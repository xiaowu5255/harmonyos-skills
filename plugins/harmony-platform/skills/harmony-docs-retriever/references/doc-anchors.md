# 鸿蒙官方文档锚点表(种子版 v0.2.0)

> 常见主题 → 已核实稳定 URL。**新增前必须用 `scripts/check-doc-urls.sh` 确认返回 200。**
> 域名统一为 `https://developer.huawei.com/consumer/cn/doc/`。
> 版本说明见 SKILL.md「步骤 3 版本消歧」:默认取 `harmonyos-guides/<slug>` 无版本后缀的新 slug。
> 表中 URL 均经 curl 实测 200(截至 2026-06)。文档会演进,失效以脚本巡检为准。

## 入口根

| 主题 | URL |
|---|---|
| 文档中心首页 | https://developer.huawei.com/consumer/cn/doc/ |

## ArkTS 语言与状态管理

| 主题 | URL |
|---|---|
| 认识 ArkTS 语言(基础入门) | https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-get-started |
| 状态管理概述 | https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-state-management-overview |
| 状态管理 V2 | https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-state-management-v2 |
| 状态管理 V1→V2 迁移 | https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-v1-v2-migration |

## ArkUI 框架与 UI 开发

| 主题 | URL |
|---|---|
| ArkUI 框架入口 | https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkui |
| 方舟开发框架 ArkUI 概述 | https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkui-overview |
| UI 开发(ArkTS 声明式范式) | https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-development |
| @Builder 全局动态更新(mutableBuilder) | https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-mutablebuilder |

## 工程配置

| 主题 | URL |
|---|---|
| 工程级 build-profile.json5 说明 | https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-hvigor-build-profile |
| build-profile.json5(app/模块级) | https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-hvigor-build-profile-app |
| module.json5 配置文件 | https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/module-configuration-file |

## 媒体 — Camera / Scan Kit

| 主题 | URL |
|---|---|
| Camera Kit(相机服务) | https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/camera-kit |
| 安全相机(ArkTS) | https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/camera-secure-photo |
| 分布式相机开发指南 | https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/camera-distributed |
| Scan Kit 自定义界面扫码 | https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/scan-customscan |

## 应用服务 — Push Kit

| 主题 | URL |
|---|---|
| Push Kit(推送服务)简介 | https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/push-kit-introduction |
| 推送通知消息 | https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/push-alert |
| 推送实况窗消息 | https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/push-update-liveview |

## 如何继续扩充

按 SKILL.md 步骤 2 用 `<关键词> site:developer.huawei.com/consumer/cn/doc` 搜索得到 canonical
URL(优先 `harmonyos-guides/<slug>` 无版本后缀形态,避开 `-V5`/`-V2`/带长数字 ID/`faqs` 页),
再 `bash scripts/check-doc-urls.sh` 验证 200 后以上表格式登记。高优先级待补:Account/Map/
Location/Notification 各 Kit 接入页、ArkTS API 参考错误码页、性能与测试指南。
