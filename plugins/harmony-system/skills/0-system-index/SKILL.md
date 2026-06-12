---
name: 0-system-index
description: "鸿蒙系统能力索引。涉及后台任务、权限安全、网络/通信、数据存储、文件管理、加密/认证、分布式、Native NDK、传感器/设备时加载本索引。provides: index, requires: harmony-index"
provides: index
requires: harmony-index
---

# 鸿蒙系统能力索引

覆盖后台任务、安全、网络、存储、分布式等系统级能力。

## 子领域

| 子领域 | 内容 | 深度技能 |
|--------|------|----------|
| 后台任务 | 短时任务、长时任务、延迟任务、提醒 | `background-tasks` |
| 权限与安全 | 权限模型(ATL/用户授权)、Picker 选择器、ACL 受限权限 | `security-permissions` |
| 加密与认证 | 加解密、密钥管理(HUKS)、生物认证 | `crypto-security`（新） |
| 网络请求 | HTTP/HTTPS、WebSocket、Socket、弱网优化 | `network-requests`（新） |
| 近场通信 | 蓝牙、WiFi、星闪(NearLink)、NFC | `connectivity`（新） |
| 数据存储 | Preferences、关系数据库(RDB)、分布式数据库 | `data-storage` |
| 文件管理 | 沙箱文件、用户文件选取、备份恢复 | `file-system`（新） |
| 分布式能力 | 设备流转、跨设备协同、任务接续 | `distributed` |
| Native NDK | C/C++ 开发、N-API 桥接 | `native-ndk` |
| 功能框架(FASt/基础服务) | 系统基础服务任务 | 暂无深度技能（未来扩展） |
