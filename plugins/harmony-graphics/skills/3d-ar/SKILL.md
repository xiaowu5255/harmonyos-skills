---
name: 3d-ar
description: "鸿蒙3D与AR: ArkGraphics 3D 场景渲染、AR Engine 增强现实、Spatial Recon Kit 空间建模、XEngine Kit GPU加速。涉及3D模型加载、AR应用时使用本技能。[P2 待完善]"
license: MIT
metadata:
  target-platform: "HarmonyOS 6.x / API 20-24"
requires: 0-graphics-index
kits: ["@kit.ArkGraphics3D", "@kit.AREngine", "@kit.SpatialReconKit", "@kit.XEngineKit"]
---

# 3D 与 AR：场景渲染与增强现实

> **状态：P2 待完善** —— 本文档为轻量速查占位，后续将补充完整示例、API 详解与最佳实践。

## 覆盖 Kit 说明

**ArkGraphics 3D** 是鸿蒙 3D 图形引擎，负责 3D 场景构建、模型加载(glTF/OBJ)、材质与光照系统、相机控制与渲染管线管理。**AR Engine** 提供增强现实能力：平面检测、图像跟踪、手部/人体/面部跟踪、光照估计实现虚实融合。**Spatial Recon Kit** 进行环境空间建模，将现实空间转换为 3D 网格模型。**XEngine Kit** 提供跨平台 GPU 加速框架，支持 Vulkan/OpenGL ES 计算着色器。

## 常见场景速查

| 场景 | 需关注的 Kit | 官方文档入口 |
|------|-------------|------------|
| 3D 模型展示 | ArkGraphics3D | [3D 场景渲染指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkgraphics-3d-model) |
| AR 平面放置 | AREngine | [AR 平面检测指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ar-engine-hit-test) |
| AR 人脸特效 | AREngine | [AR 人脸跟踪指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ar-engine-face-tracking) |
| 空间扫描 | SpatialReconKit | [空间建模指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/spatial-recon) |
| GPU 加速计算 | XEngineKit | [GPU 加速指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/xengine-overview) |

## P2 完善计划

以下内容将在后续版本补全：

- [ ] ArkGraphics 3D 场景图(Scene Graph)的节点管理与材质系统
- [ ] glTF 2.0 模型加载完整流程(含 PBR 材质、骨骼动画)
- [ ] AR Engine 的平面检测→放置虚拟物体→交互的端到端示例
- [ ] Spatial Recon Kit 的空间扫描与 3D 网格导出流程
- [ ] XEngine Kit Vulkan 管线的初始化与计算着色器示例
- [ ] 相机权限与 AR 场景联合使用的权限申请流程
- [ ] 用 sdk-diff 验证所有 API 名后再补回速查表
