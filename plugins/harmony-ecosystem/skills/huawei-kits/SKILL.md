---
name: huawei-kits
description: >-
  华为生态 Kit 接入:华为账号一键登录(Account Kit)、推送(Push Kit)、应用内
  支付(IAP Kit)、地图/定位、扫码(Scan Kit)等开放能力。凡是涉及接入任何
  华为系 Kit、"接入代码对但一直报错/拿不到 token/拉不起登录"类问题时使用本
  技能。生态 Kit 的失败九成出在 AGC 侧前置配置而非端侧代码,先验前置链路。
license: MIT
requires: 0-ecosystem-index
kits: ["@hms.account", "@hms.push", "@hms.iap", "@kit.ScanKit"]
metadata:
  target-platform: "HarmonyOS 6.x / API 20-24 + AGC"
---

## Overview

华为生态 Kit 接入:华为账号一键登录(Account Kit)、推送(Push Kit)、应用内 支付(IAP Kit)、地图/定位、扫码(Scan Kit)等开放能力。生态 Kit 的失败九成出在 AGC 侧前置配置而非端侧代码,先验前置链路。

## When to Use

- 涉及 接入任何 华为系 Kit 时
- 涉及 "接入代码对但一直报错 时
- 涉及 拿不到 token 时
- 涉及 拉不起登录"类问题 时

# 华为生态 Kit 接入

## 通用接入方法论(每个 Kit 都适用)

任何 Kit 的接入 = **AGC 前置配置 + 工程配置 + 端侧代码** 三段,排错也按此
三段二分。通用前置清单:

1. AGC 中应用已创建,bundleName 与工程完全一致。
2. 该 Kit 对应的服务已在 AGC **显式开通**(很多服务默认关闭)。
3. **公钥指纹已配置到 AGC**(HarmonyOS 用"公钥指纹",非 Android 的 SHA256 证书指纹;
   账号、支付、推送、地图类强校验项;换签名证书后必须同步更新,否则全线校验失败
   如 Account 报 1001500001——这是换机器/换证书后"突然全坏了"的标准答案)。
4. 需要 scope/资质的能力(支付、部分账号信息)已申请并通过审核。
5. module.json5 中该 Kit 要求的权限/配置项(如 client_id 类 metadata)已加。

端侧报错先回到这五条逐项核对,再看代码。

## Account Kit(华为账号一键登录)

- 推荐用系统提供的授权登录控件/接口获取 Authorization Code,**code 送
  自家服务端换 token 与 UnionID/OpenID**;端侧直连拿用户信息的做法不适合
  生产(密钥不能放端侧)。
- UnionID(同开发者跨应用一致)vs OpenID(单应用)——账号体系设计先选对。
- 测试账号在 AGC 沙箱配置;真机登录的账号地区与应用上架地区不匹配会失败。

## Push Kit(推送)

- 链路:端侧获取 push token → 上报自家服务端 → 服务端经华为推送服务下发。
- token 可能变化(重装/清数据/deleteToken 后):HarmonyOS **无 onNewToken 刷新回调**,
  应每次冷启动(UIAbility onCreate)调 getToken 与本地缓存比对,变化即重新上报;
  只取一次存库是掉推率的主因。
- 收不到推送排查序:AGC 推送服务开通?token 新鲜?通知权限已授?设备
  在线且非省电深度限制?——再查报文。
- 后台到达后的处理受后台管控约束,重逻辑用推送拉起 + 用户点击进入,
  不要幻想静默后台干重活(见 background-tasks)。

## IAP Kit(支付)

- 商品必须先在 AGC 配置(类型:消耗/非消耗/订阅),沙箱测试账号验证全流程。
- **必须实现掉单补偿**:启动/恢复时查询未发货订单并补发货;只在支付回调里
  发货的实现线上必出掉单。
- 服务端验签校验购买凭据,端侧结果只作 UI 参考。

## 定位/地图/扫码速记

- 定位:优先 LocationButton 安全控件免权限(见 security-permissions;首次点击仍有一次
  系统确认,授权为前台临时性);持续定位属长时任务场景。
- 扫码:Scan Kit 默认界面 `scanBarcode.startScanForResult`(一行调用,已预授权相机)与
  自定义界面(customScan)两档,先用默认档。
- 地图:AGC 开通 + 公钥指纹配置后才出图;"地图白屏"基本是指纹/开通问题。

## 版本纪律

各 Kit SDK 独立演进,接口以工程实际依赖版本的声明文件为准;AGC 控制台
界面如与本技能描述不符,以实际界面为准并用 /harmony-feedback 反馈差异。
