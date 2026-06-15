# harmonyos-skills 渐进式架构设计

> **背景**：官方文档 ~142 个 Kit/专题，当前 8 plugin / 53 skill 三层渐进式架构，Kit 覆盖率 ~50%  
> **目标**：让 AI agent 按需加载知识，避免 context 爆炸，同时保持全栈覆盖

---

## 一、核心问题（已解决）

### 重构前

```
harmony-core/  (14 skills — 已过重)
  ├── arkts-syntax/
  ├── arkui-patterns/
  ├── stage-model/
  ├── ... (10 more)
harmony-cloud/  (2 skills)
harmony-release/ (3 skills)
```

**痛点**：
- `harmony-core` 塞了 14 个 skill，但触发的粒度是"写 ArkUI 代码" vs "做后台任务"—完全不搭界的事情却同在同一个 plugin
- 如果按此节奏补齐媒体(10)、AI(10)、网络(8)等，会产生 **40+ skill 在 4-5 个大 plugin 里** — agent 无法分辨哪些需要加载
- 每个 skill 都是深度文章（1-4KB），全部加载 = context 爆炸

### Agent Skills 标准的工作机制

Agent 通过 **skill description** 字段匹配用户意图来触发加载。这意味着：
1. description 是唯一的路由机制
2. 越精确的 description → 越精准的触发
3. 但不存在"先加载 A，A 里推荐 B"的显式机制

**所以必须通过结构化设计模拟渐进加载**：索引 skill 被触发 → agent 理解全局 → 根据具体问题加载对应的深度 skill。

---

## 二、三层渐进架构

```
                        ┌──────────────────┐
                        │  harmony-index   │  ← 总索引（~1KB）
                        │  (1 skill)       │     永远是第一个被触发的
                        └──────┬───────────┘
                               │ 描述7个领域 + 指向各领域索引
               ┌───────────────┼───────────────┐
               ▼               ▼               ▼
        ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
        │ 0-core-idx  │ │ 0-system-idx│ │ 0-media-idx │ ← 领域索引（~1KB each）
        │  (轻量)      │ │  (轻量)      │ │  (轻量)      │    列出子领域 + 指向深度 skills
        └──────┬──────┘ └──────┬──────┘ └──────┬──────┘
               │               │               │
      ┌────────┼────────┐      │      ┌────────┼────────┐
      ▼        ▼        ▼      ▼      ▼        ▼        ▼
  深度skill  深度skill  深度skill   深度skill  深度skill  深度skill
  (2-4KB)   (2-4KB)   (2-4KB)     ...       ...       ...
```

### 第一层：总索引 `harmony-index`

**定位**：系统入口，描述"鸿蒙开发有哪些领域、每个领域下有什么"

```yaml
name: harmony-index
description: >-
  鸿蒙全栈开发总索引。涉及任意鸿蒙开发问题时首先加载本技能以确定领域。
  触发: HarmonyOS、鸿蒙、ArkTS、ArkUI、元服务、卡片、Native、端云、上架
```

**内容**：
- 7 个领域分类表（应用框架 / 系统 / 媒体 / 图形 / 应用服务 / AI / 发布）
- 每个领域下列出其领域索引 skill 名称
- 典型场景 → 推荐加载路径（如"做音频播放 → 加载 0-media-index → 加载 media-playback"）
- 约 1KB

### 第二层：领域索引 `0-{domain}-index`

**定位**：领域总览，描述"这个领域里有哪些 Kit，分别做什么，何时加载哪个深度 skill"

```yaml
name: system-index
description: >-
  鸿蒙系统能力总索引。涉及后台任务、权限安全、网络/通信、数据存储、文件管理、
  分布式、传感器、加密/认证等系统级能力时加载本技能以定位具体子领域。
```

每个领域索引包含：
- 该领域下所有子领域 / Kit 的功能一句话描述
- 每个子领域指向的深度 skill 名称
- **NOT** 包含详细 API 用法（那是深度 skill 的事）
- 约 1KB

### 第三层：深度 Skill

**定位**：具体 Kit/场景的详细知识，保持现有 skill 风格（方法论 + 排查清单 + 核心模式）

每个深度 skill 遵循现有写法，但 frontmatter 增加 `requires` 字段指明其领域索引：

