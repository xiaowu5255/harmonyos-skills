---
name: signing-and-certificates
description: >-
  HarmonyOS 签名证书全链路:密钥(p12)、证书请求(CSR)、调试/发布证书(cer)、
  Profile(p7b)、调试设备 UDID 注册、build-profile.json5 签名配置。凡是遇到
  签名报错、HAP 安装提示 signature/verify 失败、真机无法安装调试、证书过期、
  准备上架打 release 包,或新人搭建鸿蒙调试环境时,务必使用本技能。签名是
  鸿蒙新手放弃率最高的环节,按本清单排查可避免盲目试错。
license: MIT
requires: 0-release-index
metadata:
  target-platform: "HarmonyOS 6.x / API 20-24 + AGC"
---

## Overview

HarmonyOS 签名证书全链路:密钥(p12)、证书请求(CSR)、调试/发布证书(cer)、 Profile(p7b)、调试设备 UDID 注册、build-profile.json5 签名配置。凡是遇到 签名报错、HAP 安装提示 signature/verify 失败、真机无法安装调试、证书过期、 准备上架打 release 包,或新人搭建鸿蒙调试环境时,务必使用本技能。签名是 鸿蒙新手放弃率最高的环节,按本清单排查可避免盲目试错。

## When to Use

- 当用户请求与 signing-and-certificates 相关的开发任务时

# 鸿蒙签名证书全链路

## 心智模型:四件套 + 一个绑定关系

```
p12(密钥库,本地生成,含公私钥)
 └→ csr(证书请求文件,由 p12 生成,上传 AGC)
      └→ cer(数字证书,AGC 用 csr 签发,分调试/发布两种)
           └→ p7b(Profile 文件,绑定:证书 + bundleName + 设备列表(调试) + 权限)
```

最终 `build-profile.json5` 的 signingConfigs 引用:storeFile(p12)、
storePassword/keyAlias/keyPassword、certpath(cer)、profile(p7b)、
signAlg(固定 `SHA256withECDSA`)、type(HarmonyOS/OpenHarmony)。
**签名校验的本质是这条链上每一环的一致性**——排错就是逐环验证一致性。

## 两条路线:先选对路再动手

**路线 A:自动签名(调试期,强烈推荐)**
DevEco 中登录华为开发者账号 → File > Project Structure > Project > Signing Configs →
勾选 Automatically generate signature。IDE 自动完成四件套生成与设备注册。
新手调试一律走这条路;自动签名失败再看下面的手动排查。

**路线 B:手动签名(发布、CI、团队共享证书时必须)**
1. DevEco(或命令行工具)生成 p12 密钥库与 csr。
2. AGC 控制台 → 证书管理:上传 csr,申请证书(类型选调试或发布),下载 cer。
3. 调试场景:AGC → 设备管理,注册调试设备。UDID 获取:
   `hdc shell bm get --udid`(设备需开启开发者模式并连接;旧写法 -udid 已失效)。
4. AGC → Profile 管理:创建 Profile(关联应用 bundleName + 证书 + 调试设备列表
   + 需要的受限权限),下载 p7b。
5. build-profile.json5 配置 signingConfigs,材料路径建议放工程内相对路径
   (绝对路径在换机器/CI 上必坏)。

## 安装失败五步排查清单(按命中率排序)

报错含 signature / verify / install failed 时,顺序执行,命中即停:

1. **设备在不在 Profile 里?**(仅调试包)`hdc shell bm get --udid` 取当前设备
   UDID,核对 AGC 该 Profile 的设备列表。换了测试机忘注册是第一大根因。
   修复:注册设备 → **重新生成并下载 p7b**(旧 p7b 不会自动更新)→ 重签名。
2. **bundleName 三处一致?** AppScope/app.json5 的 bundleName、AGC 应用包名、
   Profile 绑定的包名,三者必须完全一致。
3. **证书类型匹配?** 调试证书 + 调试 Profile 配调试包;发布证书 + 发布 Profile
   配 release 包。混用必失败。发布 Profile 签的包不能直接侧载安装(需上架渠道)。
4. **证书/Profile 过期?** 调试证书有效期 1 年、发布证书 3 年(每账号最多 3 个发布证书);
   调试设备每账号每年最多注册 100 台。AGC 证书管理页查有效期。过期 → 重新申请证书 →
   重新生成 Profile(证书换了 Profile 必须跟着换)。
5. **签名材料路径与密码对不对?** 跑 harmony-debugging 技能的
   check_project_config.sh,它会验证 signingConfigs 引用的文件是否存在;
   密码错误会在构建期(而非安装期)报错,据此区分。

## 受限开放权限注意点

部分敏感权限(如读取已安装应用列表等 ACL 权限)需要在 Profile 申请时声明,
仅 module.json5 声明不够。现象:代码与配置看似正确但权限始终拒绝。
排查:核对 AGC Profile 的受限权限列表是否包含该权限。

## 团队与 CI 实践

- p12 与密码绝不进 git。CI 中通过密钥管理注入,build-profile.json5 的密码字段
  留占位符由 CI 替换。
- 团队共享:发布证书全队唯一(由管理员保管),调试证书可各自生成;
  Profile 设备列表集中维护。
- 证书数量有配额限制,不要无脑新建,优先复用。

## 输出纪律

排查时每一步都让用户提供实际命令输出/截图字段再下结论;签名问题"看起来像"
的猜测命中率极低,一致性核对才可靠。解决后用 /harmony-feedback 回流案例。
