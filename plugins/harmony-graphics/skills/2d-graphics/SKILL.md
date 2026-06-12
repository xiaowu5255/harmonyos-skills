---
name: 2d-graphics
description: "鸿蒙2D图形: ArkGraphics 2D 绘制/显示/Canvas、Graphics Accelerate Kit 图形加速。涉及自定义绘制、高性能渲染时使用本技能。[P2 待完善]"
license: MIT
metadata:
  target-platform: "HarmonyOS 6.x / API 20-24"
requires: 0-graphics-index
kits: ["@kit.ArkGraphics2D", "@kit.GraphicsAccelerateKit"]
---

# 2D 图形：绘制、Canvas 与加速

> **状态：P2 待完善** —— 本文档为轻量速查占位，后续将补充完整示例、API 详解与最佳实践。

## 覆盖 Kit 说明

**ArkGraphics 2D** 是鸿蒙 2D 图形绘制核心引擎，提供 `Canvas`、`RenderNode`、显示合成(`DisplaySync`)能力。支持路径绘制、文字渲染、图片合成、滤镜效果等基础绘图原语，与 ArkUI 组件树深度集成。**Graphics Accelerate Kit** 提供硬件图形加速能力，将 2D 绘制负载卸载到 GPU，适用于高性能渲染场景如游戏 UI、图表引擎、动画特效等。

## 常见场景速查

| 场景 | 需关注的 Kit | 官方文档入口 |
|------|-------------|------------|
| 自定义绘制 | ArkGraphics2D | [Canvas 绘制指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkgraphics-2d-canvas-drawing) |
| 离屏渲染缓冲 | ArkGraphics2D | [离屏渲染指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkgraphics-2d-offscreen) |
| 高性能动画 | ArkGraphics2D, GraphicsAccelerateKit | [DisplaySync 指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkgraphics-2d-display-sync) |
| 图表绘制 | ArkGraphics2D | [图表绘制指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkgraphics-2d-chart) |
| 图片合成 | ArkGraphics2D | [图片合成指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkgraphics-2d-image) |
| GPU 加速 | GraphicsAccelerateKit | [图形加速指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/graphics-accelerate) |

## P2 完善计划

以下内容将在后续版本补全：

- [ ] Canvas 2D 绘制原语(path/rect/text/image)的完整 API 参考
- [ ] RenderNode 与 ArkUI 组件树集成的生命周期管理
- [ ] DisplaySync 同步 vsync 信号进行流畅动画渲染的示例
- [ ] Graphics Accelerate Kit 开启与关闭的性能对比数据
- [ ] 离屏渲染 Surface 创建与像素回读的典型场景
- [ ] 大屏/折叠屏设备的绘制分辨率自适应方案
- [ ] 用 sdk-diff 验证所有 API 名后再补回速查表