```yaml
name: network-requests
description: >-
  鸿蒙网络请求: HTTP 数据请求、WebSocket 双向连接、Socket 连接、
  弱网优化、网络状态监听。涉及网络、API 调用、上传下载时使用。
requires: 0-system-index
kits: ["@kit.NetworkKit", "@kit.NetworkBoostKit"]   # @ 为 YAML 保留字符,必须加引号
```

---

## 三、最终的仓库结构

```
harmonyos-skills/
├── README.md
├── ARCHITECTURE.md                 ← 本文档
├── CHANGELOG.md
│
├── plugins/
│   │
│   ├── harmony-platform/           ← 🆕 平台入口层
│   │   ├── .claude-plugin/plugin.json
│   │   └── skills/
│   │       ├── harmony-index/      # 🌐 总索引（~1KB，必装）
│   │       └── version-guide/      # API 版本迁移（从 harmony-core 迁入）
│   │
│   ├── harmony-core/               ← 优化：拆分过重内容
│   │   ├── .claude-plugin/
│   │   │   ├── plugin.json
│   │   │   ├── hooks.json
│   │   │   └── commands/
│   │   ├── skills/
│   │   │   ├── 0-core-index/       # 🆕 应用框架域索引（~1KB）
│   │   │   ├── arkts-syntax/       # 已有，深度
│   │   │   ├── arkts-concurrency/  # 🆕 从 arkts-syntax 拆分并发
│   │   │   ├── arkui-patterns/     # 已有
│   │   │   ├── arkui-window/       # 🆕 窗口+屏幕管理（原漏）
│   │   │   ├── stage-model/        # 已有
│   │   │   ├── arkweb/             # 🆕 Web容器 P1
│   │   │   ├── hvigor-build/       # 已有
│   │   │   ├── harmony-debugging/  # 已有
│   │   │   ├── atomic-services/    # 已有（元服务+卡片）
│   │   │   └── multi-device-adaptation/ # 已有
│   │   └── commands/               # 已有
│   │
│   ├── harmony-system/             ← 🆕 系统能力
│   │   ├── .claude-plugin/plugin.json
│   │   └── skills/
│   │       ├── 0-system-index/     # 🆕 系统域索引（~1KB）
│   │       ├── background-tasks/   # 已有，从 harmony-core 迁入
│   │       ├── data-storage/       # 已有，从 harmony-core 迁入（重命名）
│   │       ├── distributed/        # 已有，从 harmony-core 迁入（重命名）
│   │       ├── security-permissions/ # 已有，从 harmony-core 迁入
│   │       ├── crypto-security/    # 🆕 加解密+密钥+认证 P1
│   │       ├── network-requests/   # 🆕 HTTP/WebSocket/Socket P0
│   │       ├── connectivity/       # 🆕 蓝牙/WiFi/星闪 P2
│   │       └── file-system/        # 🆕 文件管理 P1
│   │
│   ├── harmony-media/              ← 🆕 多媒体（P0 缺口）
│   │   ├── .claude-plugin/plugin.json
│   │   └── skills/
│   │       ├── 0-media-index/      # 🆕 媒体域索引
│   │       ├── audio-playback/     # 🆕 音频播放+录制
│   │       ├── camera-capture/     # 🆕 相机
│   │       ├── media-processing/   # 🆕 编解码+图片处理
│   │       └── media-system/       # 🆕 AVSession+投屏+DRM
│   │
│   ├── harmony-graphics/           ← 🆕 图形（P2 缺口）
│   │   ├── .claude-plugin/plugin.json
│   │   └── skills/
│   │       ├── 0-graphics-index/   # 🆕 图形域索引
│   │       ├── 2d-graphics/        # 🆕 ArkGraphics 2D
│   │       └── 3d-ar/              # 🆕 3D+AR+Spatial
│   │
│   ├── harmony-ai/                 ← 🆕 AI（P2 缺口）
│   │   ├── .claude-plugin/plugin.json
│   │   └── skills/
│   │       ├── 0-ai-index/         # 🆕 AI域索引
│   │       ├── ai-vision/          # 🆕 视觉AI（OCR/检测）
│   │       ├── ai-speech/          # 🆕 语音AI
│   │       ├── ai-nlp/             # 🆕 NLP
│   │       └── ai-inference/       # 🆕 端侧推理
│   │
│   ├── harmony-ecosystem/          ← 从 harmony-cloud 扩展
│   │   ├── .claude-plugin/plugin.json
│   │   └── skills/
│   │       ├── 0-ecosystem-index/  # 🆕 生态服务域索引
│   │       ├── huawei-kits/        # 已有（账号/推送/支付/地图等）
│   │       ├── cloud-foundation/   # 已有
│   │       ├── notification/       # 🆕 通知 P1
│   │       ├── location-map/       # 🆕 定位+地图深度
│   │       └── sharing-social/     # 🆕 分享+联系人+日历+DeepLink P2
│   │
│   └── harmony-release/            ← 保留
│       ├── .claude-plugin/plugin.json
│       └── skills/
│           ├── 0-release-index/    # 🆕 发布域索引
│           ├── performance-tuning/ # 已有
│           ├── testing-harmony/    # 已有
│           ├── signing/            # 已有
│           └── release-compliance/ # 已有
│
├── tools/
│   ├── sdk-diff/
│   ├── sync-skills.sh
│   ├── lint-skills.sh              # 一致性校验（CI 强制）
│   └── evals/
│       └── evals.json
│
└── .github/workflows/
    ├── ci.yml                      # push/PR 触发 lint
    └── weekly-sdk-watch.yml
```

