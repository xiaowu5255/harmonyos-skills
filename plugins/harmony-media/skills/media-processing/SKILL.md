---
name: media-processing
description: "鸿蒙媒体处理: AVCodec Kit 音视频编解码/转码、Image Kit 图片压缩/裁剪/像素处理、Media Kit 播放/录制、媒体库管理。涉及视频压缩、图片编辑、媒体文件管理时使用本技能。[P2 待完善]"
license: MIT
metadata:
  target-platform: "HarmonyOS 6.x / API 20-24"
requires: 0-media-index
kits: ["@kit.AVCodecKit", "@kit.ImageKit", "@kit.MediaKit", "@kit.MediaLibraryKit"]
---

# 媒体处理：编解码、图片编辑与媒体库

> **状态：P2 待完善** —— 本文档为轻量速查占位，后续将补充完整示例、API 详解与最佳实践。

## 覆盖 Kit 说明

**AVCodec Kit** 负责音视频编解码与转码，支持硬件加速的 H.264/H.265/AV1 编解码，提供 Codec MIME 类型选型与缓冲区管理。**Image Kit** 提供图片源解码(`ImageSource`)、像素处理(`PixelMap`)、压缩编码(`ImagePacker`)与格式转换能力。**Media Kit** 管理音视频播放(`AVPlayer`)与录制(`AVRecorder`)的完整生命周期。**MediaLibrary Kit** 提供系统媒体库的增删查改与相册管理。

## 常见场景速查

| 场景 | 需关注的 Kit | 官方文档入口 |
|------|-------------|------------|
| 视频转码 | AVCodecKit | [视频编解码指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/avcodec-video-codec) |
| 图片压缩 | ImageKit | [图片压缩指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/image-compression) |
| 图片裁剪/旋转 | ImageKit | [像素处理指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/image-pixelmap) |
| 音视频播放 | MediaKit | [播放指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/media-playback) |
| 录音/录像 | MediaKit, AudioKit | [录制指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/media-recorder) |
| 媒体文件查询 | MediaLibraryKit | [媒体库指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/media-library) |

## P2 完善计划

以下内容将在后续版本补全：

- [ ] AVCodec Kit 编解码的完整 Buffer 管理与 Surface 输入示例
- [ ] Image Kit 像素级处理(滤镜/变换)的实战示例
- [ ] Media Kit 播放器与录制器的状态机管理详解
- [ ] 媒体库权限(`READ_MEDIA`/`WRITE_MEDIA`)与文件访问路径规则
- [ ] 硬件编解码能力查询与 fallback 策略(软解切换)
- [ ] 批量图片处理的 TaskPool 并发优化方案
- [ ] 用 sdk-diff 验证所有 API 名后再补回速查表
