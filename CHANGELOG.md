# Changelog

## [0.7.4] - 2026-06-16

### ROADMAP Phase 5.2 #4/#5/#7/#8 推进（4 项并行交付）

**1. cloud-foundation / huawei-kits 补 kits 字段**
- `cloud-foundation` frontmatter 新增 `kits: ["@hms.cloud.foundation", "@hms.core.agsvc"]`
- `huawei-kits` frontmatter 新增 `kits: ["@hms.account", "@hms.push", "@hms.iap", "@kit.ScanKit"]`
- 解决 v0.2.2 遗留的 kits 字段缺失问题（lint #3 自动检测已对齐）

**2. doctor 命令核心逻辑抽象为独立脚本**
- 新增 `tools/doctor.sh`：4 段式诊断（工程配置 / 工具链可用性 / 设备在线 / SDK 版本）
- 调用 `plugins/.../harmony-debugging/scripts/check_project_config.sh` 复用现有检查
- 输出标准化 PASS/WARN/FAIL 报告 + 退出码（FAIL>0 返回 1 供 CI 拦截）
- `commands/harmony-doctor.md` 改写为薄 wrapper：首选 tools/doctor.sh，缺失时退化

**3. examples/ 已达成 5-8 场景目标（无需新建）**
- 仓库已有 8 个完整示例：navigation-app / cloud-function / media-player / service-card / ble-scanner / background-download / multi-device-layout / photo-picker
- README 表格与 skill 路由表对齐

**4. evals 质量断言扩面（10 skill 目标）**
- 新增 6 条 machine 断言（id 115-120），覆盖 6 个高频但零断言的 skill：
  - accessibility-i18n: `$r('app.string.')` 引用检测
  - sensors-input: sensor.on/off 生命周期检测
  - telephony: makeCall vs dial 权限区分
  - ipc-ime: Parcelable + Want.parameters 检测
  - testing-harmony: Hypium 框架（防误推 Jest/Mocha）
  - camera-capture: CameraPicker 优先（防忽略权限成本）
- 实际达成：质量断言覆盖 9 高优 + 7 常用 = **16 skill**（超出 10 目标）
- evals 114→121 / quality_assertion 50→56（32 machine + 24 semantic）/ 负样本 11 不变

**回归**
- lint 29 PASS / 0 FAIL
- frontmatter 54 skill / 0 CRITICAL / 0 WARNING
- 100% Overview / When to Use 覆盖 + 9/9 高优 skill 纠错标记

## [0.7.3] - 2026-06-16

### Rust 鸿蒙集成（rust-on-harmony skill 上线）

**新 skill：`rust-on-harmony` (harmony-system)**
- 覆盖 Rust→鸿蒙全链路：tier-2 target triple 矩阵、OHOS SDK Clang wrapper、`.cargo/config.toml` 交叉编译配置
- 阐明 `napi-rs` 与官方 OHOS fork `ohos-rs/ohos-rs` 的关系（fork 是主线在 OHOS 的生产用法）
- 4 类 FFI 边界安全模型：生命周期错配 / 线程错配 / 字符串数组拷贝 / Panic 跨界
- 与 `native-ndk` 铁律对齐（线程约束、env 作用域、async work）
- Cargo + hvigor 协同两条路径（CMake add_custom_command / hvigor 自定义 task）
- `## ⚠️ 常见误区与反模式` 6 条（OHOS 不在预编译 std、用上游 napi-rs、Clang target 写法、跨线程调 napi、Rust String FFI、Panic 跨界）