> **共享数据放在 skill 内部，不放仓库根**：错误对照表在 `harmony-debugging/references/common-errors.md`，
> TS 迁移对照在 `arkts-syntax/references/ts-to-arkts.md`，API 版本变更清单（SDK diff 产出）落
> `version-guide/references/`。原因：`sync-skills.sh` 以 skill 目录为单位复制，仓库根级文件
> 同步到 Codex / OpenCode 等工具时会丢失，skill 内的 references/ 才可移植。

---

## 四、索引 Skill 设计规范

### 格式模板

```markdown
---
name: 0-{domain}-index
description: >-
  {一句话定位}。加载后根据具体问题再加载对应深度 skill。
  触发: {关键词1}、{关键词2}、...
  provides: index
  target-depth:
    - deep-skill-name-1
    - deep-skill-name-2
requires: harmony-index
kits: ["@kit.XXX", "@kit.YYY"]   # 必须加引号: @ 是 YAML 保留字符,裸值无法解析
---

# {领域名称} 索引

## 何时用这个领域

{一句话说明场景边界}

## 子领域速查

| 如果你的问题是... | 加载 |
|-------------------|------|
| HTTP 请求超时、WebSocket 断连 | → network-requests |
| 后台任务被杀、下载中断 | → background-tasks |
| ... | ... |

## 核心不变量（领域级）

{1-2 条跨所有子领域的基本原则}
```

### 尺寸约束

| 层级 | 最大字数 | 说明 |
|------|---------|------|
| 总索引 `harmony-index` | 300 词 | 只是一个路由表 |
| 领域索引 `0-*-index` | 300 词 | 列出子领域 + 1-2 条领域原则 |
| 深度 skill | 600-1200 词 | 保持现有方法论密度 |

### 索引声明机制 (`provides: index`)

索引类 skill 使用 `provides: index` 元字段标识自身为路由层，Agent loader 可通过此字段区分"索引路由"与"深度知识"。

**当前状态**: 8 个索引 skill 均有此标记（1 个总索引 + 7 个领域索引）。

```
harmony-index        → provides: index              (总索引,无 requires)
0-core-index         → provides: index, requires: harmony-index
0-system-index       → provides: index, requires: harmony-index
0-media-index        → provides: index, requires: harmony-index
0-graphics-index     → provides: index, requires: harmony-index
0-ecosystem-index    → provides: index, requires: harmony-index
0-ai-index           → provides: index, requires: harmony-index
0-release-index      → provides: index, requires: harmony-index
```

**设计意图**:
- `provides: index` 是显式声明机制，不依赖 Agent 的隐式推理
- 外部 loader（如 Hermes 适配层、gstack ultrawork）可通过扫描此字段自动注册路由
- 深度 skill 没有 `provides` 字段，只有 `requires` 指向其领域索引

**跨平台迁移价值**: 在不支持 `description` 路由的平台上，只要有 loader 能识别 `provides: index`，即可实现索引→领域→深度的渐进加载，无需重写 skill 内容。

---

## 五、渐进加载流程示例

### 场景：用户说"App 冷启动要好几分钟，帮我优化"

