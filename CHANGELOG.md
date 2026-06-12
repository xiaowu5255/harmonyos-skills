# Changelog

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
