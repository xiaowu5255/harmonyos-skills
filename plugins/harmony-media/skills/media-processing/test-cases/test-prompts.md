# 测试提示词 — media-processing

> 种子用例,取自仓库级回归集 `tools/evals/evals.json`。可按需补充边界条件 / 错误处理场景。

## 基础功能测试

### 场景 1
**提示词**：鸿蒙视频编辑器,怎么把一个 MP4 里的音视频轨道分离后分别处理?

**预期输出**：触发 media-processing;给出 AVCodec Demuxer→编解码→Muxer 流水线;强调 pts 严格递增

### 场景 2
**提示词**：想把一批 JPEG 图片批量转成 WebP 格式缩小体积,鸿蒙怎么做?

**预期输出**：触发 media-processing;给出 Image Kit createImageSource→decode→createImagePacker→packToFile 流水线;提醒 PixelMap 及时 release