```
1. Agent 扫描所有 skill description
2. "鸿蒙/HarmonyOS" → 命中 harmony-index（总索引）
3. 加载 harmony-index → 发现"性能优化 → 0-release-index"
4. 0-release-index 的 description 包含"性能/帧率/内存/启动"
   → 命中，加载
5. 0-release-index 路由表："启动/帧率/内存 → performance-tuning"
6. Agent 再主动加载 performance-tuning → 读取 Profiler 工作流 + 入口瘦身清单
7. 输出诊断步骤

全程加载：3 个 skill × 平均 1KB = ~3KB context。

> **注意**：Agent Skills 的 body 内容本就是按 description 触发按需加载的，旧结构下也不会 19 个 skill 全量加载。
> 但渐进架构的真实收益在于：(1) 47 个 skill 的 description 元数据开销固定 ~3-5KB，通过领域拆分使路由更精准；
> (2) 索引层提供全景发现兜底——当用户需求模糊时 agent 可通过 harmony-index 定位到正确的领域。
```

### 场景：用户说"做一个拍照上传功能"

```
1. 命中 harmony-index
2. harmony-index 路由："相机 → 0-media-index"、"网络 → 0-system-index"、"权限 → security-permissions"
3. Agent 并行加载 0-media-index + security-permissions
4. 0-media-index 路由："拍照/录像 → camera-capture"
5. Agent 加载 camera-capture
6. 在 camera-capture 中看到"上传"引用，再加载 network-requests

全程加载：~5 个 skill × ~1KB = ~5KB context
```

---

## 六、迁移计划（已完成）

全部 6 个 Stage 已于 v0.5.0 完成。当前处于 Phase 5 质量打磨期。

---

## 七、设计决策记录

| 决策 | 选项 | 选择 | 理由 |
|------|------|------|------|
| 索引 skill 命名 | `index` / `{domain}-overview` / `0-{domain}` | `0-{domain}-index` | 文件系统排序确保索引在目录列表首位，方便人工查看（对 description 路由无影响） |
| 索引 skill 是否可独立使用 | 纯路由 / 含领域原则 | 含 1-2 条核心原则 | 纯路由太单薄，加载后没有获得感 |
| 深度 skill 是否引用索引 | 显式 `requires` / 仅 description 暗示 | 显式 `requires` | 多一个路由信号减轻 description 负担 |
| 跨 plugin 迁移已有 skill | 保留路径 / 移动路径 | 移动路径 | 归属于语义正确的 plugin，长期可维护 |

---

## 八、量化目标

| 指标 | v0.1.0 | v0.2.0 | v0.5.0 | v0.6.0 |
|------|--------|--------|--------|--------|
| Skill 数量 | 19 | 47 | 53 | 53（质量打磨期） |
| Plugin 数量 | 3 | 8 | 8 | 8（稳定） |
| 深度 skill 数量 | 19 | 35 | 45 | 45 |
| Kit 覆盖率 | ~19% | ~45% | ~50% | ~50% |
| 单 skill 最大字数 | ~1200 词 | 不变 | 不变 | 不变 |
| 质量审计 | — | — | v2.0 (抽查) | v3.0 (全量45个skill) |

> **关于 context 开销**：Agent Skills 的 body 内容按 description 触发按需加载，不会全量载入。
> 重构前后的真实变化是：47 个 skill 的 name+description 元数据常驻 context（约 3-5KB，vs 旧版 19 个约 1.5KB），
> 对终端用户影响可忽略。收益在于更精准的路由和索引层的全景发现兜底。

---

## 九、Skill 目录规约

遵循 Agent Skills 标准目录结构（SKILL.md 必需，scripts/、references/、assets/ 可选），但**按内容驱动，禁止为合规建空目录**：

| 目录 | 何时建 | 本仓库实例 |
|------|--------|-----------|
| `references/` | 被字数上限（深度 skill ≤1200 词）挤出的权威长尾内容：错误对照表、API 明细、逐条迁移示例 | `harmony-debugging/references/common-errors.md`、`arkts-syntax/references/ts-to-arkts.md`、`testing-harmony/references/qa-checklist.md` |
| `scripts/` | 确定性检查类可执行逻辑（可随 skill 同步到 Codex/OpenCode，弥补 commands 仅 Claude Code 可用） | `harmony-debugging/scripts/check_project_config.sh` |
| `assets/` | 真实模板/样板文件（build-profile 模板、卡片样板） | 暂无，待 Phase 3 |

硬规则（`tools/lint-skills.sh` 强制，CI 拦截）：

