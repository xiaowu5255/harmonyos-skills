---
name: ai-speech
description: >-
  鸿蒙语音AI: Core Speech Kit 语音识别(ASR)、语音合成(TTS),
  Speech Kit 场景化语音服务(TextReader 朗读、AICaption AI 字幕)。
  涉及语音输入、文本朗读、实时字幕时使用本技能。
license: MIT
requires: 0-ai-index
kits: ["@kit.CoreSpeechKit", "@kit.SpeechKit"]
metadata:
  target-platform: "HarmonyOS 6.x / API 20-24"
---

# 语音 AI：识别、合成与唤醒

## 双 Kit 分工

| Kit | 能力(以官方为准) | 触发场景 |
|-----|------|---------|
| **Core Speech Kit** | 语音识别(ASR)、语音合成(TTS) | 语音输入、内容朗读、语音指令 |
| **Speech Kit** | 场景化服务:`TextReader`(文本朗读)、`AICaptionComponent`(AI 字幕) | 朗读播报、实时字幕 |

> ⚠️ 纠正:Speech Kit **不提供声纹(voiceprint)与语音唤醒**——官方该 Kit 当前为
> TextReader / AICaption 等场景化能力。如确需声纹/唤醒,先用 harmony-docs-retriever
> 核实是否有对应 Kit,**不要凭记忆调用不存在的 API**。

## Core Speech：ASR 语音识别

```typescript
import { speechRecognizer } from '@kit.CoreSpeechKit';

// 1. 创建并初始化引擎(Promise);online: 1=在线 / 0=离线
let asrEngine: speechRecognizer.SpeechRecognitionEngine | undefined;
let params: speechRecognizer.CreateEngineParams = {
  language: 'zh-CN',
  online: 1,
  extraParams: { 'recognizerMode': 'short' }, // short=短语音 / long=长语音(以官方为准)
};
asrEngine = await speechRecognizer.createEngine(params);

// 2. 设置 RecognitionListener 回调
let listener: speechRecognizer.RecognitionListener = {
  onStart: (sessionId, msg) => {},
  onEvent: (sessionId, code, msg) => {},
  onResult: (sessionId, result) => { /* 中间结果 + 最终结果 */ },
  onComplete: (sessionId, msg) => {},
  onError: (sessionId, code, msg) => {},
};
asrEngine.setListener(listener);

// 3. 开始 / 结束(方法名与参数以本地 d.ts 为准:startListening/finish 等)
// asrEngine.startListening(...); asrEngine.finish(sessionId);
```

> 引擎以 `createEngine` 创建、`setListener(RecognitionListener)` 收结果(回调 onStart/
> onResult/onComplete/onError);没有 `createRecognizer` + `on('recognizeword')` 这套写法。

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

模块是 `textToSpeech`(不是 `speechSynthesis`):`createEngine` 创建 → `setListener` 设回调
→ `speak(text, SpeakParams)` 合成播报。

```typescript
import { textToSpeech } from '@kit.CoreSpeechKit';

let ttsEngine: textToSpeech.TextToSpeechEngine;
let initParams: textToSpeech.CreateEngineParams = {
  language: 'zh-CN',
  person: 0,        // 音色,取值以官方为准
  online: 1,
};
ttsEngine = await textToSpeech.createEngine(initParams);

// 播报参数走 extraParams(speed/volume/pitch 范围均 [0.5-2] 或 [0-2],见官方)
let speakParams: textToSpeech.SpeakParams = {
  requestId: 'req-1', // 同一实例内不可重复
  extraParams: { 'speed': 1, 'volume': 1, 'pitch': 1, 'playType': 1 }, // playType:0 仅合成返流 /1 合成并播报
};
ttsEngine.speak('今天天气很好', speakParams);
```

**TTS 三个常见坑**：
1. **音色不生效** → person/音色取值依设备资源而定,以官方文档与本地 d.ts 为准
2. **speak 调用后没声音** → 确认 `setListener` 已设;音频通道(soundChannel)与焦点未被独占
3. **长文本中断** → 单次 `speak` 文本**上限 10000 字符**(官方,不含首尾空格),超长需分段播报

## 长语音 / 连续转写

连续转写不是独立 API,而是创建引擎时选**长语音识别模式**(`extraParams.recognizerMode: 'long'`,
取值以官方为准),配合 `RecognitionListener.onResult` 持续收中间结果:

```typescript
let params: speechRecognizer.CreateEngineParams = {
  language: 'zh-CN', online: 1,
  extraParams: { 'recognizerMode': 'long' }, // 长语音/连续场景(会议记录等)
};
let engine = await speechRecognizer.createEngine(params);
engine.setListener(listener); // onResult 持续回调,结束时显式 finish
```

短语音模式会在静音后自动结束;长语音模式适合不定长连续语音,需业务显式 `finish`。

## Speech Kit：场景化语音服务(TextReader / AICaption)

Speech Kit 提供的是**开箱即用的场景能力**,不是底层引擎:

```typescript
import { TextReader } from '@kit.SpeechKit';            // 文本朗读(播报)
import { AICaptionComponent } from '@kit.SpeechKit';     // AI 实时字幕组件
```

- **TextReader**:把文本交给系统朗读,适合资讯播报、无障碍朗读。
- **AICaptionComponent**:UI 组件,对音频流生成实时字幕。

> ⚠️ **声纹验证、语音唤醒不在本 Kit**。原先示例中的 `voiceprint.enroll/verify`、
> `MANAGE_VOICE_WAKEUP` 唤醒在官方 Speech Kit 中不存在,已移除。若业务确需声纹/唤醒,
> 先用 harmony-docs-retriever 确认是否有对应 Kit 与 API,再实现——勿编造。

## 权限声明

| 能力 | 权限 |
|------|------|
| 语音识别(在线) | `ohos.permission.INTERNET` + `ohos.permission.MICROPHONE` |
| 语音识别(离线) | `ohos.permission.MICROPHONE` |
| 语音合成(TTS) | 不需要特殊权限（仅播放音频） |
| TextReader / AICaption | 按官方文档,通常无需麦克风(以官方为准) |

## 排查清单

1. **ASR 一直"正在听"不返回结果** → 确认 `ohos.permission.MICROPHONE` 已授权，检查麦克风是否被其他应用占用
2. **TTS 合成输出为空白音频** → 检查文本编码（必须是 UTF-8），若含 emoji 需先过滤
3. **离线 ASR 精度差** → 离线模型按需下载，确认模型已就绪后再识别（就绪查询接口以官方/本地 d.ts 为准）
4. **ASR 和 TTS 同时使用冲突** → 两者共享音频焦点。先结束一方再启动另一方
5. **实时转写时间戳不准** → 连续语音场景下 `startTime` 存在系统偏差，对时序敏感的用 VAD(静音检测) 二次修正

> 官方文档：[Core Speech Kit](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/core-speech-kit-guide) · [Speech Kit](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/speech-kit-guide)
