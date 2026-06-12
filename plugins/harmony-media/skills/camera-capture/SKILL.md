---
name: camera-capture
description: "鸿蒙相机开发: Camera Kit 预览/拍照/录像、影随人动追焦(API24)、延迟预览输出。涉及相机功能、扫码集成、人脸追焦时使用本技能。[P2 待完善]"
license: MIT
metadata:
  target-platform: "HarmonyOS 6.x / API 20-24"
requires: 0-media-index
kits: ["@kit.CameraKit"]
---

# 相机开发：预览、拍照与录像

> **状态：P2 待完善** —— 本文档为轻量速查占位，后续将补充完整示例、API 详解与最佳实践。

## 覆盖 Kit 说明

**Camera Kit** 提供鸿蒙相机全链路能力：相机会话管理与预览流/拍照流/录像流/元数据流的配置输出。"影随人动"主体追焦、分段式拍照等增强能力以官方文档为准(具体 API 名与版本待 sdk-diff 核实后补充)。

## 常见场景速查

| 场景 | 需关注的 Kit | 官方文档入口 |
|------|-------------|------------|
| 相机预览 | CameraKit | [相机预览指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/camera-preview) |
| 拍照输出 | CameraKit | [拍照指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/camera-overview) |
| 录像输出 | CameraKit, AVCodecKit | [录像指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/camera-overview) |
| 二维码扫描 | CameraKit, ScanKit | [扫码集成指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/camera-overview) |
| 人脸追焦 | CameraKit | [影随人动追焦指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/camera-overview) |
| 延迟预览 | CameraKit | [延迟预览指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/camera-overview) |

## P2 完善计划

以下内容将在后续版本补全：

- [ ] 完整的相机会话生命周期示例(打开→预览→拍照→释放)
- [ ] 影随人动追焦的配置与回调处理示例
- [ ] 扫码集成联合使用 Scan Kit 的完整流程
- [ ] 相机权限申请(`ohos.permission.CAMERA`)与用户授权处理
- [ ] 多设备适应性(折叠屏相机切换、平板前后摄管理)
- [ ] 性能优化：预览帧率控制、内存占用管理
- [ ] 用 sdk-diff 验证所有 API 名后再补回速查表