1. SKILL.md 正文引用的 `references/`、`scripts/` 相对路径**必须存在**（check #7）
2. 索引 skill（harmony-index、`0-*-index`）**永远单文件**，不建子目录
3. frontmatter 的 `kits` 值必须加引号——`@` 是 YAML 保留字符（check #3）
4. 任何具体 API 名必须经 `tools/sdk-diff` 或官方文档核实后才能写入；未核实内容只能以"参考官方文档"指引形式存在

## 十、发布 Checklist

每次发版前依次执行：

- [ ] `bash tools/lint-skills.sh` 全部 PASS（12 项检查，含 frontmatter 内容质量）
- [ ] 版本号三处同步：marketplace.json（metadata + 各 plugin 条目）、8 个 plugin.json、README"当前版本"行
- [ ] README 技能矩阵、命令表与目录树一致（lint 部分覆盖，人工复核新增/删除项）
- [ ] CHANGELOG.md 新增本版本条目
- [ ] evals.json：新增 skill 已补 2-3 条用例（含触发与预期输出）
- [ ] 新增/改动 skill 已补 `test-cases/test-prompts.md`（见 §十二约定）
- [ ] 本地实测：`/plugin install <每个新增/改动插件>@harmonyos-skills` 安装成功且 skill 可触发

---

## 十一、检索层 / 开发层分离与 Master 大路由

> 借鉴 `harmonyos-agent-skills`（HarmonyOS_Skills 官方组织）的两个工程模式，落进本仓库。

### 检索层 / 开发层分离

把"取官方证据"与"写业务代码"拆成两类技能，避免开发技能凭记忆编造易过期的 API：

- **检索层**（`layer: retrieval`）：只产出"官方原文 + URL/版本"，不写业务代码。
  本仓库实例：`harmony-docs-retriever`（官方文档）。它对应 ARCHITECTURE 的第零条原则
  "先查本地 SDK / 官方文档再写码"——把方法论沉淀成了一个可复用技能。
- **开发层**：拿检索层给的证据完成编码与验证（`arkts-syntax`、各 Kit 技能等）。

> 稳态检索的关键经验：官方文档站搜索接口 `/doc/search?` 被 robots 禁止且无公开 JSON，
> 因此检索层走"本地锚点表 + site 限定搜索 + web-fetch"，**绝不直连搜索接口**。
> 这与官方 `knowledge-retriever` 技能检索本地 KB（而非实时 API）是同一稳态选择。

### Master Skill 大路由模式

当一个主题复杂到需要多份深度内容时，用一个**分型/分场景路由技能**先判型，再指向细分内容：

- 既有实例：`harmony-index`（领域路由）、`0-*-index`（子领域路由）。
- 新增实例：`crash-diagnostics`——按 CppCrash/JsCrash/AppFreeze/内存泄漏**分型**路由到
  `references/` 下各型详解。相比官方仓库"每型一个独立 skill"，本仓库用"一个路由技能 +
  references 分型"，在保留分型价值的同时遵守尺寸与密度纪律。

---

## 十二、test-cases / 触发样本约定

> 借鉴官方仓库"每个 skill 必带测试提示词"的交付件要求，按本仓库密度纪律裁剪落地。

- **位置**：`<skill>/test-cases/test-prompts.md`。
- **适用**：深度 skill（索引 skill 豁免）。`tools/lint-skills.sh` 第 12 项做**软提示**
  （缺失仅 WARN，不拦截 CI），鼓励逐步补齐而非一次性强制。
- **与 evals 的分工**：`tools/evals/evals.json` 是仓库级触发率/质量回归集（跨 skill）；
  `test-prompts.md` 是 skill 本地的功能/边界/错误场景用例，随 skill 同步到 Codex/OpenCode。
- **模板**（参考 `harmony-docs-retriever`、`crash-diagnostics` 两个范例）：

```markdown
# 测试提示词 — <skill-name>
## 基础功能测试
### 场景 1：<名称>
**提示词**：<用户输入>
**预期输出**：- <期望行为/触发的技能/关键决策点>
## 边界条件测试
### 场景 2：<边界场景>
**提示词**：... / **预期输出**：...
## 错误处理测试
### 场景 3：<错误或负向场景>
**提示词**：... / **预期输出**：<期望的错误处理/不应触发>
```

---

## 十三、内容质量审查与 ArkTS 校验闭环

