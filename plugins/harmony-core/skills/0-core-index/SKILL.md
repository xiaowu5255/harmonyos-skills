---
name: 0-core-index
description: "鸿蒙应用框架索引。涉及ArkTS语法、状态管理、ArkUI布局/导航/动画/窗口、Stage模型、ArkWeb、元服务卡片、多设备适配、Hvigor构建、工程调试时加载本索引。provides: index, requires: harmony-index"
provides: index
requires: harmony-index
---

# 鸿蒙应用框架索引

覆盖 ArkTS/ArkUI/Stage 模型等核心应用开发能力。

## 子领域

| 子领域 | 内容 | 深度技能 |
|--------|------|----------|
| ArkTS 语法与状态管理 | 类型约束、装饰器(@State/@Prop/@Link等)、组件复用 | `arkts-syntax` |
| ArkTS 并发 | TaskPool 与 Worker 多线程 | `arkts-concurrency`（新） |
| ArkUI 布局与导航 | 布局组件、导航(Navigation/NavPathStack)、列表(LazyForEach)、动画(属性/显式/页面过渡) | `arkui-patterns` |
| ArkUI 窗口管理 | 窗口创建/分屏/悬浮窗/屏幕适配 | `arkui-window`（新） |
| Stage 模型 | UIAbility/ServiceExtensionAbility、Want、Context、进程模型 | `stage-model` |
| ArkWeb | Web 组件加载网页、JS 互调、Cookie/缓存管理 | `arkweb`（新） |
| 构建体系 | HAP/HAR/HSP/hvigor 编译打包 | `hvigor-build` |
| 调试诊断 | 六层诊断框架、hilog、异常捕获 | `harmony-debugging` |
| 元服务与卡片 | 原子化服务、Form Kit 卡片开发 | `atomic-services-and-cards` |
| 多设备适配 | 断点系统、折叠屏适配、横竖屏 | `multi-device-adaptation` |
| 无障碍与本地化 | 屏幕朗读适配、多语言资源、长辈关怀模式、RTL布局 | `accessibility-i18n` |
| 进程通信与输入法 | IPC RPC跨进程调用、输入法开发与自绘编辑器集成 | `ipc-ime` |
