---
description: 鸿蒙开发环境与工程健康一键诊断
---

对当前鸿蒙工程做完整健康检查,按以下步骤执行:

1. **首选**:`bash tools/doctor.sh [工程根目录]` —— 自动化执行工程配置检查、
   工具链检测、设备在线状态、SDK 版本核对,输出标准化诊断报告。
   若当前目录无 build-profile.json5,先向上/向下寻找工程根。
2. **若 `tools/doctor.sh` 缺失**:退化为执行
   `plugins/harmony-core/skills/harmony-debugging/scripts/check_project_config.sh`
   并手工核对工具链。
3. 读取 doctor 输出,对 FAIL/WARN 项给出具体修复步骤
   (引用 harmony-debugging 技能的分层方法论)。
4. 报告末尾按严重程度排序列出待办。

只读诊断,未经用户确认不要修改任何文件。