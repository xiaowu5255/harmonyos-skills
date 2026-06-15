---
name: media-processing
description: >-
  鸿蒙音视频处理: AVCodec Kit 编解码、Image Kit 图片处理、
  Media Kit 播放/录制、封装解封装(muxer/demuxer)。涉及视频编辑、
  音频转码、图片变换、媒体文件加工时使用本技能。
license: MIT
requires: 0-media-index
kits: ["@kit.AVCodecKit", "@kit.ImageKit", "@kit.MediaKit"]
metadata:
  target-platform: "HarmonyOS 6.x / API 20-24"
---

## Overview

鸿蒙音视频处理: AVCodec Kit 编解码、Image Kit 图片处理、 Media Kit 播放/录制、封装解封装(muxer/demuxer)。

## When to Use

- 涉及 视频编辑 时
- 涉及 音频转码 时
- 涉及 图片变换 时
- 涉及 媒体文件加工 时

# 音视频处理：编解码、图片与播放器

## 三 Kit 边界速判

拿到媒体处理需求先分派到正确的 Kit——选错等于从头重写。

| 需求类型 | 用哪个 Kit | 典型 API |
|---------|-----------|---------|
| 视频解码/编码 | **AVCodec Kit** | `createVideoDecoder` / `createVideoEncoder` |
| 音频转码/解码 | **AVCodec Kit** | `createAudioDecoder` / `createAudioEncoder` |
| 图片解码/编码/变换 | **Image Kit** | `createImageSource` / `createImagePacker` |
| 容器解封装(.mp4→音视频轨) | **AVCodec Kit** | `createAVDemuxer` / `createAVMuxer` |
| 播放音视频文件 | **Media Kit (AVPlayer)** | `createAVPlayer` |
| 录音/录屏 | **Media Kit (AVRecorder)** | `createAVRecorder` |

## AVCodec Kit：同步 vs 异步

AVCodec 有两套编码模型，API 20 后**同步模式正式上线**：

| 模式 | 机制 | 适用场景 |
|------|------|---------|
| **异步模式** | callback 驱动 `on('bufferAvailable')` | 播放器、实时预览，不用管效率 |
| **同步模式(API 20+)** | 主动 `pullBuffer()/pushBuffer()` | 视频编辑器、精确帧控制、多轨合成 |

**异步模式流程**：
```
createDecoder → configure → start → on('bufferAvailable')
  → renderOutputBuffer → releaseOutputBuffer → stop → release
```

**同步模式关键差异**：不再等回调，主动拉取。`pullBuffer(timeout)` 可传 -1 无限等，0 立即返回，N 毫秒超时。帧级的 seek + decode 精确到微秒，是视频剪辑的基础。

## 编码参数七件套

不管是音还是视频编码，这七个参数一定要搞对：

1. **codecMime**：视频 `'video/avc'`(H.264) / `'video/hevc'`(H.265)，音频 `'audio/mp4a-latm'`(AAC)
2. **width × height**：视频编码必须匹配输入帧尺寸，差 1 像素 = `CODEC_ERROR`
3. **bitrate**：码率随分辨率与帧率上升而增大；具体取值按画质/体积权衡实测调优，不照搬固定值
4. **frameRate**：常见 15/24/30/60，编码端和源视频一致
5. **profile**：H.264 → baseline/main/high；H.265 → main
6. **pixelFormat**：`NV12`(默认) / `NV21` / `RGBA8888`
7. **声道/采样率**(音频)：AAC 常见 44100Hz / 立体声

## Image Kit：解码到编码的流水线

Image Kit 核心是 **Source(输入) → Decoder(解码) → Packer(编码输出)**：

```
createImageSource(uri/fd/ArrayBuffer)
  → createImageDecoder → decode → PixelMap
    → createImagePacker → packToFile → .jpg/.png/.webp
```

**三个常用变换场景**：
- **JPEG→WebP 转码**：decode → 改 `desiredPixelFormat` 为 RGBA8888 → packToFile → 格式选 `image/webp`，质量 80
- **缩略图生成**：decode 时设 `desiredSize = {width: 200, height: 200}`，等比缩放
- **批量加水印**：decode → PixelMap → Canvas 绘图叠加水印 → packToFile

**内存警示**：PixelMap 是显存对象，用后立即 `pixelMap.release()`。批量处理 50 张 12MP 照片，不释放 = 6 秒 OOM 崩溃。

## Media Kit 播放录制速查

| 场景 | 类 | 关键点 |
|------|-----|-------|
| 本地/网络音频 | AVPlayer | `url` 设本地路径或 `fdSrc`，网络用 `http://` |
| 视频播放 | AVPlayer | XComponent 绑 surfaceId |
| 录音 | AVRecorder | `audioSourceType` 选 MIC / CAMCORDER |
| 录屏 | AVRecorder | `videoSourceType` 选 SURFACE_RGBA，需权限 |

**AVPlayer 状态机必知**：idle → initialized → prepared → playing → paused → stopped。**已经 stopped 就不能再 prepared，必须 reset 回 idle**。

## 容器操作：Demuxer/Muxer

视频编辑器最常见的操作——抽音视频轨道后分别处理：

```
createAVDemuxer(fd) → getTrackCount → selectTrackByIndex
  → readSample → (编解码处理) → createAVMuxer → addTrack
    → writeSample → close
```

**关键坑**：Muxer 写 sample 时 pts(时间戳) 必须严格递增。解码后修改了帧的时间戳，重新封装如果 pts 乱序，播放器会卡住。

## 排查清单

1. **编码输出花屏/绿屏** → pixelFormat 不匹配：输入 RGBA 但编码器期望 NV12
2. **解码失败不抛异常** → 检查 MIME 类型(codecMime)是否在 `avcodec.isCodecSupported()` 白名单
3. **MP4 播放无音轨** → Demuxer 只选了视频轨道，需要 `selectTrackByIndex` 两次分别取音视频
4. **打包后文件 0 字节** → Muxer 写完后必须调 `close()`，否则缓冲区未刷盘
5. **AVPlayer 播放报 801** → URL 文件不存在，检查沙箱路径（不是绝对路径 `/data/storage/el2/`）

> 官方文档：[AVCodec Kit](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/avcodec-kit) · [Image Kit](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/image-kit) · [Media Kit](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/media-kit)
