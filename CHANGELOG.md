# Changelog

## [0.1.0] - 2026-06-10
适配:HarmonyOS 6.x / API 20-24。首个完整版本。

### Skills(19)
- harmony-core(L0):arkts-syntax(含 ts-to-arkts 参考)、arkui-patterns、
  stage-model、hvigor-build、harmony-debugging(含错误对照表与工程自检脚本)
- harmony-core(L1):atomic-services-and-cards、distributed-collaboration、
  multi-device-adaptation、background-tasks、security-and-permissions、
  arkdata-storage、native-ndk、performance-tuning、api-version-migration
- harmony-cloud(L2):cloud-foundation、huawei-ecosystem-kits
- harmony-release(L3):signing-and-certificates、testing-harmony、
  release-and-compliance

### Claude Code 增强
- Hooks:UserPromptSubmit 强制技能评估;PostToolUse .ets 写后 lint 门禁
- Commands:/harmony-doctor、/harmony-api-scan、/harmony-feedback、
  /harmony-sign-check、/harmony-cloud-deploy

### 自进化工具链
- tools/sdk-diff/diff_api.py:SDK 接口声明机器 diff(已含自测)
- .github/workflows/weekly-sdk-watch.yml:官方页面变更周报
- tools/evals/evals.json:14 条触发率/质量回归样本(含负样本)
- tools/sync-skills.sh:跨工具(Codex/OpenCode 等)一键同步

### 0.1.0 补充(QA 测试维度完善)
- testing-harmony 扩展为 QA 全维度:新增稳定性测试、兼容性与云测、
  功耗专项、内测分发、QA 流程方法论与 QA 全景图
- 新增 references/qa-checklist.md 发布前检查清单
- 新增命令 /harmony-test-plan(定制化测试计划生成)
- 修正网传资料误区:明确 JUnit/@ohos.unittest 不适用于 ArkTS/Stage 工程,
  统一为 Hypium;明确 test/ 与 ohosTest/ 为并列目录
