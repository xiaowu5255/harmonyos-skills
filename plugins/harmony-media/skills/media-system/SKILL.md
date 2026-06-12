---
name: media-system
description: "鸿蒙媒体系统服务: AVSession Kit 音视频播控/投屏、DRM Kit 数字版权保护、Scan Kit 统一扫码、Ringtone Kit 铃声服务。涉及媒体投屏、版权视频、扫码跳转时使用本技能。[P2 待完善]"
license: MIT
metadata:
  target-platform: "HarmonyOS 6.x / API 20-24"
requires: 0-media-index
kits: [@kit.AVSessionKit, @kit.DRMKit, @kit.ScanKit]
---

# 媒体系统服务：播控、DRM 与扫码

> **状态：P2 待完善** —— 本文档为轻量速查占位，后续将补充完整示例、API 详解与最佳实践。

## 覆盖 Kit 说明

**AVSession Kit** 提供系统级音视频播控服务：锁屏/通知栏媒体控件、媒体元数据(`AVSessionMetadata`)设置、播放状态同步。支持投屏(`Cast+`)能力，将音频/视频流投射到远端设备。**DRM Kit** 为受版权保护的音视频内容提供数字版权解密与许可管理，支持主流 DRM 方案(Widevine/ChinaDRM)。**Scan Kit** 提供统一扫码能力，支持二维码/条形码的相机扫码与图片解码两种模式。

## 常见场景速查

| 场景 | 核心 API | 需关注的 Kit |
|------|---------|-------------|
| 媒体播控 | `AVSession.createAVSession(context)` + 设置 metadata | AVSessionKit |
| 投屏到电视 | `AVSession.startCast()` + 设备发现 | AVSessionKit |
| DRM 视频播放 | `MediaKeySystem` → `MediaKeySession` → 解密 | DRMKit |
| 二维码扫码 | `ScanKit.startScan()` 或 `ScanUtil.decodeFromPixels()` | ScanKit |
| 铃声设置 | `RingtoneManager.setRingtone()` | RingtoneKit |

## P2 完善计划

以下内容将在后续版本补全：

- [ ] AVSession 播控控件的完整生命周期(创建→激活→元数据更新→释放)
- [ ] Cast+ 投屏的设备发现、连接建立与流传输的完整流程
- [ ] DRM 在线/离线许可获取与媒体解密完整示例
- [ ] Scan Kit 自定义扫码 UI 与相机权限联合处理方案
- [ ] 后台播控的连续任务(`continuousTask`)与音频焦点配合
- [ ] 多场景联合：扫码 → DRM 校验 → 投屏播放的端到端流程
