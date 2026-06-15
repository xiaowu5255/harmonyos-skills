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

## Overview

鸿蒙音频开发: Audio Kit 音频播放/录制、音频流类型选型、音频焦点/会话管理、 设备路由(耳机/扬声器)、MIDI 外设通信。

## When to Use

- 涉及 播放音乐 时
- 涉及 录音 时
- 涉及 语音通话 时

## ⚠️ 常见误区与反模式

| 误区 | 正确做法 | 来源 |
|------|---------|------|
| 用 `createAudioSession()` 直接创建会话 | API 12+ 用 `getSessionManager()` + `activateAudioSession()` | Audio Kit API 文档 |
| `AudioCapturer` 用旧嵌套结构 | API 12+ 嵌套为 `{ audioCapturerOptions: { ... } }` | Audio Kit 迁移文档 |
| MIDI 用 `MIDIPlayer` 高级 API | API 24+ 正本清源为 C-API (UMP 协议);MIDIPlayer 仅部分支持 | MIDI Kit 文档 |
| 音频焦点靠 `requestFocus()` 单独调 | 必须配合 `AVSession` 注册;焦点竞争时系统优先选择有会话的应用 | AVSession + AudioSession |
| 设备切换用 `setOutputDevice` 旧名 | API 12+ 用 `audioRenderer.setDeviceChangeCallback` 监听 `DeviceFlag` | 设备路由文档 |

> **验证方法**:音频 API 以 `@kit.AudioKit` 声明文件为准。
> 用 `grep -r "AudioRenderer\|AudioCapturer" oh_modules/@kit.AudioKit/` 查实际可用接口。

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

## 音频焦点(AudioSession)抢占与恢复(API 12+)

API 名以本地 SDK `@ohos.multimedia.audio.d.ts` 为准;以下经官方
[AudioSessionManager](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/arkts-apis-audio-audiosessionmanager)
核验(API 12+):**先从 AudioManager 取 AudioSessionManager,再 activate**,没有 `createAudioSession` 这个接口。

```ts
import { audio } from '@kit.AudioKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 1. 取 AudioSessionManager(由 audioManager 派生,不是 audio.createXxx)
const audioManager = audio.getAudioManager();
const audioSessionManager: audio.AudioSessionManager = audioManager.getSessionManager();

// 2. strategy 是 AudioSessionStrategy 对象,枚举装在 concurrencyMode 字段里
const strategy: audio.AudioSessionStrategy = {
  concurrencyMode: audio.AudioConcurrencyMode.CONCURRENCY_PAUSE_OTHERS, // 被抢占时暂停
};

// 3. activateAudioSession 返回 Promise
audioSessionManager.activateAudioSession(strategy)
  .then(() => console.info('audio session activated'))
  .catch((err: BusinessError) => console.error(`activate failed: ${err}`));

// 4. 监听停用事件(参数是 AudioSessionDeactivatedEvent,带 reason)
audioSessionManager.on('audioSessionDeactivated', (event) => {
  // event.reason: AudioSessionDeactivatedReason
  //   LOW_PRIORITY(被低优先级流抢占) / TIMEOUT(超时未用被回收)
  // 暂停播放、释放资源
});
```

- 枚举值以官方为准,常见:`CONCURRENCY_MIX_WITH_OTHERS`(混音)、
  `CONCURRENCY_DUCK_OTHERS`(压低其他音频)、`CONCURRENCY_PAUSE_OTHERS`(暂停其他)。
- 纯音乐播放器用 `CONCURRENCY_PAUSE_OTHERS`——通话来了暂停。
- 导航语音用 `CONCURRENCY_DUCK_OTHERS`——压低其他音频音量而非抢占焦点。
- **不要忽略 `audioSessionDeactivated` 回调**——不做响应会导致"两个播放器
  同时出声"或"通话结束后不恢复播放"。恢复播放在重新拿到焦点后由业务自行触发。

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

官方 `createAudioCapturer` 的 options 是 **嵌套结构**(`streamInfo` + `capturerInfo`),
不是平铺字段。经
[audio API](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/arkts-apis-audio-f)
核验:

```ts
const streamInfo: audio.AudioStreamInfo = {
  samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_48000,
  channels: audio.AudioChannel.CHANNEL_2,
  sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
  encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW,
};
const capturerInfo: audio.AudioCapturerInfo = {
  source: audio.SourceType.SOURCE_TYPE_MIC, // 录音源,按场景选
  capturerFlags: 0,
};
const audioCapturer: audio.AudioCapturer =
  await audio.createAudioCapturer({ streamInfo, capturerInfo });
```

