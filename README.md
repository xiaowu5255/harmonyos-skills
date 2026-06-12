# harmonyos-skills

HarmonyOS 6(API 20–24)开发专家技能集。让你的 AI 编码 agent 熟练掌握 ArkTS 语法、ArkUI、构建调试、系统特性(元服务/分布式/一多/后台/权限)、端云一体化与签名发布全流程。

技能本体遵循 **Agent Skills 开放标准**(SKILL.md),可在 Claude Code、Codex、OpenCode 等所有兼容工具中使用;Claude Code 用户额外获得插件层增强(强制触发 hook、写后 lint 门禁、斜杠命令)。

当前版本:**0.1.0** —— 3 个 plugin / 19 个 skill / 5 个命令 / 2 个 hook / 自进化工具链。

## 技能矩阵

**harmony-core(14 个,所有鸿蒙开发者必装)**

| 层 | Skill | 解决什么 |
|---|---|---|
| L0 语言 | arkts-syntax | ArkTS≠TS 硬约束、状态管理 V1/V2、TS 迁移(含 references) |
| L0 UI | arkui-patterns | 布局选型、Navigation、列表性能三件套、动画 |
| L0 架构 | stage-model | UIAbility 生命周期、Want、module.json5、Context |
| L0 构建 | hvigor-build | HAP/HAR/HSP 选型、多模块、release 混淆暗坑 |
| L0 调试 | harmony-debugging | 六层定位法、hdc/hilog、错误对照表、自检脚本 |
| L1 | atomic-services-and-cards | 元服务约束、卡片生命周期与三条刷新通路 |
| L1 | distributed-collaboration | 流转/接续、分布式前置五条清单 |
| L1 | multi-device-adaptation | 断点响应式、折叠屏/PC 形态、一多工程组织 |
| L1 | background-tasks | 后台任务类型选型表("后台默认死"原则) |
| L1 | security-and-permissions | Picker/安全控件优先决策树、ACL、申请链路 |
| L1 | arkdata-storage | 存储选型、RDB 迁移、数据类 bug 排查 |
| L1 | native-ndk | N-API 线程约束、CMake、C++ 库移植 |
| L1 | performance-tuning | Profiler 工作流、冷启动/丢帧/内存 |
| L1 | api-version-migration | 版本语义、canIUse、升级流程清单 |

**harmony-cloud(2 个,做端云/生态接入装)**:cloud-foundation(端云一体化全链路)、huawei-ecosystem-kits(账号/推送/支付/地图/扫码通用接入方法论)

**harmony-release(3 个,负责测试与上架装)**:signing-and-certificates(签名四件套+五步排查)、testing-harmony(QA 全维度:Hypium/UI 自动化/稳定性/云测兼容性/内测,含发布前检查清单)、release-and-compliance(上架与隐私合规驳回整改)

设计原则:技能教**方法与不变量**(先读 build-profile.json5 定版本、先查本地 SDK 声明、先验前置清单、分层定位),不堆易过期的 API 事实——这是对抗鸿蒙季度级迭代的核心手段。

## 安装

### Claude Code(完整体验)

```
/plugin marketplace add <你的GitHub用户名>/harmonyos-skills
/plugin install harmony-core@harmonyos-skills
/plugin install harmony-cloud@harmonyos-skills      # 按需
/plugin install harmony-release@harmonyos-skills    # 按需
```

本地调试:`claude --plugin-dir ./plugins/harmony-core`

### Codex / OpenCode / 其他兼容工具

```bash
git clone https://github.com/<你的用户名>/harmonyos-skills && cd harmonyos-skills
./tools/sync-skills.sh           # 复制全部 19 个 skill 到 ~/.agents/skills
# 或 --link 软链接模式:git pull 即全工具更新
```

OpenCode 自动发现零配置;Codex 同步后重启,可在 `~/.codex/config.toml` 按路径启停单个 skill;其他兼容工具把技能目录放入其 skills 路径即可。hooks 与 commands 为 Claude Code 专属增强,其他工具自动忽略。

## 命令(Claude Code)

| 命令 | 作用 |
|---|---|
| /harmony-doctor | 环境与工程健康一键诊断 |
| /harmony-api-scan | 扫描高于 compatibleSdkVersion 的 API 调用 |
| /harmony-sign-check | 签名全链路一致性排查 |
|  /harmony-cloud-deploy 、/harmony-test-plan | 端云工程部署前检查 |
| /harmony-feedback | 把本次解决的问题蒸馏回流知识库 |

## 自进化机制

- **知识回流**:`/harmony-feedback` 把真实踩坑蒸馏成错误对照表条目(条目规范见 common-errors.md 末尾)。
- **SDK diff**:`python3 tools/sdk-diff/diff_api.py <旧SDK/ets/api> <新SDK/ets/api>` 机器生成新增/移除/废弃 API 清单,直接作为技能 reference 数据(已含自测样例)。
- **变更监测**:`.github/workflows/weekly-sdk-watch.yml` 每周监测官方页面变化并自动开 issue(URL 需按实际有效页面替换)。
- **防退化**:`tools/evals/evals.json` 14 条回归样本(含负样本),每次修改技能后过一遍。

## 发布前待办

- [ ] 替换 marketplace.json / plugin.json 中的 `YOUR_NAME` 占位
- [ ] 对照 Claude Code 当前官方文档核验 hooks.json / marketplace.json 字段格式(插件机制仍在演进)
- [ ] weekly-sdk-watch.yml 中的监测 URL 替换为你验证过的页面
- [ ] 用 evals.json 实测触发率;错误对照表种子条目在真实环境复核

## License

MIT
