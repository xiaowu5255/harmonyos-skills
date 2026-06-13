# 测试提示词 — ai-speech

> 种子用例,取自仓库级回归集 `tools/evals/evals.json`。可按需补充边界条件 / 错误处理场景。

## 基础功能测试

### 场景 1
**提示词**：鸿蒙 App 里要做语音输入功能,在线识别和离线识别怎么选?

**预期输出**：触发 ai-speech;给出在线(97%精度/需网络)vs 离线(90%/实时)对比表;强调 MICROPHONE 权限

### 场景 2
**提示词**：做一个朗读文章的 TTS 功能,长文本自动分段播放,鸿蒙怎么做?

**预期输出**：触发 ai-speech;给出 speechSynthesis.createSpeechPlayer→speak 流式合成;长文本分段(≤2000字)+delay 200ms 方案
