---
name: release-and-compliance
description: >-
  鸿蒙应用发布与合规:版本号管理、release 包构建检查、AGC 上架流程、隐私
  合规(隐私声明/权限用途/SDK 目录)、审核常见驳回与整改。凡是准备提审上架、
  被审核驳回、做合规自查、配置版本号策略时使用本技能。
license: MIT
requires: 0-release-index
metadata:
  target-platform: "HarmonyOS 6.x / API 20-24 + AGC"
---

# 发布与合规

## 版本号(AppScope/app.json5)

- versionCode:整数,**每次提审必须严格递增**,只增不减,内部构建也建议
  用 CI 自动递增避免撞号。
- versionName:语义化展示版本。两者解耦管理:code 机器管,name 人管。

## release 包构建前检查清单

1. 签名:发布证书 + 发布 Profile(调试 Profile 签的包提不了审,见
   signing-and-certificates 第 3 步)。
2. 混淆:DevEco 5.0.3.600 起新建工程混淆默认关闭,发布包应**显式开启**
  (`ruleOptions.enable: true`)保护代码;**开启后必须真机实测 release 包核心流程**——
  "debug 全对 release 崩"专题见 hvigor-build 混淆节。
3. 构建产物:上架用 App Pack(.app,hvigorw assembleApp),不是单 HAP。
4. 清理:日志开关关闭、测试入口/调试菜单移除、网络环境指向生产。
5. compatibleSdkVersion 复核:它决定商店分发的设备范围。

## AGC 上架流程

软件包上传 → 应用信息(名称/图标/截图/分类)→ 隐私与资质材料 →
版本说明 → 提审。沙盒/开放式测试(邀请测试)可在正式上架前走灰度。

## 隐私合规(驳回重灾区,逐条自查)

1. **隐私声明**:链接可访问、内容与实际收集行为一致、首启弹窗"同意前
   不得收集"——同意前就初始化统计/推送 SDK 是典型驳回点,SDK 初始化
   必须后置到用户同意之后。
2. **权限最小化**:requestPermissions 里没用到的权限删掉;每个 user_grant
   权限的 reason 用途说明真实、具体(见 security-permissions)。
3. **第三方 SDK 清单**:声明所集成 SDK 及其收集行为,与隐私声明一致。
4. 账号类应用提供注销入口;UGC 类有举报/审核机制;特定行业备好资质。

## 常见驳回 → 整改映射

| 驳回类别 | 第一排查点 |
|---|---|
| 隐私不合规 | 同意前是否有网络请求/设备信息读取(抓包验证) |
| 权限滥用 | 声明了但场景里用不到/说明含糊 |
| 崩溃/无法运行 | 审核环境=生产 release 包,本地用同一包复测 |
| 元数据问题 | 截图与实际功能不符、名称侵权风险 |

被驳回时:逐字读驳回意见 → 用上表定位 → 修复后在驳回回复中写明改动点,
含糊重提大概率二次驳回。

## 发布后

崩溃与运营数据接入(AGC 侧服务按需开通);热修复能力受平台政策约束,
不要预设可热修,以当期官方政策为准。
