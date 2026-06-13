# 测试提示词 — media-system

> 种子用例,取自仓库级回归集 `tools/evals/evals.json`。可按需补充边界条件 / 错误处理场景。

## 基础功能测试

### 场景 1
**提示词**：鸿蒙音乐 App 想在锁屏和控制中心显示播放控制按钮,怎么实现?

**预期输出**：触发 media-system;给出 AVSession createSession→setMetadata→activate→注册 controlCommand 的完整流程

### 场景 2
**提示词**：想把手机上正在播放的音乐投到电视上继续播,鸿蒙怎么实现?

**预期输出**：触发 media-system;给出分布式 AVSession 方案;先过分布式前置五条清单再 castAudio
