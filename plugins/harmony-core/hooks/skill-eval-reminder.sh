#!/usr/bin/env bash
# UserPromptSubmit hook:检测鸿蒙相关关键词,提醒模型先评估对应 skill。
# 社区实测此类 forced-eval 机制可将 skill 激活率从 ~20% 提升到 ~80%+。
# stdin 为 JSON,stdout 会作为附加上下文注入。
INPUT=$(cat)
PROMPT=$(echo "$INPUT" | tr '[:upper:]' '[:lower:]')

KEYWORDS='\.ets|arkts|arkui|hvigor|module\.json5|build-profile|oh-package|ohpm|hdc|hilog|deveco|harmonyos|鸿蒙|元服务|agconnect|端云|签名|p7b|hap安装|@state|@componentv?2?'

if echo "$PROMPT" | grep -qiE "$KEYWORDS"; then
  cat << 'CTX'
[harmony-core hook] 本条消息涉及 HarmonyOS 开发。回答前先评估并加载相关技能:
ArkTS/ArkUI 代码 → arkts-syntax;构建/安装/运行报错 → harmony-debugging;
签名证书问题 → signing-and-certificates;云函数/云数据库/AGC → cloud-foundation。
鸿蒙 API 迭代极快,务必先读项目 build-profile.json5 确认 API 版本,不确定的 API 先查本地 SDK 声明文件。
CTX
fi
exit 0
