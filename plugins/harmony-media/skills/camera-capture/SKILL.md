---
name: camera-capture
description: "鸿蒙相机开发: Camera Kit 预览/拍照/录像、影随人动追焦(API24)、延迟预览输出。涉及相机功能、扫码集成、人脸追焦时使用本技能。[P2 待完善]"
license: MIT
metadata:
  target-platform: "HarmonyOS 6.x / API 20-24"
requires: 0-media-index
kits: [@kit.CameraKit]
---

# 相机开发：预览、拍照与录像

> **状态：P2 待完善** —— 本文档为轻量速查占位，后续将补充完整示例、API 详解与最佳实践。

## 覆盖 Kit 说明

**Camera Kit** 提供鸿蒙相机全链路能力：会话创建(`createCameraSession`)、预览流(`previewOutput`)、拍照流(`photoOutput`)、录像流(`videoOutput`)、元数据流(`metadataOutput`)的管理。API 24 新增"影随人动"追焦(`SubjectTrackingFocus`)，支持运动主体锁定跟踪对焦；同时支持 `DeferredPhotoOutput` 延迟预览输出，降低预览功耗。

## 常见场景速查

| 场景 | 核心 API | 需关注的 Kit |
|------|---------|-------------|
| 相机预览 | `cameraSession.startPreview()` | CameraKit |
| 拍照输出 | `session.createPhotoOutput()` | CameraKit |
| 录像输出 | `session.createVideoOutput()` + AVCodecKit | CameraKit, AVCodecKit |
| 二维码扫描 | `session.createMetadataOutput(metadataTypes: ['barcode'])` | CameraKit, ScanKit |
| 人脸追焦 | `SubjectTrackingFocus` (API 24+) | CameraKit |
| 延迟预览 | `DeferredPhotoOutput` | CameraKit |

## P2 完善计划

以下内容将在后续版本补全：

- [ ] 完整的相机会话生命周期示例(打开→预览→拍照→释放)
- [ ] 影随人动追焦的配置与回调处理示例
- [ ] 扫码集成联合使用 Scan Kit 的完整流程
- [ ] 相机权限申请(`ohos.permission.CAMERA`)与用户授权处理
- [ ] 多设备适应性(折叠屏相机切换、平板前后摄管理)
- [ ] 性能优化：预览帧率控制、内存占用管理
