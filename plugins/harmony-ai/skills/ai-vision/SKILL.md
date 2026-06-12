---
name: ai-vision
description: "鸿蒙视觉AI: Vision Kit 场景化视觉(OCR/文档识别)、Core Vision Kit 基础视觉(图像分类/检测)。涉及文字识别、图像检测时使用本技能。[P2 待完善]"
license: MIT
metadata:
  target-platform: "HarmonyOS 6.x / API 20-24"
requires: 0-ai-index
kits: [@kit.VisionKit, @kit.CoreVisionKit]
---

# 视觉 AI：文字识别与图像分析

> **状态：P2 待完善** —— 本文档为轻量速查占位，后续将补充完整示例、API 详解与最佳实践。

## 覆盖 Kit 说明

**Vision Kit** 提供场景化视觉 AI 能力：通用文字识别(OCR)、文档扫描矫正、身份证/银行卡识别、表格识别、二维码检测、手势识别等开箱即用的视觉能力。**Core Vision Kit** 提供基础视觉原子能力：图像分类(`ImageClassifier`)、目标检测(`ObjectDetector`)、图像分割(`ImageSegmenter`)，允许开发者自定义模型替换默认模型进行端侧推理。

## 常见场景速查

| 场景 | 核心 API | 需关注的 Kit |
|------|---------|-------------|
| 拍照 OCR 识别 | `VisionKit.createTextRecognizer()` | VisionKit |
| 身份证扫描 | `VisionKit.createIDCardAnalyzer()` | VisionKit |
| 文档矫正扫描 | `VisionKit.createDocReflectionDetector()` | VisionKit |
| 图像分类 | `CoreVisionKit.createImageClassifier()` | CoreVisionKit |
| 目标检测 | `CoreVisionKit.createObjectDetector()` | CoreVisionKit |
| 手势识别 | `VisionKit.createGestureDetector()` | VisionKit |

## P2 完善计划

以下内容将在后续版本补全：

- [ ] Vision Kit 每种识别器的完整初始化与结果解析示例
- [ ] Core Vision Kit 自定义模型加载(ONNX/TFLite)的完整流程
- [ ] 拍照→选择区域→OCR→结果展示的端到端交互示例
- [ ] 图片输入源的选择策略：相机帧(`cameraOutput`) vs `PixelMap` vs `ImageUri`
- [ ] 识别结果的置信度过滤与后处理最佳实践
- [ ] 端侧推理的性能优化：模型量化、NPU 加速、内存管理
