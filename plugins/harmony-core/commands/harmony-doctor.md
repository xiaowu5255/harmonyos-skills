---
description: 鸿蒙开发环境与工程健康一键诊断
---

对当前鸿蒙工程做完整健康检查,按以下步骤执行:

1. 运行本插件 harmony-debugging 技能目录下的 `scripts/check_project_config.sh`,
   传入工程根目录(若当前目录无 build-profile.json5,先向上/向下寻找工程根)。
2. 检查工具链:`hdc version`、`ohpm -v`、`node -v` 是否可用;`hdc list targets`
   是否有设备/模拟器在线。
3. 读取 build-profile.json5,报告 compatibleSdkVersion / targetSdkVersion,
   并与本地已安装 SDK 版本对比,指出不匹配。
4. 汇总输出一份诊断报告:正常项一句话带过,异常项给出具体修复步骤(引用
   harmony-debugging 技能的分层方法论)。报告末尾按严重程度排序列出待办。

只读诊断,未经用户确认不要修改任何文件。