- **frontmatter 内容质量**：`tools/validate-frontmatter.py`（被 lint 第 11 项调用）按
  Claude Skills 规范审查 name 字符集、description 的 what+when、长度等。CRITICAL 拦截，
  风格问题降级 WARN，不破坏存量 skill。借鉴官方 `.hmos-skill-reviewer` 思路。
- **ArkTS 编译器级校验闭环**：`arkts-syntax/scripts/arkts-lint.sh` + `hooks/ets-lint-gate.sh`
  可接入 OpenHarmony 官方 `linter-cli`（来自 `harmonyos-agent-rules`）做真实编译器诊断，
  回退 codelinter，再回退 grep 快检。接入见 `arkts-syntax/references/arkts-linter-setup.md`。

---

## 十四、Claude Code 市场集成

### 市场结构

```
harmonyos-skills/
├── .claude-plugin/
│   └── marketplace.json         ← 市场清单（8 个 plugin + 元数据）
├── plugins/
│   ├── harmony-platform/
│   │   └── .claude-plugin/
│   │       └── plugin.json      ← 插件定义（skills 列表 + 版本号）
│   ├── harmony-core/
│   │   └── .claude-plugin/
│   │       ├── plugin.json
│   │       ├── hooks.json        ← UserPromptSubmit + PostToolUse hooks
│   │       └── commands/         ← /harmony-doctor 等 Claude Code 命令
│   ├── harmony-system/
│   ├── harmony-media/
│   ├── harmony-ecosystem/
│   ├── harmony-graphics/
│   ├── harmony-ai/
│   └── harmony-release/
```

### 市场注册

用户将本仓库添加为市场源后，Claude Code 读取 `.claude-plugin/marketplace.json`，自动发现所有可用 plugin。

### 插件安装

每个 plugin 的 `.claude-plugin/plugin.json` 定义其 skills 列表。安装时：
- SKILL.md 正文 → 按 description 触发按需加载
- commands/ → 注册为 `/harmony-*` 命令（仅 Claude Code）
- hooks.json → 注册生命周期钩子（仅本插件作用域）
- references/ / scripts/ → 随 skill 目录同步

### 跨工具兼容

`tools/sync-skills.sh` 将 skill 目录复制到 `~/.agents/skills`（加 `harmony-` 前缀防止冲突），Codex / OpenCode 等工具直接读取。commands 核心逻辑已抽象到 `tools/commands/*.sh`，终端下可独立运行。

## 断言撰写规范（v0.7.0 引入）

`tools/evals/evals.json` 的 `quality_assertion` 字段是 v0.7.0 起的"防回潮"硬约束，撰写时必须遵循以下规范。

### 1. `machine` 断言可追溯

每条 `machine` 断言必须**给出 ≥1 条对应 ROADMAP 6.1 / 5.2 的修复记录**——即该断言是"防某个已知杜撰 API / 性能臆测回潮"。

### 2. `semantic` 断言可判定

每条 `semantic` 断言必须**有具体可读的判定提示**（`note` 字段），例如"必须显式给出 X 调用，不能只说 Y"——禁止写"输出质量好""表述准确"这种空话。

### 3. 数量上限

同一 skill 的 `machine` 断言不超过 6 条；超出部分由维护者评估是否真有必要。理由：黑名单维护成本与鸿蒙版本迭代速度正相关，无信源不扩。

### 4. 命名稳定

断言名沿用 `q-<skill_slug>-<idx>` 格式（仅作为 `id` 字段在 `quality_assertion` 内的可选 key 出现），便于历史趋势 diff。

### 5. 失败转 semantic 机制

任何新增断言若 3 次 PR 都被维护者手动判"误报"，自动转 `semantic` 并 issue 化。run_evals.py 的 `aggregate` 输出会标记误报率；CI 评论附统计。

### 6. 撰写模板

```json
{
  "id": <递增 int>,
  "skill": "<skill-slug>",
  "prompt": "<用户提问样例>",
  "expected_output": "<期望 agent 触发的技能与行动>",
  "quality_assertion": {
    "type": "machine",
    "check": "not_contains | contains | regex_match",
    "target": "stdout",
    "value": ["token1", "token2"]    // 或 "regex pattern"（regex_match 时为字符串）
  }
}
```

`semantic` 类型示例：

```json
{
  "type": "semantic",
  "note": "维护者必读:<具体可读判定>"
}
```
