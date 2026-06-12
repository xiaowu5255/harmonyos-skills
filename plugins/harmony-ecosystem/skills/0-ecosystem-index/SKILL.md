---
name: 0-ecosystem-index
description: "鸿蒙应用服务索引。涉及华为账号登录、消息推送、应用内支付、通知系统、定位地图、端云一体化、分享/联系人/日历/DeepLink时加载本索引。provides: index, requires: harmony-index"
provides: index
requires: harmony-index
---

# 鸿蒙应用服务索引

覆盖华为生态服务、推送、支付、地图、云开发等应用服务。

## 子领域

| 子领域 | 内容 | 深度技能 |
|--------|------|----------|
| 华为核心 Kit | 账号服务(Account Kit)、推送(Push Kit)、应用内支付(IAP Kit)、地图(Map Kit)、扫码(Scan Kit) 通用接入 | `huawei-kits` |
| 通知 | 通知发布/更新/移除、角标、通知渠道、通知意图 | `notification`（新） |
| 定位与地图 | 定位(FusedLocation)、地理围栏、地图显示与交互 | `location-map`（新） |
| 端云一体化 | 云函数、云数据库、云存储、认证服务 | `cloud-foundation` |
| 社交分享 | 分享、联系人、日历、DeepLink 跳转 | `sharing-social`（新） |
| 广告/应用市场/数字空间 | 广告接入、应用市场服务、数字空间 | 暂无深度技能（未来扩展） |
