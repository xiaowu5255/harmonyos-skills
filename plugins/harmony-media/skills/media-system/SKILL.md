---
name: media-system
description: >-
  鸿蒙播控与媒体系统: AVSession Kit 播控中心、媒体通知栏、
  跨设备投屏与流转、DRM 版权保护、扫码(Scan Kit)。涉及后台播放、
  锁屏控制、投屏到电视时使用本技能。
license: MIT
requires: 0-media-index
kits: ["@kit.AVSessionKit", "@kit.DrmKit", "@kit.ScanKit"]
metadata:
  target-platform: "HarmonyOS 6.x / API 20-24"
---

## Overview

鸿蒙播控与媒体系统: AVSession Kit 播控中心、媒体通知栏、 跨设备投屏与流转、DRM 版权保护、扫码(Scan Kit)。

## When to Use

- 涉及 后台播放 时
- 涉及 锁屏控制 时
- 涉及 投屏到电视 时

## ⚠️ 常见误区与反模式

| 误区 | 正确做法 | 来源 |
|------|---------|------|
| 用 `AVPlayer` 做播控交互 | `AVPlayer` 是底层播放器;播控交互必须通过 `AVSession` 接入系统控制中心 | AVSession 文档 |
| `scanBarcode()` 直接返回结果 | API 12+ `scanBarcode` 是异步 Promise;需 `await` 且处理 `BusinessError` | Scan Kit 文档 |
| DRM 直接用 `MediaKeySystem` | 需先 `isMediaKeySystemSupported()` 检查设备能力;不是所有设备都支持所有 DRM 类型 | DRM Kit 文档 |
| 后台播放只需 `continuousTask` | 还需注册 `AVSession` + 设置音频焦点;缺一步都会被系统打断 | 后台播放最佳实践 |
| 扫码用 `@system.barcode` 旧 API | API 12+ 用 `@kit.ScanKit` 的 `scanBarcode()` | 模块迁移文档 |

> **验证方法**:多媒体 API 以 `@kit.AudioKit` / `@kit.MediaKit` / `@kit.ScanKit` 声明文件为准。
> 不确定的 API 名先 `grep` 本地 SDK 再使用。

# 播控与媒体系统：AVSession、DRM、扫码

## AVSession 心智模型

AVSession 是你应用程序与**系统播控中心**之间的桥梁——锁屏的播放按钮、控制中心的上一曲/下一曲，都通过 AVSession 通信。

```
你的 App                   系统播控中心              手表/耳机/车机
  │                           │                        │
  ├─ createAVSession ────────►│                        │
  ├─ setMetadata(歌名/封面)───►│──── 广播 ──────────────►│
  ├─ activate() ─────────────►│                        │
  │   (成为活跃会话)            │                        │
  └─ on('play'/'pause'/'stopNext') ←─── 用户点按钮 ────┘
```

**不变量**：AVSession 是"单例广播"——同一时间只有一个应用是活跃播控。不设 metadata 就被系统忽略，不注册 controlCommand 就收不到用户操作。

## 本地与投播

| 维度 | 本地播控 | 投播到远端设备 |
|------|---------|--------------|
| 用途 | 本机播控（锁屏/通知栏/控制中心） | 跨设备流转（手机→平板→电视） |
| 会话创建 | `createAVSession(context, 'audio')` | 同上，通过系统播控中心发起投播 |
| 投播方式 | N/A | 用户从播控中心点选目标设备；应用侧配合 `AVCastController` 处理投播状态 |
| 前提 | 无额外要求 | 同账号、同 WiFi、开启蓝牙（设备发现） |

**分布式流转五步排查**（按优先级依次检查）：
1. 两台设备都已登录同一华为账号
2. 两台设备同一个 WiFi 且连通（ping 测试）
3. 蓝牙已开启（负责设备发现，非传输数据）
4. 分布式能力已申请：`ohos.permission.DISTRIBUTED_DATASYNC`
5. 目标设备支持音视频播控（平板/电视支持，手表仅通知）

## 播控自检清单

接入播控必过的 6 项检查：

- [ ] `createAVSession` 的 type 与 `AudioRenderer` 匹配（`'audio'` / `'video'`）
- [ ] `setMetadata` 填了 mediaId / title / artist / albumImage（缺封面系统不展示）
- [ ] 时长 `setDuration(totalDuration)` 和进度 `setProgress(currentPosition, speed)` 持续更新
- [ ] `activate()` 被调了——不激活系统不认
- [ ] `on('play')` / `on('pause')` / `on('stopNext')` 三个事件都有实现
- [ ] `on('seek')` 处理了拖动进度条（视频/播客场景必须）

## DRM Kit 速览

`@kit.DrmKit` 处理受版权保护的媒体内容。三个核心流程：

```typescript
// 1. 创建 DRM 实例
let drmManager = drm.createDrmManager('com.wiseplay.drm');
// 2. 打开媒体 → 判断是否需要许可证
drmManager.openMedia(uri).then(status => { /* 检查 DRM 方案 */ });
// 3. 许可证获取/续期
drmManager.generateLicense(licenseServerUrl, requestHeaders);
```

**典型坑**：DRM 内容不能用普通 AVPlayer 直接播放，必须用 `AVCodec` 绑定 DRM 的 `decryptConfig`。看到 "can not play this protected content" 错误，第一步检查 `drmManager.isMediaKeyProvisioned()`。

## Scan Kit：二维码的正确打开方式

不要用相机预览自己解析二维码——**系统已内置专为扫码优化的 Scan Kit**：

```typescript
import { scanBarcode, scanCore, customScan } from '@kit.ScanKit';

// 方式1：默认扫码界面（取景框/闪光灯/相册选图）
let options: scanBarcode.ScanOptions = {
  scanTypes: [scanCore.ScanType.ALL], enableMultiMode: true, enableAlbum: true,
};
scanBarcode.startScanForResult(context, options).then((result: scanBarcode.ScanResult) => {
  console.info(result.originalValue); // 解码结果
});

// 方式2：自定义扫码 UI — customScan.init → start(绑定 XComponent surfaceId)
customScan.init(options);
let viewControl: customScan.ViewControl = { width: w, height: h, surfaceId };
customScan.start(viewControl).then((results: Array<scanBarcode.ScanResult>) => { /* 结果数组 */ });
```

**选型原则**：默认界面满足绝大多数场景（取景框+闪光灯+相册）；仅需自定义取景 UI 时才用
`customScan`（要自管 XComponent surface 与生命周期 init/start/stop/release）。

## 排查清单

1. **播控中心不显示我的应用** → 确认 `activate()` 已调 + metadata.mediaId 非空
2. **手表/耳机按键控制不生效** → AVSession 的 `on('controlCommand')` 未注册对应事件
3. **投屏失败"设备不可达"** → 分布式五条前置清单逐条核对
4. **DRM 视频花屏或无声** → 检查 `decryptConfig` 是否正确绑定到 AVCodec 的 configure 步骤
5. **扫码识别率低** → 用 `options.scanTypes` 指定预期码制（如 `scanCore.ScanType.QR_CODE`）而非全类型，缩小范围提识别率

> 官方文档：[AVSession Kit](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/avsession-kit) · [DRM Kit](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/drm-kit) · [Scan Kit](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/scan-kit-guide)
