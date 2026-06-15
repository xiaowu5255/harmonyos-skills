---
name: security-permissions
description: >-
  鸿蒙权限与安全体系:权限分级与 ACL、动态申请流程、Picker 与安全控件免权限
  方案、应用沙箱、数据加密。凡是涉及申请任何权限、访问相册/文件/位置/剪贴板/
  联系人、权限弹窗与被拒处理、上架前权限合规整改时,务必使用本技能。鸿蒙的
  设计哲学是"能不要权限就不要权限"——先想免权限方案,再谈申请,这也是过审的关键。
license: MIT
requires: 0-system-index
metadata:
  target-platform: "HarmonyOS 6.x / API 20-24"
---

## Overview

鸿蒙权限与安全体系:权限分级与 ACL、动态申请流程、Picker 与安全控件免权限 方案、应用沙箱、数据加密。鸿蒙的 设计哲学是"能不要权限就不要权限"——先想免权限方案,再谈申请,这也是过审的关键。

## When to Use

- 涉及 申请任何权限 时
- 涉及 访问相册 时
- 涉及 文件 时
- 涉及 位置 时
- 涉及 剪贴板 时
- 涉及 联系人 时
- 涉及 权限弹窗 时
- 涉及 被拒处理 时

## ⚠️ 常见误区与反模式

| 误区 | 正确做法 | 来源 |
|------|---------|------|
| `access_token` 直接传字符串 | 用 `abilityAccessCtrl.createAtManager()` 获取 `AtManager` 实例 | 权限 API 文档 |
| 权限名用 `ohos.permission.CAMERA` 就够 | 部分权限需要在 `module.json5` 声明 + 运行时申请;两步缺一不可 | 权限申请链路 |
| 用户拒绝后反复弹窗 | 检查 `canIUse`;永久拒绝后引导用户到设置页;不要死循环弹窗 | UX 最佳实践 |
| `ohos.permission.READ_MEDIA` 读相册 | API 12+ 用 `PhotoViewPicker` 替代直接读取;不需要 READ_MEDIA 权限 | 沙箱与数据安全 |
| `ohos.permission.DISTRIBUTED_DATASYNK` 直接用 | 需要先在 AGC 控制台开通分布式能力;本地声明权限不等于可用 | 分布式文档 |

> **验证方法**:权限名以 `@ohos.abilityAccessCtrl` 声明文件为准。
> 用 `grep -r "ohos.permission" oh_modules/` 检查实际可用权限列表。

# 权限与安全

## 决策树:遇到"需要权限"先走这三步

1. **有没有 Picker?** 选照片 → PhotoViewPicker;选文件 → DocumentViewPicker;
   选联系人 → contacts Picker……Picker 由系统进程代为访问,**零权限**、零弹窗、
   零审核说明。能用 Picker 的场景申请权限属于设计错误。
2. **有没有安全控件?** 保存到相册 → SaveButton;获取位置 → LocationButton;
   读剪贴板 → PasteButton。用户点击控件即一次性授权,无需常驻权限。
3. **都没有,才申请权限**,并走完整合规链路(下文)。

## 权限申请完整链路(漏一步就是一个 bug)

1. module.json5 `requestPermissions` 声明,**附 reason(用途说明资源)与
   usedScene**——上架审核要查。
2. 区分授权方式:system_grant(声明即得)/ user_grant(必须动态弹窗)。
3. user_grant 权限:调用前先查询授权状态 → 未授权则
   `requestPermissionsFromUser` → **处理拒绝分支**(降级体验或引导到设置,
   不许死循环弹窗)。
4. 受限权限(ACL):普通应用默认不可用的高敏权限,需在签名 Profile 中申请
   (见 signing-and-certificates),仅 module.json5 声明会在运行时静默失败
   ——"配置看着全对但权限永远拒绝"十有八九是这个。

## 高频权限对照

| 场景 | 正确方案 |
|---|---|
| 读用户选的图片/视频 | PhotoViewPicker(免权限) |
| 写图片到相册 | SaveButton 或申请相应媒体权限 |
| 模糊/精确位置 | LocationButton 或 APPROXIMATELY/LOCATION 权限组合(精确依赖模糊) |
| 网络 | ohos.permission.INTERNET(system_grant,但仍须声明) |
| 后台常驻 | KEEP_BACKGROUND_RUNNING(转 background-tasks) |

## 沙箱与数据安全

- 应用数据一律放沙箱路径(context.filesDir 等),不要假设可访问任意全局路径;
  跨应用共享走 Picker/分享/UDMF,不走"公共目录"思维。
- 敏感数据落盘:Preferences/RDB 的加密选项 + 数据分级(securityLevel)按
  数据敏感度设置(见 data-storage);密钥用系统密钥管理,不要硬编码。

## 排查:"权限明明给了还是不行"

按概率:ACL 权限未进 Profile > 动态申请时机早于 UI 可交互 > 查询的权限名
与声明的不一致(复制粘贴错字符串)> 设备设置里被用户手动关闭。