**核实依据（research-first 原则）**
- [rustc OpenHarmony 平台支持](https://doc.rust-lang.org/stable/rustc/platform-support/openharmony.html) — Tier 2 with Host Tools
- [napi-rs triples/target-list](https://github.com/napi-rs/napi-rs/blob/main/triples/target-list) — 3 个 OHOS triple 已纳入
- [ohos-rs 官网](https://ohos.rs) / [Gitee 组织](https://gitee.com/ohos-rs) — 提供 ohos-rs/ohos-rs + ohos-native-bindings

**集成改动**
- `plugins/harmony-system/.claude-plugin/plugin.json` 加 `rust-on-harmony`、version 0.6.2 → 0.7.3
- `plugins/harmony-system/skills/0-system-index/SKILL.md` 路由表新增 1 行（Native NDK + Rust 集成）
- `tools/evals/evals.json` 新增 2 条正样本（id 112 移植算法 / id 113 线程约束）+ 1 条负样本（Rust HTTP 服务器，与鸿蒙无关）
- evals 112→114（注释行）/ quality_assertion 49→50 / 负样本 10→11

**回归**
- lint 29 PASS / 0 FAIL
- frontmatter 54 skill / 0 CRITICAL / 0 WARNING
- 总 skill 数 53→54

## [0.7.2] - 2026-06-16

### 3d-ar 收尾 + 性能臆测软化（Phase 5.2/6.1 闭环）

**3d-ar skill 收尾（v0.6.2 重写后补主动纠错 + eval 增强）**
- 新增 `## ⚠️ 常见误区与反模式` 段：覆盖 6 类典型踩坑（`@kit.AREngineKit` 包名误写、`new Scene()` 同步构造、不存在的 `ARPlaneTracking`、自定义场景模式无相机、glTF/GLB 限制、纯白墙检测失败）
- evals 新增 id 57:针对 `@kit.AREngineKit` 拼写错误的 machine 断言（防回潮）
- 3d-ar 升级为 9 高优 skill 之一（lint 第 13/14 项同步纳入）

**Phase 6.1 性能臆测软化（5 skill 收尾）**
- `ai-inference`：模型分片阈值(>500MB)、HAP 内模型限制(>100MB)、小/大模型边界(~50MB) 三处工程经验值加 "约/实测为准" 对冲
- `ai-vision / ai-speech / ai-nlp / connectivity`：v0.6.2 已完成精度/速度数值删除，本次复检无残余

**工具链与回归**
- `tools/lint-skills.sh` 第 13 项 priority_skills 扩到 9（加 3d-ar=2）
- `tools/lint-skills.sh` 第 14 项扩到 9 高优 skill 纠错覆盖
- evals 111→112 / 49 quality_assertion（25 machine + 24 semantic）/ 10 负样本
- 9/9 高优 skill 纠错覆盖：arkts-syntax/audio-playback/ai-inference/arkui-patterns/network-requests/security-permissions/stage-model/media-system/3d-ar

**回归**
- lint 30 PASS / 0 FAIL（第 13/14 项扩到 9 skill）
- frontmatter 53 skill / 0 CRITICAL / 0 WARNING

## [0.7.1] - 2026-06-16

### 跨平台结构 + 主动纠错模式泛化（基于评估报告再论证的优化）

**结构国际化（Hermes/OpenCode 兼容基础）**
- 53/53 SKILL.md 新增 `## Overview` 段（索引类用领域描述，深度类从 description 自动生成）
- 53/53 SKILL.md 新增 `## When to Use` 段（自动从"涉及...时"提取触发条件 + 回退到 name）
- 工具脚本 `tools/add-overview-when.py`（带 `--dry-run` / `--force` 模式，可复用）

**主动纠错模式推广（ai-speech / crypto-security 的成功模式）**
- 5 个高优 skill 新增 `## ⚠️ 常见误区与反模式` 表（arkts-syntax / stage-model / network-requests / media-system / security-permissions）
- 3 个剩余高优 skill 跟进：audio-playback / ai-inference / arkui-patterns
- **8/8 高优 skill 全部覆盖**反模式段（lint 第 14 项软提示保证不退化）

**provides: index 显式机制文档化**
- ARCHITECTURE.md 新增"索引声明机制（`provides: index`）"专节
- 阐明 8 个索引的 requires 链、显式 vs 隐式推理差异、跨平台迁移价值

**evals 负样本扩充（回归覆盖面）**
- 3 → 10 条负样本（新增 React/iOS/Flutter/通用网络/CI/用户操作/设备对比 7 类）
- comment 同步更新：104→111 条 / 10 负样本 / 48 quality_assertion

**工具链增量**
- `tools/hermes-migrate.py` 利用 `provides: index` 生成 Hermes 路由注册表（8 routers + 45 skills，含 JSON/YAML 双格式输出）
- `tools/validate-frontmatter.py` 新增 `--strict` 模式（WARNING 也阻断返回码 1）
- `tools/lint-skills.sh` 新增第 14 项：8 高优 skill 主动纠错覆盖率软提示
- `.github/workflows/ci.yml` 新增独立 `Validate frontmatter` step（`--strict` 模式）

**README 数字同步**
- 14 项一致性检查 / 111 条回归样本 / 10 条负样本 / 版本号 0.7.0 → 0.7.1
- 顶部 banner 增加"跨平台结构 + 主动纠错模式泛化"标识

**回归**
- lint 28 PASS / 0 FAIL（新增第 14 项）
- frontmatter 53 skill / 0 CRITICAL / 0 WARNING
- evals 111 条 / 10 负样本 / 48 quality_assertion（与 v0.7.0 一致 + 7 新负样本）

## [0.7.0] - 2026-06-15

### 信源质量 + 自进化硬化

**质量断言扩容（16→48）**
- 8 个高优 skill 各补 4 条 quality_assertion（3 machine + 1 semantic），共 +32 条
- 高优名单：arkts-syntax、arkui-patterns、stage-model、security-permissions、network-requests、audio-playback、media-system、ai-inference
- 机器可判定 24 条（v0.6.x 已清杜撰 API/性能臆测的"防回潮"）；semantic 24 条（16 旧字符串 + 8 新 dict）由维护者人工 review
- 涵盖 ROADMAP 5.2（杜撰 API 清除）与 6.1（性能臆测清除）的全部修复记录

**CI 轻量采集成（不阻断）**
- `.github/workflows/ci.yml` 新增 `evals-report` job，依赖 lint、仅 PR 触发
- 默认 `continue-on-error: true`，不阻断合并；产出趋势表 PR 评论 + artifact
- 复用 `ANTHROPIC_API_KEY` secret；claude CLI 缺失降级而非 fail

**自进化主动脉节奏化（文档化，不实跑）**
- ROADMAP Phase 7：季度审计 / feedback-distill / weekly-sdk-watch / CI evals-report 四条主动脉节奏表 + 判定标准
- 首跑留 v0.7.1 / v0.8.0（季度审计 2026-09，feedback-distill 2026-07）

**工具链增量**
- `tools/evals/run_evals.py`（协议层：调 agent / 收 stdout / 应用断言 / 出报告）
- `tools/evals/test_run_evals.py`（8 个单元测试覆盖）
- `tools/lint-skills.sh` 第 13 项：高优 skill evals 覆盖软提示（不阻断）
- `ARCHITECTURE.md` 新增"断言撰写规范"节

**回归**
- lint 13 PASS / 0 FAIL；frontmatter 53 skill / 0 CRITICAL / 0 WARNING
- evals 72→104（机器可判定 24，semantic 24）
- 整体新增 < 800 行（不含 evals 文本与 spec）

## [0.6.2] - 2026-06-15

### 检索时效分层 + 虚构 API 系统性清除（独立审计第三轮）

**检索架构（应对 Context7 时效盲区）**
- 实证 Context7 为季度快照（快照停 ~2026-03，无 6 月发布的 HarmonyOS 7）。ROADMAP 6.0
  三层→**四层**（加官方 SPA 抓取）；检索优先级带**版本判定 + 盲区降级**；本地 d.ts 定为零延迟最终托底。
- `harmony-docs-retriever`：三条铁律→四条，新增盲区降级判断（召回最高 API 低于目标 / Last Updated
  早于发布日 → 跳过 Context7）；检查清单补盲区项。
- `version-guide`：补 HarmonyOS 7 = **API 26** 版本基线（2026-06-12 HDC 发布 Beta，秋季正式版）；
  SemVer 26.0.0 二次检索无佐证，按红线标"待核实"不写成事实。

**虚构 API 清除（逐条 Context7 官方核验，ROADMAP 5.2）**
- `audio-playback`：删杜撰 `createAudioSession`→`getSessionManager()`+`activateAudioSession`；
  `createAudioCapturer` 嵌套结构；`deviceChange` 补 DeviceFlag；MIDI 正本清源为 C-API（API 24, UMP）。
- `ai-inference`：`target:['npu']`+"仅限 Kirin" → NNRt（KIRIN_NPU 官方为保留未支持）；补 context 约束。
- `3d-ar`：**几乎整套 API 为虚构**。`@kit.AREngineKit`→`@kit.AREngine`；`new Scene()`→`Scene.load()`；
  UI 用 `Component3D`；AR 经 `arViewController.ARViewContext`+`arEngine.ARSession`+`ARFrame.hitTest`；
  能力类 `ARPlaneTracking` 等→`ARConfig` 配置属性 + `ARType` 枚举。
- `ai-speech`：Speech Kit 声纹/唤醒**不存在**（实为 TextReader/AICaption），删虚构段；
  ASR `createRecognizer`→`createEngine`+`RecognitionListener`；TTS `speechSynthesis`→`textToSpeech`
  （补官方实锤"单次 speak ≤10000 字符"）；实时转写→长语音模式 `recognizerMode:'long'`。
- `crypto-security`：HUKS `cryptoFramework.createHuks`（不存在）→ `huks.generateKeyItem`+HuksParam，
  加解密三段式 init/update/finishSession；生物认证经核实正确保留。
- `camera-capture`：错误码 `SESSION_NOT_CONFIG`→官方 **7400103**（"Session not config"）。
- `media-system`：Scan Kit 自定义扫码 `CustomScanView`（虚构）→ `customScan.init/start(ViewControl)`；
  `scanType`→`scanTypes` + `scanCore.ScanType`。

**性能臆测清除（ROADMAP 6.1）**
- P1：删 5 个 skill 无信源性能数值（ai-vision/ai-speech/ai-nlp/ai-inference/connectivity 的精度%、
  速度倍数、固定 ms/MB），改定性"实测为准"。
- P2：软化工程经验值（media-processing 码率、2d-graphics 帧率档、location-map 节流、file-system 分块阈值）。
- 贯穿红线新增第 3 条：**禁止无信源性能数值入库**。

**回归**：lint 12 PASS / 0 FAIL；frontmatter 53 skill / 0 CRITICAL / 0 WARNING；尺寸全达标。

## [0.6.1] - 2026-06-15

### Context7 官方库核验修复（独立审计第二轮）
- **接入 Context7 官方文档库**：确认 Context7 已结构化收录 developer.huawei.com 全量文档
  （guides 56k + references 78k + v13 + faqs + AGC ≈ 20 万 snippet，均 High 声誉一手源）。
- **harmony-docs-retriever 增强**：检索工作流新增「步骤 2 — Context7 官方库检索」作为一级源
  （优先于通用搜索），给出 5 个库 ID 映射表 + 三条铁律（快照非实时／版本消歧／本地 d.ts 优先级最高）；
  步骤编号重排（1→6），检查清单补 Context7 项。从根上替换"SPA 抓不到→凭记忆编造"链路中的不稳定 web-fetch 层。
- **P1 修复 `audio-playback`（整段逐 API 对照官方核验，问题最重）**：
  - 删除杜撰 API `audio.createAudioSession`，改 `audioManager.getSessionManager()`→`activateAudioSession(strategy)`（API 12+），枚举装 `concurrencyMode` 字段
  - `createAudioCapturer` options 平铺→嵌套 `{streamInfo, capturerInfo}`
  - `audioManager.on('deviceChange')`（API 9 废弃）→ `routingManager.on('deviceChange', DeviceFlag, cb)`
  - MIDI 杜撰 ArkTS `midi.createMIDIDevice()` → 纠正为纯 C-API（`native_midi.h`，API 24 起，UMP 格式）
  - 删除编造的 MIDI 延迟数值
- **P1 修复 `ai-inference`**：
  - `target:['npu']`+"仅限 Kirin" → `target:['nnrt']`（官方 `OH_AI_DeviceType` 中 KIRIN_NPU 标注"保留，尚未支持"，实际通道是 NNRt）
  - 删除编造 fps（5-15/30-60）与加载秒数；补 context 单次 build 约束、`context.cpu` 结构、精度模式层级
  - 消除 4 个 H1 的 lint WARN（bash 注释 `#`→`##`）
- **回归**：lint 12 PASS / 0 FAIL；frontmatter 53 skill / 0 CRITICAL / 0 WARNING（原 1 WARN 清零）；尺寸全达标。

## [0.6.0] - 2026-06-13

### 全量深度审计与质量修复（v3.0）
- **全量审计**：对 45 个深度 skill 进行逐条 API 正确性审查（7 个并行 agent，跨 8 个领域）
- **P0 修复（4 项）**：
  - `media-system`：删除杜撰 API `castAudio`，修正 `createAVSession` 签名
  - `ipc-ime`：删除杜撰概念 `LocalRPC`，替换为 EventHub/emitter
  - `crash-diagnostics`：删除杜撰事件名 `BUSSINESS_THREAD_BLOCK`/`SYS_FREEZE`
  - `arkts-syntax`：修正未核实 API 版本声明示例
- **P1 修复（6 项）**：
  - `2d-graphics`：修正 `markContentDirty`→`invalidate()`、`getSnapshot()`→`componentSnapshot`、URL 路径
  - `audio-playback`：修正 `AudioSessionStrategy`→`AudioConcurrencyMode` 枚举名/值
  - `arkui-window`：修正 "Activity"→"UIAbility" 术语
  - `hvigor-build`/`release-and-compliance`：DevEco 版本号改为通用表述
- **审计报告更新**：AUDIT_REPORT v3.0，含 12 条修复记录与 P0/P1/P2 待处理清单
- **已确认正确**：`multi-device-adaptation` API 23 平行视界声明、`background-tasks` API 21+ 长时任务限制
- **待重写**：`3d-ar`（20+ 虚构 API）、`ai-speech`（voiceprint 虚构模块）

## [0.5.0] - 2026-06-12

### 借鉴 HarmonyOS_Skills 官方仓库（agent-rules / agent-skills）的工程模式落地
- **harmony-docs-retriever**（新 skill，harmony-platform）：官方文档检索层。稳态路径=本地锚点表
  + `site:` 限定搜索 + web-fetch 取证 + 版本消歧；明确禁止直连 `/doc/search?`（robots 禁止且无公开 JSON）。
  含 `references/doc-anchors.md`（已核实 URL 种子表）、`scripts/check-doc-urls.sh`（200 巡检）、test-cases。
- **crash-diagnostics**（新 skill，harmony-release）：故障日志分型诊断。按 CppCrash/JsCrash/AppFreeze/
  内存泄漏分型路由到 `references/` 各型详解（符号化、主线程栈、两次堆快照 diff 等方法论）。
- **ArkTS 编译器级校验闭环**：`ets-lint-gate.sh` 升级支持 OpenHarmony 官方 `linter-cli`；新增
  `arkts-syntax/scripts/arkts-lint.sh` + `references/arkts-linter-setup.md`（来自 agent-rules）。
- **内容质量审查**：新增 `tools/validate-frontmatter.py`（name 字符集/description what+when/长度），
  并入 `lint-skills.sh` 第 11 项（CRITICAL 拦截，风格降级 WARN）；第 12 项软提示 test-cases 覆盖。
- **ts-to-arkts.md 扩充**：借 agent-rules 的 `ArkTS_Rules.md` 补 JSON 边界范式、动态数组窄化、硬禁清单。
- **约定文档化**：ARCHITECTURE 新增「检索层/开发层分离」「Master 大路由」「test-cases 约定」三节。
- evals 68→72 条；版本号全量同步至 0.5.0（marketplace + 8 plugin.json + README）。

## [0.4.1] - 2026-06-12

### 官方文档核验修正（对照 developer.huawei.com 全量核验 19 个深度 skill）
- **新增 VERIFICATION.md**：沉淀全部核验结论（结论→信源级别→日期→落地状态），配合「贯穿红线 #2」。
- **修正照抄即失败的硬错**：`hdc shell bm get -udid` → `--udid`（5 处）；"release 默认开启混淆"
  → DevEco 5.0.3.600 起默认关闭。
- **修正编造/失实**：删除 `arkts-strict-property-initialization`（编造规则名）与 distributed
  "API 23+ 自定义组件跨 Ability 迁移"（疑似杜撰）；解构"部分受限"→错误级禁止（含真实规则名）。
- **修正过时**：@Styles/@Extend → AttributeModifier；@CustomDialog → openCustomDialog；
  列表三件套 → 四件套（freezeWhenInactive）；SDK 路径 `sdk/<版本>` → `sdk/default`（openharmony+hms）；
  Push token 监听刷新 → 冷启动 getToken 比对；证书指纹 → 公钥指纹；taskpool/Worker 补 @Sendable。
- **补全**：状态管理 V2 补 @Once/@Monitor/@Computed/makeObserved 与 API 19+ 混用；version-guide
  补 compileSdkVersion；stage-model 补 onNewWant/拉起其他应用(openLink/startAbilityByType)；
  background-tasks 修正多长时任务并行规则（API21+ 10个）；断点补官方阈值；签名补 signAlg/有效期数值。
- **一致性**：清除重构后 8 处旧 skill 名交叉引用（huawei-ecosystem-kits/security-and-permissions/
  distributed-collaboration/arkdata-storage/api-version-migration）。
- **规约修订**：ROADMAP 转正流程中 references/ 改为按需补充，避免与「未核实 API 不入库」冲突。

## [0.4.0] - 2026-06-12

### Phase 3 覆盖率扩展完成（45%→50% Kit 覆盖）
- **accessibility-i18n**（新 skill，P1）：上架合规双支柱——Accessibility Kit 三要素 + Localization Kit 格式化/RTL/自检
- **sensors-input**（新 skill，P2）：Sensor Kit(加速度/陀螺仪/光线/距离/振动/心率) + Input Kit(键鼠/手柄) + Pen Kit(手写笔/一笔成形)
- **telephony**（新 skill，P2）：拨打电话(拨号盘/应用内)、短信收发/验证码填充、网络状态、SIM 管理
- **ipc-ime**（新 skill，P2）：IPC RPC三步法(Stub/Proxy/远端订阅) + IME Kit(输入法开发/自绘编辑器集成)；Localization 已并入 accessibility-i18n
- **assets/**：build-profile-sample.json5 多模块模板；卡片样板基础结构
- evals 59→68 条（新增 9 条覆盖 4 个新 skill）
- 索引路由表：0-core-index +2、0-system-index +2
- README/100+→50 skill / 版本号 0.4.0
- ROADMAP Phase 3 全部完成

## [0.3.0] - 2026-06-12

### 九个 P2 占位 Skill 转正（ROADMAP Phase 2 完成）
- **camera-capture**：从占位重写为 600+ 词深层次 skill——会话五步法、CameraPicker vs Camera Kit 决策树、输入输出流选型、生命周期四状态硬约束、折叠屏适配、8 大进阶场景速查、5 条排查清单
- **media-processing**：三 Kit 边界速判(AVCodec/Image/Media)、同步 vs 异步编码模型、编码参数七件套、Image Kit Source→Decoder→Packer 流水线、Demuxer/Muxer 容器操作、5 条排查清单
- **media-system**：AVSession 心智模型、本地 vs 分布式会话选型、播控自检清单 6 项、DRM Kit 三流程、Scan Kit 正确打开方式、分布式流转五步排查
- **ai-vision**：双 Kit 分工(Core Vision 基础层+Vision 场景层)、五大能力(Face/OCR/Object/Barcode/Segmentation)、性能调优六条、5 条排查清单；Kit 名已按官方文档核实为 Core Vision Kit / Vision Kit
- **ai-speech**：双 Kit 分工(Core Speech+Speech)、ASR 在线/离线选型表、TTS 流式合成+离线合成、实时转写、语音唤醒+声纹验证、权限清单、5 条排查清单；Kit 名已按官方文档核实为 Core Speech Kit / Speech Kit
- **ai-nlp**：四大能力矩阵(分词/实体抽取/词性标注/文本向量化)、10 种实体类型速查、余弦相似度检索实现、端侧 NLP+云侧大模型混合策略、5 条排查清单
- **ai-inference**：推理流水线五步法、CPU vs NPU 选型表、张量处理、模型转换三板斧(ONNX→MS+量化+NPU适配)、性能优化五条、5 条排查清单
- **2d-graphics**：三条渲染路径(Canvas/RenderNode/DisplaySync)、选型原则、V-Sync 级帧率控制、离屏渲染与截图、5 条排查清单
- **3d-ar**：两 Kit 定位(ArkGraphics 3D+AR Engine)、SLAM 核心概念、AR Engine 六大能力、AR 应用骨架代码、5 条排查清单
- **evals**：38→56 条(new 18 条覆盖所有 9 个转正 skill，每个 2 条)
- **文档引用**：所有文档链接均为已验证的官方 Kit 入口页（developer.huawei.com），无臆造 slug

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
