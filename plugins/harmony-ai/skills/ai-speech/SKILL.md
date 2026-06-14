---
name: ai-speech
description: >-
  鸿蒙语音AI: Core Speech Kit 语音识别(ASR)、语音合成(TTS)、
  实时语音转写，Speech Kit 语音唤醒与声纹验证。涉及语音输入、
  朗读、语音指令时使用本技能。
license: MIT
requires: 0-ai-index
kits: ["@kit.CoreSpeechKit", "@kit.SpeechKit"]
metadata:
  target-platform: "HarmonyOS 6.x / API 20-24"
---

# 语音 AI：识别、合成与唤醒

## 双 Kit 分工

| Kit | 能力 | 触发场景 |
|-----|------|---------|
| **Core Speech Kit** | 语音识别(ASR)、语音合成(TTS)、实时转写 | 语音输入、内容朗读、会议记录 |
| **Speech Kit** | 语音唤醒、声纹注册/验证 | 语音助手唤醒词、声纹解锁 |

## Core Speech：ASR 语音识别

```typescript
import { speechRecognizer } from '@kit.CoreSpeechKit';

// 1. 创建识别器实例
let asrEngine = speechRecognizer.createRecognizer({
  language: 'zh-CN',        // zh-CN / en-US / ja-JP / ko-KR
  online: true,             // true=在线(更高精度) / false=离线
  engineType: 'speech'      // speech / phrase（短语模式）
});

// 2. 设置事件回调
asrEngine.on('start', () => { /* 录音中 */ });
asrEngine.on('recognizeword', (result) => {
  // result: { word: string, confidence: number, isLast: boolean }
});
asrEngine.on('error', (err) => { /* 错误处理 */ });

// 3. 开始识别
asrEngine.startListening();

// 4. 结束时停止
asrEngine.stopListening();
```

**在线 vs 离线选型**：

| 维度 | 在线 | 离线 |
|------|------|------|
| 精度 | 更高(依赖云端大模型) | 够用(端侧模型) |
| 延迟 | 含网络往返 | 本地即时 |
| 网络 | 需要 | 不需要 |
| 并发限制 | 1 路 / 应用 | 1 路 / 应用 |
| 适用 | 语音输入、搜索 | 语音指令、离线场景 |

> 精度/延迟的具体数值依网络、口音、场景而定,实测为准,不臆断固定百分比。

`RECOGNIZER_BUSY` 错误 → 前一次识别未 stop 就调了 start。ASR 是单路资源，用完必释放。

## Core Speech：TTS 语音合成

```typescript
import { speechSynthesis } from '@kit.CoreSpeechKit';

let ttsEngine = speechSynthesis.createSpeechPlayer({
  language: 'zh-CN',
  person: 0,        // 0=女声 / 1=男声
  speed: 1.0,       // 0.5~2.0
  volume: 1.0,      // 0~1.0
  pitch: 1.0        // 语调
});

// 流式合成：边合成边播放
ttsEngine.speak('今天天气很好');

// 离线合成：先合成到文件
ttsEngine.synthesizeToFile('今天天气很好', '/path/to/output.wav');

// 事件监听
ttsEngine.on('complete', () => { /* 播放完毕 */ });
ttsEngine.on('error', (err) => { /* 合成失败 */ });
```

**TTS 三个常见坑**：
1. **男声不生效** → 部分设备只装了女声资源包，检查 `speechSynthesis.getVoiceList()` 查看可用音色
2. **speak 调用后没声音** → 确认 AudioRenderer 未被其他应用独占（音频焦点冲突）
3. **长文本中断** → 单次合成有字数上限（具体值以官方文档/本地 SDK 为准），超长文本需分段合成、依次衔接播放

## 实时语音转写

```typescript
let transcribe = speechRecognizer.createRecognizer({ engineType: 'transcribe' });
// 持续识别会话中的语音，不限时长——会议记录核心
// 输出带时间戳：{ word, startTime, endTime, isLast }
```

与普通 ASR 的区别：`engineType: 'transcribe'` 不会在 silence 后自动停止。需显式调 stop。

## Speech Kit：唤醒与声纹

**语音唤醒**：
- 需要设备厂商预置唤醒模型
- 应用声明 `ohos.permission.MANAGE_VOICE_WAKEUP`
- 热词在系统设置中注册，应用只能监听唤醒事件

**声纹验证**：
```typescript
import { voiceprint } from '@kit.SpeechKit';
// 1. 注册：录入 3-5 次指定短语
voiceprint.enroll(userId, text, (result) => { /* success/fail */ });
// 2. 验证：比对当前语音与已注册声纹
voiceprint.verify(userId, text, (result, score) => {
  // score 越高越可信;判定阈值按安全等级与官方建议设定,勿照搬固定值
});
```

## 权限声明

| 能力 | 权限 |
|------|------|
| 语音识别(在线) | `ohos.permission.INTERNET` + `ohos.permission.MICROPHONE` |
| 语音识别(离线) | `ohos.permission.MICROPHONE` |
| 语音合成(TTS) | 不需要特殊权限（仅播放音频） |
| 语音唤醒 | `ohos.permission.MANAGE_VOICE_WAKEUP` |
| 声纹 | `ohos.permission.MICROPHONE` |

## 排查清单

1. **ASR 一直"正在听"不返回结果** → 确认 `ohos.permission.MICROPHONE` 已授权，检查麦克风是否被其他应用占用
2. **TTS 合成输出为空白音频** → 检查文本编码（必须是 UTF-8），若含 emoji 需先过滤
3. **离线 ASR 精度差** → 离线模型按需下载，检查 `getModelStatus()` 确认模型已就绪
4. **ASR 和 TTS 同时使用冲突** → 两者共享音频焦点。先 stop ASR 再 start TTS，反之亦然
5. **实时转写时间戳不准** → 连续语音场景下 `startTime` 存在系统偏差，对时序敏感的用 VAD(静音检测) 二次修正

> 官方文档：[Core Speech Kit](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/core-speech-kit-guide) · [Speech Kit](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/speech-kit-guide)
