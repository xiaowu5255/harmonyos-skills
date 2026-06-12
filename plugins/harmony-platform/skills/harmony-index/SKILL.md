---
name: harmony-index
description: "鸿蒙全栈开发总索引。涉及任意 HarmonyOS/鸿蒙/ArkTS/ArkUI/元服务/Native/端云开发时首先加载本技能确定领域。provides: index"
provides: index
---

# 鸿蒙全栈开发总索引

本索引覆盖鸿蒙开发全部领域。根据任务类型选择对应子索引加载。

## 领域路由

| 领域 | 说明 | 加载技能 |
|------|------|----------|
| 应用框架 | ArkTS/ArkUI/Stage模型/ArkWeb/元服务卡片/多设备适配/Hvigor构建/调试 | `0-core-index` |
| 系统能力 | 后台任务/权限/网络/存储/文件/加密/分布式/Native NDK/传感器 | `0-system-index` |
| 媒体 | 音频/相机/编解码/图片/DRM/AVSession播控/扫码 | `0-media-index` |
| 图形 | 2D绘制/3D渲染/AR/图形加速/空间感知 | `0-graphics-index` |
| 应用服务 | 账号/推送/支付/通知/地图/端云一体化/分享/DeepLink | `0-ecosystem-index` |
| AI | 视觉AI/语音AI/NLP/端侧推理/意图框架 | `0-ai-index` |
| 发布运维 | 性能优化/QA测试/签名/上架合规 | `0-release-index` |

## 业务定制路由（直接在本索引处理）

- **AGC 平台**：AppGallery Connect 配置、质量服务、分析、崩溃等 → 参考 AGC 官方文档，本技能系列暂不覆盖
- **设计规范**：鸿蒙设计指南、组件规范、多设备布局 → 参考 HarmonyOS Design 官方文档
- **行业实践**：政务/教育/医疗/金融等行业解决方案 → 参考华为行业解决方案文档

## 使用方式

遇到鸿蒙开发任务时，先确认所属领域，然后加载对应子索引获取具体技能名，最后加载深度技能获取API细节。
