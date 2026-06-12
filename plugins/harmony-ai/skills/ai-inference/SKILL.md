---
name: ai-inference
description: >-
  鸿蒙端侧推理: MindSpore Lite Kit 模型加载(inference/train)、
  张量操作、NPU 加速(CANN/NNRt)、模型转换与优化。涉及端侧AI、
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

// CPU 推理
let model: mindSporeLite.Model = await mindSporeLite.loadModelFromFile('/data/storage/el2/base/haps/entry/files/model.ms');

// NPU 推理（自动选择可用加速器）
let context: mindSporeLite.Context = { target: ['npu'] };
let model: mindSporeLite.Model = await mindSporeLite.loadModelFromFile(modelPath, context);
```

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

## CPU vs NPU 选型

| 维度 | CPU | NPU |
|------|-----|-----|
| 执行后端 | `target: ['cpu']` | `target: ['npu']` |
| 适用模型 | MobileNet、NLP BERT(<100MB) | ResNet、YOLO、大模型(>200MB) |
| 首次加载 | 无额外耗时 | 1-3s(模型编译) |
| 推理速度 | 帧率 5-15fps | 帧率 30-60fps |
| 功耗 | 高 | 极低 |
| 限制 | 无 | 仅限 Kirin SoC；不支持动态 shape |

**决策原则**：图像/视频推理先试 NPU 加速（`target: ['npu', 'cpu']` 自动回退）。NLP 小模型直接用 CPU 更省心。

## 模型转换三板斧

```bash
# 1. ONNX → MS
mindspore-lite-converter --fmk=ONNX --modelFile=model.onnx --outputFile=model.ms

# 2. 量化（Int8，模型体积缩小 4x，推理速度提升 2x）
mindspore-lite-converter --fmk=ONNX --modelFile=model.onnx \
  --outputFile=model_quant.ms --quantType=WeightQuant --bitNum=8

# 3. NPU 适配
mindspore-lite-converter --fmk=ONNX --modelFile=model.onnx \
  --outputFile=model_npu.ms --configFile=npu.cfg
```

**量化决策树**：
- 图像分类、物体检测 → Int8 量化（精度损失 ≤1%）
- NLP 模型、语音模型 → Float16（精度损失可控）
- 超分辨率、图像生成 → Float32（量化会引入伪影）

## 性能优化五条

1. **预热机制**：`model.predict()` 前调用一次空跑（dummy input），触发 NPU 编译和算子调度优化
2. **张量复用**：循环预测时复用 `MSTensor` 对象，用 `setData` 更新而非反复创建——省 40% 显存分配开销
3. **模型分片**：超大模型（>500MB）按层拆分为多个 `.ms`，流水线执行
4. **并行预测**：多个 `Model` 实例在不同线程中可并行推理（TaskPool），但需注意各自独立的内存开销
5. **混合精度**：`context = { precisionMode: 'preferred_fp16' }`——兼顾速度与精度

## 排查清单

1. **loadModel 报空指针** → 检查模型路径：沙箱路径非绝对路径，`/data/storage/el2/` 仅在真机有效
2. **NPU 加载失败回退 CPU** → 检查模型 op 是否全量支持 NPU；用 `mindspore-lite-converter --configFile=npu.cfg` 设置 `provider=ge` 
3. **predict 超时** → 首次预测 NPU 编译可能要 3-5s；`setTimeout` 给够，或提前 warmup
4. **输出数值异常(NaN/Inf)** → 确认输入归一化与训练时一致（常见坑：训练用 [0,1] 推理用 [-1,1]）
5. **内存 OOM** → 大模型推理后立即 `outputs.forEach(t => t.free())`，不可依赖 GC

> 官方文档：[MindSpore Lite Kit](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/mindspore-lite-kit) · [API 参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/mindspore-lite-api)
