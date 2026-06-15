---
name: crypto-security
description: >-
  鸿蒙加解密与安全认证: Crypto Architecture Kit(加解密/签名/摘要/MAC/密钥派生)、
  Universal Keystore Kit(密钥存储)、User Authentication Kit(生物认证)。
  涉及数据加密、安全存储、指纹/人脸登录时使用本技能。
license: MIT
requires: 0-system-index
kits: ["@kit.CryptoArchitectureKit", "@kit.UniversalKeystoreKit", "@kit.UserAuthenticationKit"]
metadata:
  target-platform: "HarmonyOS 6.x / API 20-24"
---

## Overview

鸿蒙加解密与安全认证: Crypto Architecture Kit(加解密/签名/摘要/MAC/密钥派生)、 Universal Keystore Kit(密钥存储)、User Authentication Kit(生物认证)。

## When to Use

- 涉及 数据加密 时
- 涉及 安全存储 时
- 涉及 指纹 时
- 涉及 人脸登录 时

# 加解密与安全认证

## 算法选型(先选对算法)

| 需求 | 推荐算法 | 禁止/慎用 |
|------|---------|----------|
| 对称加密(数据机密性) | AES-256-GCM / SM4-GCM | AES-ECB(无法抵抗模式分析);DES/3DES(已淘汰) |
| 非对称加密 | RSA-2048+ / SM2 | RSA-1024(已被破解可行) |
| 消息摘要(数据完整性校验) | SHA-256+ / SM3 | MD5、SHA-1(碰撞攻击可行) |
| 消息认证码(来源验证) | HMAC-SHA256 / HMAC-SM3 | 裸 Hash 做 MAC(length extension attack) |
| 密钥派生(密码→密钥) | PBKDF2 / HKDF | 裸 Hash 做 KDF(弱抗暴力) |
| 密钥协商 | ECDH / SM2 Key Exchange | 自造密钥交换协议 |
| **密码存储(登录口令)** | **bcrypt / argon2(通过 Native 引入)** | **SHA256(password) 是严重错误——彩虹表秒破** |

> **误区纠正**：MD5/SHA256 用于安全场景(密码哈希、数字签名)是禁止的。
> 它们仅可用于非安全场景(如文件去重、非加密校验和)。

## 国密算法体系

鸿蒙深度集成国密标准，政务/金融等合规场景强制使用：

| 国密算法 | 对应国际算法 | 用途 |
|---------|------------|------|
| SM2 | ECC(ECDH/ECDSA) | 非对称加密/签名/密钥协商 |
| SM3 | SHA-256 | 消息摘要 |
| SM4 | AES-128 | 对称加密 |

## 密钥安全存储(HUKS)

**密钥绝不能硬编码在代码中**——字符串常量可被反编译提取。用 HUKS
(Universal Keystore Kit)管理密钥。官方模块是 `huks`(**不是** `cryptoFramework.createHuks`,
那个写法不存在);生成密钥用 `generateKeyItem`,参数是 `HuksOptions`(`properties: HuksParam[]`):

```ts
import { huks } from '@kit.UniversalKeystoreKit';

const keyAlias = 'my_aes_key';
const options: huks.HuksOptions = {
  properties: [
    { tag: huks.HuksTag.HUKS_TAG_ALGORITHM, value: huks.HuksKeyAlg.HUKS_ALG_AES },
    { tag: huks.HuksTag.HUKS_TAG_KEY_SIZE,  value: huks.HuksKeySize.HUKS_AES_KEY_SIZE_256 },
    { tag: huks.HuksTag.HUKS_TAG_PURPOSE,
      value: huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_ENCRYPT | huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_DECRYPT },
    // 还需 PADDING / BLOCK_MODE 等,具体 tag 以本地 d.ts 为准
  ],
};
await huks.generateKeyItem(keyAlias, options); // 密钥生成即入 TEE,不返回明文
```

加解密是**三段式会话**:`initSession`(拿 handle)→ `updateSession`(分段喂数据)
→ `finishSession`(收尾)。密钥永远存在于安全硬件(TEE/SE)内,应用按 keyAlias 引用,
拿不到密钥明文。**keyAlias 是应用内唯一标识,丢失即永久丢失密钥**。

## 生物认证集成

```ts
const userAuth = userIAM_userAuth.getUserAuthInstance(authParam, widgetParam);
userAuth.start();
userAuth.on('result', (result) => {
  if (result.result == userIAM_userAuth.UserAuthResultCode.SUCCESS) { /* 通过 */ }
});
```

- 支持指纹(1-6 级)、人脸(2D/3D)、虹膜，具体能力取决于设备硬件
- 认证后获取的 `AuthToken` 有有效期(默认 5 分钟),过期需重新认证
- **生物特征数据永不出 TEE**——应用只拿到认证通过/不通过的结论

## 跨平台数据兼容

与 Android/iOS 加解密互通时的常见坑：
- AES-GCM 的 IV 长度：鸿蒙默认 12 字节，确认其他平台一致
- 填充模式：AES 选 `PKCS7`,与 Android/iOS 的 kCCOptionPKCS7Padding 对应
- 编码：密文跨端传递统一用 Base64,不要传原始二进制

## 安全清单

1. 密钥不硬编码——走 HUKS
2. 敏感数据(密码/Token)不落明文盘——加密后再存到 Preferences/RDB
3. 网络传输用 HTTPS + Certificate Pinning(见 network-requests)
4. MD5/SHA1 只能用在非安全场景——文件去重、非加密校验和
5. 随机数用 `cryptoFramework.createRandom()`——不要用 `Math.random()`
6. 密码哈希用 bcrypt/argon2——SHA256(password) 不等于"加密了密码"

## 排查清单：“加解密报错/认证失败”

1. IV 长度不匹配(AES-GCM 12 vs 16 字节交叉使用是高频错误)。
2. KeyStore 中 keyAlias 写错——HUKS 按 alias 查找，找不到就报错。
3. 生物认证——用户是否在系统设置中录入了生物特征？
4. SM4 加密结果跨端无法解密——确认 CBC/GCM 模式、IV、填充方式一致。
