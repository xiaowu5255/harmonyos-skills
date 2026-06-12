# Changelog

## [0.2.2] - 2026-06-12

### 一致性基建与质量加固（评估报告 Phase 0/1/2 落地）
- **版本与元数据统一**：marketplace.json owner 占位符替换、8 个 plugin.json 版本统一 0.2.2、
  修复 harmony-core/plugin.json 中 `harmonic-debugging` 拼写错误、
  修复 security-permissions 的 frontmatter name 旧名残留
- **lint 升级为 10 项检查**（tools/lint-skills.sh）：新增 plugin.json 清单↔目录双向一致、
  SKILL.md 引用路径存在性、索引路由表目标存在性、JSON 严格解析、尺寸约束;修复 evals 检查恒过缺陷
- **新增 CI**（.github/workflows/ci.yml）：push/PR 自动运行 lint
- **evals 扩充 22→38 条**：补齐 13 个深度 skill、占位域路由与 Android 负样本
- **占位 skill 文档链接全量核实**：52 个官方文档 URL 经实测 49 个失效（404/臆造 slug），
  全部替换为从官方文档中心目录页提取并逐一验证的 Kit 级入口（25 个，0 失效）;
  清除正文中未经核实的 API 类名（保留 SpeechRecognizer/AVPlayer/PixelMap 等已确认项），
  并修正 TTS 能力归属（属 Core Speech Kit 而非 Speech Kit）
- **ARCHITECTURE.md**：共享数据改为 skill 内 references/（可移植性）、修正模板中非法 YAML 示例、
  新增"目录规约"与"发布 Checklist"两节
- **sync-skills.sh**：同步目录名加 harmony- 前缀，避免与其他技能集冲突

## [0.2.1] - 2026-06-12

### 评估报告反馈修复（P0 阻断级）
- marketplace.json 重写为 8-plugin 清单（修复 README 安装命令全部不可用的问题）
- 20 个新 skill 的 kits 字段加引号（`@` 为 YAML 保留字符，裸值导致 frontmatter 解析失败）
- evals.json 同步旧 skill 名、README 命令计数修正、迁移 skill 的 name 与目录统一
- 9 个占位 skill 清除虚构 API 速查表
- ARCHITECTURE.md 修正"全量加载 38KB"的不成立论证基准

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
