---
name: ai-inference
description: >-
  鸿蒙端侧推理: MindSpore Lite Kit 模型加载(inference/train)、
  张量操作、NNRt 硬件加速、模型转换与优化。涉及端侧AI、
  图像分类、语音识别模型部署时使用本技能。
license: MIT
requires: 0-ai-index
kits: ["@kit.MindSporeLiteKit"]
metadata:
  target-platform: "HarmonyOS 6.x / API 20-24"
---

# 端侧推理：MindSpore Lite 模型部署

## 推理流水线五步法

```
模型准备(.ms 格式) → loadModel → 构造输入 Tensor → predict → 解析输出 Tensor
```

**不变量**：MindSpore Lite 只接受 `.ms` 格式模型。任何 `.onnx` / `.pb` / `.tflite` 必须先用 `mindspore-lite-converter` 工具转换。

## 加载模型

```typescript
import { mindSporeLite } from '@kit.MindSporeLiteKit';

// CPU 推理：context.target 用 'cpu'，cpu 子配置可设线程数/精度
let context: mindSporeLite.Context = {};
context.target = ['cpu'];
context.cpu = { threadNum: 2, threadAffinityMode: 1, precisionMode: 'enforce_fp32' };
let model: mindSporeLite.Model =
  await mindSporeLite.loadModelFromFile('/data/storage/el2/base/haps/entry/files/model.ms', context);

// 硬件加速：经 NNRt(神经网络运行时)统一抽象，target 用 'nnrt'，不是 'npu'
// （'npu'/KIRIN_NPU 在官方设备类型枚举中为"保留，尚未支持"）
let nnrtContext: mindSporeLite.Context = {};
nnrtContext.target = ['nnrt'];
let accModel: mindSporeLite.Model =
  await mindSporeLite.loadModelFromFile(modelPath, nnrtContext);
```

> **同一 `context` 只能用于一次 `loadModelFromFile`**(官方 C-API `OH_AI_ModelBuildFromFile`
> 明确约束)；加载多个模型需各自新建 context。`target` 取值与 `cpu`/`nnrt` 配置结构以本地
> SDK `@hms.ai.mindSporeLite.d.ts` 为准。

**模型文件放在哪**：
- 小模型(≤50MB)：放 `entry/src/main/resources/rawfile/` → 运行时用 `resourceManager.getRawFileContent()` 读取
- 大模型(>50MB)：放 HAP 外，运行时从服务器下载到沙箱 `/data/storage/el2/base/haps/entry/files/`
- **模型不要放 HAP 内**：超过 100MB 影响安装包大小，且更新模型需重新上架

## 输入输出张量处理

```typescript
// 获取输入张量规格
let inputs: mindSporeLite.MSTensor[] = model.getInputs();
let inputShape = inputs[0].getShape();    // [1, 3, 224, 224] NCHW
let dataType = inputs[0].getDataType();   // float32 / uint8 / int32

// 填充数据
let floatData = new Float32Array(inputs[0].getDataSize());
// ... 预处理：resize + normalize + toCHW ...
inputs[0].setData(floatData.buffer);      // 写入张量

// 预测
let outputs: mindSporeLite.MSTensor[] = await model.predict(inputs);

// 解析输出
let result = new Float32Array(outputs[0].getData()); // [1, 1000] 分类 logits
```

## CPU vs NNRt(硬件加速)选型

| 维度 | CPU | NNRt(硬件加速) |
|------|-----|-----|
| 执行后端 | `target: ['cpu']` | `target: ['nnrt']`(经 NNRt 调度底层加速硬件) |
| 适用模型 | 小模型(MobileNet、轻量 NLP) | 计算量大的视觉模型(ResNet、YOLO 等) |
| 首次加载 | 无额外耗时 | 通常更慢(需算子编译/图优化) |
| 推理速度 | 较慢 | 通常显著更快(随机型/分辨率而异,实测为准) |
| 功耗 | 较高 | 较低 |
| 限制 | 无 | 算子需被后端支持;不支持的算子回退 CPU |

> 不列固定 fps/加载秒数——这些强依赖模型、分辨率、设备 SoC,臆断数值会误导。
> 需要性能基线时在目标机型实测。`KIRIN_NPU` 在官方 `OH_AI_DeviceType` 枚举中标注
> 为"保留,尚未支持",真正可用的加速通道是 **NNRt**。

**决策原则**：计算量大的视觉模型先试 NNRt(不支持的算子会回退 CPU)；
轻量模型直接用 CPU 更省心。加速是否生效以目标设备实测为准。

## 模型转换三板斧

```bash
## ① ONNX → MS
mindspore-lite-converter --fmk=ONNX --modelFile=model.onnx --outputFile=model.ms

## ② 量化（Int8，显著缩小模型体积，加速推理；精度损失需实测）
mindspore-lite-converter --fmk=ONNX --modelFile=model.onnx \
  --outputFile=model_quant.ms --quantType=WeightQuant --bitNum=8

## ③ 后端适配（按目标后端配置 configFile）
mindspore-lite-converter --fmk=ONNX --modelFile=model.onnx \
  --outputFile=model_acc.ms --configFile=backend.cfg
```

**量化决策树**：
- 图像分类、物体检测 → Int8 量化（精度损失通常较小，需实测）
- NLP 模型、语音模型 → Float16（精度损失可控）
- 超分辨率、图像生成 → Float32（量化会引入伪影）

## 性能优化五条

1. **预热机制**：`model.predict()` 前调用一次空跑（dummy input），触发加速后端的算子编译/图优化
2. **张量复用**：循环预测时复用 `MSTensor` 对象，用 `setData` 更新而非反复创建——省去重复显存分配开销
3. **模型分片**：超大模型（>500MB）按层拆分为多个 `.ms`，流水线执行
4. **并行预测**：多个 `Model` 实例在不同线程中可并行推理（TaskPool），但需注意各自独立的内存开销
5. **精度模式**：精度设在 `context.cpu.precisionMode`（如 `'preferred_fp16'` 兼顾速度与精度，
   `'enforce_fp32'` 强制全精度）——字段层级以本地 d.ts 为准

## 排查清单

1. **loadModel 报空指针** → 检查模型路径：沙箱路径非绝对路径，`/data/storage/el2/` 仅在真机有效
2. **加速后端加载失败回退 CPU** → 检查模型算子是否被 NNRt 后端全量支持；转换时用 `--configFile` 指定后端配置
3. **predict 首次偏慢** → 首次预测触发加速后端编译，耗时高于稳态；用 warmup 空跑预热，超时阈值给足
4. **输出数值异常(NaN/Inf)** → 确认输入归一化与训练时一致（常见坑：训练用 [0,1] 推理用 [-1,1]）
5. **内存 OOM** → 大模型推理后立即 `outputs.forEach(t => t.free())`，不可依赖 GC

> 官方文档：[MindSpore Lite Kit](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/mindspore-lite-kit) · [API 参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/mindspore-lite-api)
