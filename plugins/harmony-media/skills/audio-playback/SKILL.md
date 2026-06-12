---
name: audio-playback
description: >-
  鸿蒙音频开发: Audio Kit 音频播放/录制、音频流类型选型、音频焦点/会话管理、
  设备路由(耳机/扬声器)、MIDI 外设通信。涉及播放音乐/录音/语音通话时使用
  本技能。
license: MIT
requires: 0-media-index
kits: ["@kit.AudioKit"]
metadata:
  target-platform: "HarmonyOS 6.x / API 20-24"
---

# 音频开发：播放、录制与焦点管理

## 音频流类型(StreamUsage)选型

选错 StreamUsage 是无声、音量异常、被系统打断的第一根源——行为差异
远大于参数差异。

| StreamUsage | 场景 | 系统行为 |
|-------------|------|---------|
| `STREAM_USAGE_MUSIC` | 音乐播放、播客 | 受音量键单独控制；可被通话抢占；后台可播放(需长时任务) |
| `STREAM_USAGE_VOICE_COMMUNICATION` | VoIP 通话、视频会议 | 强制走听筒(贴近耳朵)/扬声器；回声消除/降噪自动开启 |
| `STREAM_USAGE_NOTIFICATION` | 通知提示音 | 短暂播放，不可循环；音量独立于媒体音量 |
| `STREAM_USAGE_RINGTONE` | 来电铃声 | 音量最大优先；不受勿扰模式完全静音(取决于设置) |
| `STREAM_USAGE_MEDIA` | 视频播放、游戏音效 | 行为与 MUSIC 相似，但某些设备上游戏模式会降低延迟 |
| `STREAM_USAGE_VOICE_ASSISTANT` | AI 语音助手交互 | 独占录音+播放通道，最高优先级 |

**选错典型案例**：VoIP 通话误用 MUSIC 流——对方听不到声音(回声消除未开)、
扬声器不切换(走错音频路由)。

## 音频焦点(AudioSession)抢占与恢复

```ts
const audioSession = audio.createAudioSession({
  strategy: audio.AudioSessionStrategy.CONCURRENCY_PAUSE, // 被抢占时暂停
});

audioSession.on('audioSessionDeactivated', (reason) => {
  // reason: LOWPRIORITY(低优先级抢占) / INTERNAL(系统抢占如通话)
  // 暂停播放，释放资源
});
audioSession.on('audioSessionActivated', () => {
  // 焦点恢复，继续播放
});
```

- 纯音乐播放器用 `CONCURRENCY_PAUSE`——通话来了暂停，通话结束自动恢复
- 导航语音用 `CONCURRENCY_DUCK`——压低其他音频音量而非抢占焦点
- **不要忽略 `audioSessionDeactivated` 回调**——不做响应会导致"两个播放器
  同时出声"或"通话结束后不恢复播放"

## 音频播放状态机

```
IDLE → PREPARED → PLAYING ──→ PAUSED
  ↑                             │
  └────────── STOPPED ←─────────┘
```

每个状态转换必须按路径走：
- `play()` 只能在 PREPARED/PAUSED/STOPPED 状态调用
- `pause()` 只能在 PLAYING 状态调用
- **不要在 IDLE 状态直接 play**——必须先 `prepare()`
- 状态转换是异步的，用 `on('stateChange')` 监听确认，不要假设同步完成

## 录制权限与音频源

```ts
const audioCapturer = await audio.createAudioCapturer({
  streamUsage: audio.StreamUsage.STREAM_USAGE_VOICE_COMMUNICATION,
  source: audio.SourceType.SOURCE_TYPE_MIC,
});
```

| 权限 | 使用场景 |
|------|---------|
| `ohos.permission.MICROPHONE` | 所有录音操作 |
| 无需权限 | 仅读取当前播放音量(只读不采集) |

- 录音源选型：`SOURCE_TYPE_MIC`(麦克风) / `SOURCE_TYPE_VOICE_CALL`(上行通话音频)
  / `SOURCE_TYPE_CAMCORDER`(摄像收音,带方向性)
- 录音期间后台需 continuousTask + LOCATION(部分场景关联蓝牙),同见 background-tasks

## 设备路由监听(蓝牙耳机插拔)

```ts
audioRoutingManager.on('deviceChange', (deviceChangeAction) => {
  // deviceChangeAction.type: 'DEVICE_AVAILABLE' / 'DEVICE_UNAVAILABLE'
  // deviceChangeAction.deviceType: SPEAKER / WIRED_HEADSET / BLUETOOTH_A2DP / BLUETOOTH_SCO
});
```

- 蓝牙耳机连接后自动路由，通常无需手动切换
- 通话场景 SCO 协议(双向低延迟)与音乐场景 A2DP 协议(单向高质量)自动切换
- 需要手动切换设备时用 `audioRoutingManager.selectDevice()`

## MIDI C API(USB/BLE 设备连接与消息收发)

```ts
const midiDevice = midi.createMIDIDevice();
midiDevice.connect(deviceId).then(() => {
  midiDevice.on('midiMessage', (msg) => { /* 标准 MIDI 消息 */ });
  midiDevice.sendMidiMessage([0x90, 0x3C, 0x7F]); // Note On, C4, velocity 127
});
```

- 支持 USB MIDI 和 BLE MIDI 两种传输协议
- MIDI 消息为 1-3 字节标准格式(Note On/Off, CC, Program Change 等)
- 多设备并发时按 deviceId 区分消息来源，不要混用线程处理——推入 TaskPool

## 音频性能调优(低延迟模式)

| 场景 | 策略 |
|------|------|
| 音乐播放 | 默认缓冲(避免卡顿) |
| 游戏音效 | 低延迟模式: bufferSize=1024 frames, sampleRate 匹配设备原生采样率 |
| 实时音频(通话/乐器) | 最低延迟: 小 buffer + 高优先级线程 + 避免 GC 抖动 |
| MIDI 输入延迟 | USB MIDI < 1ms, BLE MIDI 7-15ms——对延迟敏感场景优先 USB |

## 排查清单：“无声/音质差/录音失败”

1. StreamUsage 选对了吗？——"没声音"的第一个排查项永远是这个。
2. AudioSession focus 是否被抢占——检查 `audioSessionDeactivated` 是否触发。
3. 蓝牙耳机场景——A2DP(音乐)与 SCO(通话)切换是否导致短暂无声？正常现象。
4. 录音无数据——MICROPHONE 权限是否已授予？音频源是否与硬件通道对应？
5. MIDI 设备不识别——检查 USB/BLE 连接，确认设备兼容标准 MIDI 协议。
