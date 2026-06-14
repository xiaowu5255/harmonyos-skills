---
name: ai-vision
description: >-
  鸿蒙视觉AI: Core Vision Kit 人脸/文字/物体检测、码生成、OCR，
  Vision Kit 文档识别/表单识别/图像超分。涉及图像分析、
  文档扫描、人脸验证时使用本技能。
license: MIT
requires: 0-ai-index
kits: ["@kit.CoreVisionKit", "@kit.VisionKit"]
metadata:
  target-platform: "HarmonyOS 6.x / API 20-24"
---

# 视觉 AI：检测、识别与超分

## 双 Kit 分工

鸿蒙视觉 AI 分两层——基础原子能力(Core Vision)和场景化方案(Vision)：

| 层级 | Kit | 能力范围 | 典型场景 |
|------|-----|---------|---------|
| **基础层** | Core Vision Kit | 人脸检测、文字识别(OCR)、码生成/扫描、物体检测与跟踪 | 身份验证、名片扫描、商品识别 |
| **场景层** | Vision Kit | 文档矫正、表单识别(ST)、图像超分辨率 | 合同扫描、票据录入、老照片修复 |

**决策原则**：能覆盖原子需求就用 Core Vision——它更快、无网络依赖、参数少。场景层 Vision Kit 带更复杂的后处理流水线（倾斜矫正、表格还原），仅在基础层结果不够用时启用。

## Core Vision Kit 五大能力

### 1. 人脸检测 (Face Detection)

```typescript
import { faceDetection } from '@kit.CoreVisionKit';

let visionInfo: faceDetection.VisionInfo = {
  clientStatus: true,   // 亮屏时推理
  serverStatus: false   // 不使用云端
};
faceDetection.init(visionInfo, (err) => {
  faceDetection.detect(pixelMap, (err, faces) => {
    // faces: Face[] — 每张人脸含 boundingBox、landmarks(106点)、左右眼开合度
  });
});
```

**关键参数**：
- `trackerMode: 1` → 开启人脸跟踪（视频场景）
- `landmarkType: 1` → 106 关键点（眼鼻嘴轮廓）
- `angle` → 偏航角 ±45°，超角无法检测

### 2. 文字识别 (Text/OCR)

```typescript
import { textRecognition } from '@kit.CoreVisionKit';
// init → recognizeText(pixelMap) → TextBlock[] → TextLine[] → TextElement[]
// 返回结构化：block > line > element 三级树，每级有 boundingBox + content
```

支持语言：中英日韩法德意西葡俄。在线模式精度高于离线模式；具体精度依图像质量与语言而定，实测为准。

### 3. 物体检测与跟踪

```typescript
import { objectDetection } from '@kit.CoreVisionKit';
// detect(pixelMap) → ObjectInfo[]：label(类别) + confidence + boundingBox
// 支持 600+ 类别：动物、植物、交通工具、家居物品等
```

### 4. 码生成

```typescript
import { barcode } from '@kit.CoreVisionKit';
// createBarcode('Hello World', { width:400, height:400, type:'QR_CODE' })
// 支持：QR_CODE / AZTEC / PDF417 / DATA_MATRIX / EAN_8 / EAN_13 / CODE_128 等 13 种
```

### 5. 图像分割

人像分割 `portraitSegmentation`——输出前景掩码，用于背景替换、人像抠图。

## Vision Kit 三大场景

| 能力 | 输入 | 输出 | 精度 tips |
|------|------|------|----------|
| 文档矫正 | 拍摄的歪斜文档 | 修正后的平面图 + 四角坐标 | 光照均匀、避开反光 |
| 表单识别 | 表格/票据照片 | 结构化 TableData(行/列/单元格文本) | 表格线清晰、无折叠 |
| 图像超分 | 低分辨率图像 | 1.5x/2x/3x 超分图 | 原始分辨率 ≥ 64×64 |

## 性能调优六条

1. **PixelMap 复用**：连续多帧检测时复用同一个 PixelMap，避免每帧都做 GPU→CPU 回读
2. **备选模式匹配**：先 `detect` 拿人脸 boundingBox，再 `recognizeText` 缩小裁剪区，减少无效像素提速
3. **尺寸控制**：OCR 输入图短边不必过大，过大对精度无提升但耗时随像素增长
4. **释放时序**：每次 detect 完成后立即 `pixelMap.release()`，积压多帧会显存溢出
5. **在线/离线切换**：OCR 和物体检测支持 `serverStatus`。弱网环境强制离线，省去网络往返超时
6. **检测间隔**：人脸跟踪无需每渲染帧都跑推理，按可感知变化的频率降采样即可

## 排查清单

1. **OCR 识别乱码** → 检查图片方向：Core Vision 不支持自动旋转，先对 `pixelMap` 做旋转处理
2. **detect 返回空数组** → 图片过小(短边 < 64px)或纯色无特征区域
3. **人脸检测漏检侧脸** → `angle` 参数默认 ±30°，侧脸 >30° 需调大；但精度会下降
4. **init 初始化超时** → 模型首次加载需联网下载，真机首次按提示下载；首次比稳态慢，超时阈值给足
5. **超分结果模糊** → 检查输入是不是 JPEG 高压缩图——先把压缩图片重新解码为无损 PixelMap 再超分

> 官方文档：[Core Vision Kit](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/core-vision-kit-guide) · [Vision Kit](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/vision-kit-guide)
