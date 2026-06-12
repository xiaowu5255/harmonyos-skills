# Changelog

## [0.2.0] - 2026-06-12

### 架构重构：三层渐进式
- 从 3 个扁平 plugin 重构为 **8 plugin / 47 skill** 的三层渐进架构
- 第一层：`harmony-platform` — 总索引 `harmony-index` + 版本迁移
- 第二层：7 个领域插件，各含 `0-{domain}-index` 领域索引
- 第三层：39 个深度 skill，通过 `requires` 字段链接到领域索引

### 新增 Skill（11 个）
- **应用框架**: arkts-concurrency(TaskPool/Worker)、arkui-window(窗口管理)、arkweb(Web容器)
- **系统**: network-requests(HTTP/WS/Socket)、crypto-security(加解密/生物认证)、file-system(沙箱文件)、connectivity(蓝牙/WiFi/星闪)
- **生态服务**: notification(通知)、location-map(定位地图)、sharing-social(分享/DeepLink)
- **媒体**: audio-playback(音频播放/录制/MIDI)

### P2 占位 Skill（9 个）
- 媒体: camera-capture、media-processing、media-system
- 图形: 2d-graphics、3d-ar
- AI: ai-vision、ai-speech、ai-nlp、ai-inference

### 新增文档
- AUDIT_REPORT.md: 基于官方文档一手数据的覆盖率审计
- ARCHITECTURE.md: 三层渐进式架构设计文档

### 已有 skill 迁移
- harmony-cloud 并入 harmony-ecosystem
- 系统级 skill(后台/存储/分布式/权限/Native)迁移到 harmony-system
- 性能优化迁入 harmony-release
- API迁移功能迁入 harmony-platform/version-guide
- 所有已有 skill 添加 `requires` 索引引用

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
