---
description: 签名配置全链路一键排查
---

对当前工程执行签名全链路检查,按 signing-and-certificates 技能执行:

1. 运行 harmony-debugging 技能的 scripts/check_project_config.sh,提取
   signingConfigs 部分结果(材料文件存在性)。
2. 核对一致性链:AppScope/app.json5 的 bundleName ↔ build-profile.json5
   signingConfigs ↔ 用户提供的 AGC Profile 信息(引导用户从 AGC 页面
   读出 Profile 绑定的包名/证书/设备列表)。
3. 若用户报安装失败:引导执行 `hdc shell bm get --udid` 并核对 Profile
   设备列表;区分调试/发布证书类型匹配。
4. 输出五步排查清单(技能正文)的逐项结论与下一步动作。
   涉及密码与 p12 内容时不要求用户粘贴明文,只确认"能否本地验证通过"。
