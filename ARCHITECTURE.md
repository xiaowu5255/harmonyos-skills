# harmonyos-skills 渐进式架构设计

> **背景**：官方文档 ~142 个 Kit/专题，当前 3 plugin / 19 skill 的扁平结构无法线性扩展  
> **目标**：让 AI agent 按需加载知识，避免 context 爆炸，同时保持全栈覆盖

---

## 一、核心问题

### 当前结构的死胡同

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
requires: system-index
kits:
  - @kit.NetworkKit
  - @kit.NetworkBoostKit
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
├── references/                     ← 🆕 跨 skill 共享数据
│   ├── kit-mapping.json            # Kit ↔ Skill 映射表
│   ├── api-version-changelog.md    # API 版本变更（SDK diff 产出）
│   └── error-reference.md          # 错误对照表（feedback 回流）
│
├── tools/
│   ├── sdk-diff/
│   ├── sync-skills.sh
│   └── evals/
│       └── evals.json
│
└── .github/workflows/
    └── weekly-sdk-watch.yml
```

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
kits:
  - @kit.XXX
  - @kit.YYY
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

全程加载：3 个 skill × 平均 1KB = ~3KB context
vs 加载 19 个 skill × 平均 2KB = ~38KB（当前结构）
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

## 六、迁移计划

### Stage 1：创建索引层（本周，不改已有 skill）

| 操作 | 文件 |
|------|------|
| 新建 | `plugins/harmony-platform/skills/harmony-index/SKILL.md` |
| 新建 | `plugins/harmony-core/skills/0-core-index/SKILL.md` |
| 新建 | `plugins/harmony-system/skills/0-system-index/SKILL.md` |
| 更新 | 各已有 skill 的 description 增加领域归属关键词 |

### Stage 2：拆分过重内容（1 周）

| 操作 | 说明 |
|------|------|
| arkts-syntax → arkts-syntax + arkts-concurrency | 并发内容（TaskPool/Worker/Sendable）独立 |
| arkui-patterns 内部拆分窗口管理 | 新增 arkui-window skill |

### Stage 3：创建新 plugin + 补齐缺口（2 周）

| 操作 | 说明 |
|------|------|
| harmony-system plugin + network-requests, file-system, crypto-security | P0 缺口 |
| harmony-media plugin + 4 skills | P0 缺口 |
| harmony-ecosystem plugin + notification | P1 缺口 |

### Stage 4：扩展插件（1 月）

| 操作 | 说明 |
|------|------|
| harmony-ai plugin | P2 |
| harmony-graphics plugin | P2 |

---

## 七、设计决策记录

| 决策 | 选项 | 选择 | 理由 |
|------|------|------|------|
| 索引 skill 命名 | `index` / `{domain}-overview` / `0-{domain}` | `0-{domain}-index` | `0-` 前缀确保排序在最前 |
| 索引 skill 是否可独立使用 | 纯路由 / 含领域原则 | 含 1-2 条核心原则 | 纯路由太单薄，加载后没有获得感 |
| 深度 skill 是否引用索引 | 显式 `requires` / 仅 description 暗示 | 显式 `requires` | 多一个路由信号减轻 description 负担 |
| 跨 plugin 迁移已有 skill | 保留路径 / 移动路径 | 移动路径 | 归属于语义正确的 plugin，长期可维护 |

---

## 八、量化目标

| 指标 | 当前 | 目标 |
|------|------|------|
| Skill 数量 | 19 | ~45（含索引层 8 个） |
| Plugin 数量 | 3 | 8 |
| 平均加载 skill 数/请求 | 14（全加载） | ≤5（渐进加载） |
| context 消耗/请求 | ~38KB | ≤10KB |
| Kit 覆盖率 | 19% | ≥50% |
| 单 skill 最大字数 | ~1200 词 | 不变 |