| 权限 | 使用场景 |
|------|---------|
| `ohos.permission.MICROPHONE` | 所有录音操作 |
| 无需权限 | 仅读取当前播放音量(只读不采集) |

- 录音源选型：`SOURCE_TYPE_MIC`(麦克风) / `SOURCE_TYPE_VOICE_CALL`(上行通话音频)
  / `SOURCE_TYPE_CAMCORDER`(摄像收音,带方向性)
- 录音期间后台需 continuousTask + LOCATION(部分场景关联蓝牙),同见 background-tasks

## 设备路由监听(蓝牙耳机插拔)

`audioManager.on('deviceChange')` 已于 **API 9 废弃**;改用 `AudioRoutingManager`,
且 `on('deviceChange', ...)` 第二参数是 **`DeviceFlag`(必填)**,指定监听的设备方向。
经
[AudioRoutingManager](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/arkts-apis-audio-audioroutingmanager)
核验:

```ts
const routingManager: audio.AudioRoutingManager =
  audio.getAudioManager().getRoutingManager();

routingManager.on('deviceChange', audio.DeviceFlag.OUTPUT_DEVICES_FLAG,
  (action: audio.DeviceChangeAction) => {
    // action.type: audio.DeviceChangeType.CONNECT / DISCONNECT
    // action.deviceDescriptors[i].deviceType: SPEAKER / WIRED_HEADSET / BLUETOOTH_A2DP / BLUETOOTH_SCO ...
  });
```

- 蓝牙耳机连接后自动路由，通常无需手动切换。
- 通话场景 SCO 协议(双向低延迟)与音乐场景 A2DP 协议(单向高质量)自动切换。
- 需要手动选择输出设备时用 `routingManager.selectOutputDevice(...)`(API 名以本地 d.ts 为准)。

## MIDI(OHMIDI,**纯 C-API,API 24 起**)

⚠ MIDI **没有 ArkTS 接口**——只有 Native C-API(`native_midi.h`),需经 NDK 调用(转 native-ndk 技能)。
数据格式是 **UMP(Universal MIDI Packet)**,不是裸 1-3 字节短消息。经
[OHMIDI C API](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-ohmidi)
核验,典型流程:

```c
// 1. 创建 client(全局上限 8 个,单 app 上限 2 个,建议全程复用 1 个)
OH_MIDIClient *client = NULL;
OH_MIDIClient_Create(&client, callbacks, userData);
// 2. 发现设备/端口 → 3. 打开设备
OH_MIDIDevice *device = NULL;
OH_MIDIClient_OpenDevice(client, deviceId, &device);
// 4. 按方向打开输入/输出端口
OH_MIDIDevice_OpenOutputPort(device, descriptor);
// 5. 收(回调 UMP)/ 发(构造 UMP 包):
OH_MIDIDevice_Send(device, portIndex, events, eventCount, &eventsWritten);
// 6. 用完关端口、关设备、销毁 client
```

- 接收 MIDI 数据通过回调以 UMP 格式返回;发送需构造 UMP 数据包。
- client 配额硬限:全局 ≤8、单 app ≤2,**一个 app 维持单 client 管理多设备/端口**。
- USB MIDI 与 BLE MIDI 均走此统一 C 接口。

## 音频性能调优(低延迟模式)

| 场景 | 策略 |
|------|------|
| 音乐播放 | 默认缓冲(避免卡顿) |
| 游戏音效 | 低延迟模式: bufferSize=1024 frames, sampleRate 匹配设备原生采样率 |
| 实时音频(通话/乐器) | 最低延迟: 小 buffer + 高优先级线程 + 避免 GC 抖动 |
| MIDI 输入延迟 | USB 通常优于 BLE;具体数值依设备而定,实测为准,不臆断固定毫秒 |

## 排查清单：“无声/音质差/录音失败”

1. StreamUsage 选对了吗？——"没声音"的第一个排查项永远是这个。
2. AudioSession focus 是否被抢占——检查 `audioSessionDeactivated` 是否触发。
3. 蓝牙耳机场景——A2DP(音乐)与 SCO(通话)切换是否导致短暂无声？正常现象。
4. 录音无数据——MICROPHONE 权限是否已授予？音频源是否与硬件通道对应？
5. MIDI 设备不识别——检查 USB/BLE 连接，确认设备兼容标准 MIDI 协议。
