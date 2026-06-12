---
name: 0-media-index
description: "鸿蒙媒体能力索引。涉及音频播放/录制/MIDI、相机拍照/录像、音视频编解码、图片处理、媒体库、DRM、AVSession播控、扫码时加载本索引。provides: index, requires: harmony-index"
provides: index
requires: harmony-index
---

# 鸿蒙媒体能力索引

覆盖音频、相机、编解码、图片处理等媒体相关能力。

## 子领域

| 子领域 | 内容 | 深度技能 |
|--------|------|----------|
| 音频 | 音频播放/录制、音频焦点管理、音频路由(扬声器/听筒/蓝牙)、MIDI | `audio-playback`（新） |
| 相机 | 相机预览、拍照、录像、追焦、双摄 | `camera-capture`（新） |
| 媒体处理 | 音视频编解码、图片解码/编码/变换/滤镜、媒体信息提取 | `media-processing`（新） |
| 媒体系统 | AVSession 播控、投屏、DRM 版权保护、扫码 | `media-system`（新） |
