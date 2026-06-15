---
name: camera-capture
description: >-
  鸿蒙相机开发: Camera Kit 会话管理、预览/拍照/录像流配置、
  影随人动追焦、分段式拍照、CameraPicker 快速集成。涉及相机功能、
  拍照上传、扫码集成时使用本技能。
license: MIT
requires: 0-media-index
kits: ["@kit.CameraKit"]
metadata:
  target-platform: "HarmonyOS 6.x / API 20-24"
---

## Overview

鸿蒙相机开发: Camera Kit 会话管理、预览/拍照/录像流配置、 影随人动追焦、分段式拍照、CameraPicker 快速集成。

## When to Use

- 涉及 相机功能 时
- 涉及 拍照上传 时
- 涉及 扫码集成 时

# 相机开发：会话、流与生命周期

## 心智模型：两条路径

开发相机应用前先做决策——用**系统能力**还是自己**控制硬件**？

| 路径 | 方式 | 权限 | 适用场景 |
|------|------|------|---------|
| 快速集成 | `CameraPicker` | **无需声明** | 简单拍照/录像，一页需求 |
| 深度控制 | Camera Kit 会话模型 | `ohos.permission.CAMERA` | 美颜预览、连拍、自定义 UI |

**决策原则**：能用 CameraPicker 就别碰会话模型——每次 `Session.beginConfig()` 都是填坑的起点。

## 会话(Session)五步法

```
getCameraManager → getSupportedCameras → createCameraInput
  → createPreviewOutput → createSession
  → beginConfig → addInput + addOutput → commitConfig → start
```

**三个不变量**：
1. 任何配置变更（切镜头/改分辨率）必须走 `beginConfig → commitConfig`，未配置就操作 = 错误码 **7400103**（"Session not config"，如配置前就 start）
2. Session 状态机不可跳跃：CONFIG → READY → START，跳级必崩
3. 释放顺序与创建严格相反：先 stop → 先释放 output → 再释放 input → 最后 releaseCamera

## 输入输出流选型

```
会话(Session)
  ├── CameraInput     ← 镜头选择：前置/后置/广角/长焦
  ├── PreviewOutput   ← 画面预览：Surface(XComponent)
  ├── PhotoOutput     ← 拍照输出：单张/连拍/分段式(Raw)
  └── VideoOutput     ← 录像输出：AVRecorder 对接
```

**镜头选择关键 API**：
- `CAMERA_POSITION_FRONT` / `CAMERA_POSITION_BACK`
- `CAMERA_POSITION_FOLD_INNER` (折叠屏内屏)
- 多摄场景按焦距选 `cameraManager.getSupportedCameras()` 后对比 `focalLength`

**预览输出**：`createPreviewOutput(surfaceId)`，surfaceId 来自 XComponent。预览尺寸应匹配屏幕宽高比，避免拉伸。

**拍照双模式**：
- `PhotoOutput` 标准拍：`capture()` → `on('photoAvailable')` 取回调
- 分段式拍照(API 18+)：`createPhotoOutputWithoutSurface` → 裸数据自己编码，适合 AI 美颜后合成

## 权限与生命周期联动

相机是"前台独占资源"，遵守**四状态硬约束**：

| 生命周期事件 | 相机行为 | 理由 |
|-------------|---------|------|
| `onForeground` | `session.start()` | 恢复预览 |
| `onBackground` | `session.stop()` + `releaseCamera()` | 释放硬件给其他应用 |
| `onDestroy` | 全量释放 input/output/session/cameraManager | 防止句柄泄漏 |
| 折叠屏展开/闭合 | `beginConfig → 重新选 input → commitConfig` | 内外屏镜头不同 |

**最大坑**：在 `onBackground` 时忘记 releaseCamera，轻则句柄泄漏，重则系统 CameraService 崩（其他应用也打不开相机）。

## 进阶场景速查

| 场景 | 关键点 |
|------|--------|
| 美颜预览 | XComponent + EGL 绑定 surface，GPU shader 实时处理预览帧 |
| 影随人动追焦 | session 启用 `isAutoFocus`，监听 `on('focusStateChange')` |
| 分段式拍照 | `ImageReceiver` 接 `PhotoOutput` 的 YUV/Raw 流 |
| 双景录像 | 两个 `VideoOutput` + 两个 `CameraInput`（需设备支持） |
| 二维码扫描 | 优先用 Scan Kit (`@kit.ScanKit`) 的扫码组件，别拿相机预览自己解析 |

## 排查清单

1. **打开相机空白** → 确认 `ohos.permission.CAMERA` 已在 module.json5 声明且用户已授权
2. **切后台回来预览冻结** → 检查 `onForeground` 是否调了 `session.start()`
3. **拍照无回调** → 检查 `ImageReceiver` 的 `on('imageArrival')` 注册时机，必须在 capture 之前
4. **内存 OOM** → 高分辨率连拍时，PhotoOutput 回调中立即释放 `image.release()`
5. **折叠屏切镜头不工作** → 监听 `display.on('foldStatusChange')`，重走 beginConfig 全流程

> 官方文档：[Camera Kit 开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/camera-kit)
