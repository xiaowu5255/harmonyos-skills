# v0.7.0 信源质量 + 自进化硬化 — Design Spec

- **作者**：xiao5（通过 brainstorming 流程）
- **日期**：2026-06-15
- **基线版本**：v0.6.2
- **目标版本**：v0.7.0
- **状态**：待用户复核 → 交棒 writing-plans

---

## 1. 背景与原则

仓库 v0.6.2 已完成三轮独立审计：全量 API 正确性（5.x）、Context7 接入（6.1）、检索时效分层 + 杜撰 API 系统性清除（6.2）。**已发布的承诺已基本成立**，剩下的主要矛盾是"防回潮"与"自进化主动脉的运行化"。

**本仓库护城河**（ROADMAP 6.0）：skill 只教方法，事实层退给本地 d.ts / Context7 / 官方 SPA。本 spec 不改这一分工。

**贯穿红线**（约束 v0.7.0 全部改动）：

1. SKILL.md 引用的文件必须存在
2. 具体 API 名/文档 URL 必须经 sdk-diff 或实测核实
3. 禁止无信源性能数值入库

---

## 2. 目标与非目标

### 2.1 目标（v0.7.0 必须达成）

1. **质量断言扩容**：从已有基数扩到 ≥30 条，新增分布到 8 个高优 skill
   - arkts-syntax、arkui-patterns、stage-model、security-permissions
   - network-requests、audio-playback、media-system、ai-inference
   - 每 skill 新增 4 条断言（3 正 + 1 负），共 +32 条
2. **CI 轻量采集成**：新增 `evals-report` job，**不阻断合并**
3. **自进化主动脉文档化**：ROADMAP 新增 Phase 7，记录季度审计与 feedback-distill 的运行节奏 + 责任人 + 判定标准；**首跑留到 v0.7.1 / v0.8.0**

### 2.2 非目标（v0.7.0 明确不做）

- 不上 CI 硬门禁
- 不开新 skill 领域
- 不批量改造 SKILL.md frontmatter 给 Hermes（HERMES.md 已指引用户自跑）
- 不动 ROADMAP 6.0 四层分工
- 不改 lint 12 项（仅追加"建议 evals 覆盖"的软提示）

### 2.3 成功判据

- 8 高优 skill 在 `tools/evals/evals.json` 中各 ≥4 条 `quality_assertion`
- CI workflow 新增 `evals-report` job，PR 自动评论趋势表
- ROADMAP 新增 Phase 7
- CHANGELOG 增 v0.7.0 条目
- lint 12 PASS / 0 FAIL 不退步
- 整套新增改动 < 800 行（不含 evals 文本）

---

## 3. 架构与组件

整体不破坏现有四层分工与三层渐进加载。v0.7.0 只在 **tooling 层 + evals 数据层**叠加。

```
┌─────────────────────────────────────────────────────────────┐
│ PR / push 触发                                              │
│   ↓                                                         │
│ .github/workflows/ci.yml                                    │
│   ├── job: lint      (已存在，12 项检查)                     │
│   └── job: evals-report  (新增，轻量采集)                    │
│         │                                                    │
│         ├─ 跑 tools/evals/run_evals.py（新增）              │
│         │     ├─ 调起 Claude/Codex 跑 evals.json 全量        │
│         │     ├─ 解析 quality_assertion 机器可判定项         │
│         │     └─ 输出 JSON 报告到 tools/evals/reports/       │
│         │                                                    │
│         └─ 上传报告 + PR 评论趋势 diff                       │
└─────────────────────────────────────────────────────────────┘
```

### 3.1 新增/改动清单

| # | 路径 | 动作 | 行数估算 |
|---|------|------|---------|
| 1 | `tools/evals/evals.json` | 改 | +32 条 quality_assertion |
| 2 | `tools/evals/run_evals.py` | 新 | ~180 |
| 3 | `tools/evals/reports/.gitkeep` | 新 | 0 |
| 4 | `tools/evals/reports/comment_template.md` | 新 | ~30 |
| 5 | `.github/workflows/ci.yml` | 改 | +50 |
| 6 | `ROADMAP.md` | 改 | +60（Phase 7） |
| 7 | `CHANGELOG.md` | 改 | +25 |
| 8 | `tools/lint-skills.sh` | 改 | +5（软提示） |
| 9 | `ARCHITECTURE.md` | 改 | +40（断言撰写规范节） |
| 10 | `.gitignore` | 改 | +2（reports/*.json） |
| 11 | `docs/superpowers/specs/2026-06-15-v070-quality-evals-design.md` | 新 | 本文件 |

**总行数估算**：~420（不含 evals 文本与本文档），远低于 800 行上限。

### 3.2 关键边界

- `run_evals.py` 不知道任何 skill 业务逻辑，只**协议层**——读 evals.json、发出 prompt、收输出、跑正则/字符串匹配
- 语义类断言仍标注为 `semantic`，报告中列"未自动化"，由维护者人工 review
- CI 的 `evals-report` job **只读 evals.json 中的 `quality_assertion` 字段**做机器判定，与 `lint-skills.sh` 解耦
- 报告输出按日期归档，**不进 git 索引**（`.gitignore` 加 `tools/evals/reports/*.json`，保留 `.gitkeep`）

---

## 4. 数据流与质量断言设计

### 4.1 `quality_assertion` 两类

| 类型 | 字段 | 判定方式 | 示例 |
|------|------|---------|------|
| `machine` | `check: "not_contains" \| "contains" \| "regex_match"` + `target: "stdout"` | Python 跑一次正则/字符串 | `not_contains: ["createAudioSession", "LocalRPC", "castAudio"]` |
| `semantic` | `note: "<维护者必读>"` | 报告中列"未自动化"，PR 评论提示人工 review | "输出不得使用 release 默认开启混淆的表述" |

### 4.2 evals.json 新增断言样例（节选）

**`arkts-syntax`**（v0.6.0 已修，最稳的反而要多守）：
- machine: `not_contains: ["markContentDirty"]`（v0.6.0 已清，防回潮）
- machine: `not_contains: ["@Styles", "@Extend"]`（强制走 AttributeModifier）
- machine: `contains: ["@Sendable", "TaskPool"]`（并发硬约束命中）
- semantic: "ArkTS 不允许解构赋值的描述必须出现"

**`security-permissions`**：
- machine: `contains: ["Picker", "安全控件"]`（决策树起点）
- machine: `not_contains: ["@ohos.permission.CAMERA（无 picker 前缀）"]`
- machine: `regex_match: "permission.*ACL"`（ACL 决策点）
- semantic: "Picker 优先于申请权限的判断逻辑必须显式"

**`audio-playback`**（v0.6.1 刚大修，最值得守）：
- machine: `not_contains: ["createAudioSession", "createAudioCapturer\\(\\)"]`（杜撰 API 黑名单）
- machine: `contains: ["getSessionManager", "activateAudioSession"]`
- machine: `not_contains: ["MIDI.*ArkTS", "midi\\.createMIDIDevice"]`（MIDI 必须指 C-API）
- semantic: "MIDI 章节必须明确为 native C-API"

> 全 8 skill × 4 条 = 32 条断言的完整清单在实现阶段补齐，本 spec 仅示范。

### 4.3 断言撰写规范（写入 ARCHITECTURE.md 新增节）

1. `machine` 断言必须**给出 ≥1 条对应 ROADMAP 6.1 / 5.2 的修复记录**（可追溯）
2. `semantic` 断言必须**有具体可读的判定提示**（不能是"输出质量好"这种空话）
3. 同一 skill 的 `machine` 断言不超过 6 条，避免维护者负担爆炸
4. 断言名稳定（`q-<skill_slug>-<idx>`），便于历史趋势 diff
5. 黑名单类（`not_contains`）必须有**对应的官方修复记录**或**已验证为虚构**，禁止把"我个人没见过"列为黑名单

### 4.4 数据流

```
evals.json (改前 72 条 / 已有 16 条 quality_assertion 含 15 字符串 + 1 dict)
   ↓ run_evals.py
   ├─ for each eval with quality_assertion:
   │     ├─ 调 agent 跑 eval.prompt
   │     ├─ 收集 stdout
   │     ├─ 应用 machine.check
   │     └─ 写 {skill, eval_id, type, passed, detail}
   ↓
tools/evals/reports/<date>.json
   ↓
PR 评论 / CI artifact
```

### 4.5 run_evals.py 关键接口

```python
# 伪代码，仅约定接口
def run_eval(eval: dict) -> EvalResult: ...
def apply_machine_assertion(assertion: dict, stdout: str) -> bool: ...
def aggregate(results: list[EvalResult]) -> Report: ...

# CLI
python tools/evals/run_evals.py --report-date 2026-06-15
python tools/evals/run_evals.py --dry-run --skill security-permissions
```

- 调起 agent：使用 `claude` CLI 子进程（仓库已用 Claude Code 工具链，假设 CI runner 有 `claude` 命令与 `ANTHROPIC_API_KEY`）
- 超时：单条 120s
- 重试：单条最多 1 次重试，仍失败标 `timeout`

---

## 5. CI 接入、错误处理、验收

### 5.1 CI 接入（`.github/workflows/ci.yml` 追加）

```yaml
evals-report:
  runs-on: ubuntu-latest
  needs: lint
  if: github.event_name == 'pull_request'
  continue-on-error: true        # 关键：不阻断
  permissions:
    contents: read
    pull-requests: write
  steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-python@v5
      with: { python-version: '3.11' }
    - name: 跑 evals 报告
      env:
        ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        CLAUDE_CLI: ${{ secrets.CLAUDE_CLI }}      # 复用仓库现有 secret
      run: python tools/evals/run_evals.py --report-date ${{ github.event.pull_request.head.sha }}
    - name: 上传报告
      uses: actions/upload-artifact@v4
      with:
        name: evals-report
        path: tools/evals/reports/
    - name: PR 评论
      uses: actions/github-script@v7
      with:
        script: |
          const fs = require('fs');
          const path = `tools/evals/reports/${context.payload.pull_request.head.sha}.json`;
          if (!fs.existsSync(path)) return;
          const r = JSON.parse(fs.readFileSync(path));
          await github.rest.issues.createComment({
            owner: context.repo.owner, repo: context.repo.repo,
            issue_number: context.issue.number,
            body: renderTrendTable(r),
          });
```

### 5.2 错误处理

| 失败模式 | 处理 |
|---------|------|
| `ANTHROPIC_API_KEY` 未配 | job 直接跳过，PR 评论 "evals-report skipped: secret missing"，不报错 |
| agent 调起超时（>120s/eval） | 单条标 `timeout`，整体继续；超时条数 > 20% 报警 |
| evals.json 解析失败 | 复用 lint 的 JSON 严格解析（已有），提前 fail |
| `not_contains` 黑名单误报 | 报告中列出误报条目，维护者下次迭代修正断言 |
| `run_evals.py` 自身崩溃 | `continue-on-error: true`，PR 评论只显示 "evals 报告生成失败，请本地重跑" |

### 5.3 回退策略

- CI job 默认 `continue-on-error: true`，lint 通过即合并
- 报告与 PR 评论**只追加，不覆盖**，历史可追
- 任何新增断言若 3 次 PR 都被维护者手动判"误报"，自动转 `semantic` 并 issue 化
- v0.7.0 发布后 30 天内若发现 `evals-report` job 误报率 > 30%，可一键 disable（仓库 Settings → Actions）

### 5.4 验收 checklist

1. 8 高优 skill 各 ≥4 条 `quality_assertion`，evals.json 通过 lint 第 11/12 项
2. 新 PR 触发后，CI artifact 含 `tools/evals/reports/<sha>.json`
3. PR 评论出现趋势表（与上一次报告对比 machine 断言通过率）
4. ROADMAP Phase 7 写入并 commit
5. CHANGELOG v0.7.0 条目 commit
6. `tools/lint-skills.sh` 仍 12 PASS / 0 FAIL
7. 整体新增 < 800 行（不含 evals 文本与本 spec）
8. 本地 dry-run：`python tools/evals/run_evals.py --dry-run --skill security-permissions` 跑通
9. ARCHITECTURE.md 新增"断言撰写规范"节

---

## 6. ROADMAP Phase 7 内容草案

写入 `ROADMAP.md`，紧接 Phase 6 之后：

```markdown
## Phase 7 — 自进化主动脉节奏化（当前: v0.7.0）

### 7.0 节奏表

| 主动脉 | 频率 | 责任人 | 入口 | 首跑 |
|--------|------|--------|------|------|
| 季度审计 | 每季度 | 维护者 | `tools/quarterly-audit-checklist.md` | 2026-09 |
| feedback-distill | 每月 | 维护者 | `tools/feedback-distill.sh` | 2026-07 |
| weekly-sdk-watch | 每周 | 自动化 | `.github/workflows/weekly-sdk-watch.yml` | 已跑 |
| CI evals-report | 每次 PR | 自动化 | `.github/workflows/ci.yml` (新增 job) | v0.7.0 |

### 7.1 季度审计判定标准

参照 AUDIT_REPORT v3.0 流程，输出"通过/有 P0 修复项/有 P1 修复项/有 P2 修复项"四级结论。

### 7.2 feedback-distill 判定标准

输出"新增 N 条 / 合并入 X skill / 拒收 M 条"三栏。**拒收必须记录原因**，归档 6 个月。
```

---

## 7. 风险与缓解

| 风险 | 缓解 |
|------|------|
| agent 在 CI 中跑 evals 成本高（时间+token） | 默认 `if: github.event_name == 'pull_request'` 而非 push；超时 120s 兜底；`continue-on-error` |
| 黑名单类断言维护成本随鸿蒙版本上升 | 黑名单来自 ROADMAP 6.1 / 5.2 的修复记录，**不主动扩**，新发现的杜撰 API 走 ROADMAP 6.2 流程 |
| `claude` CLI 在 CI runner 不可用 | fallback：用 `anthropic-sdk` Python 直连，路径一致；不在 v0.7.0 范围内但留 stub |
| 维护者负担 | 同一 skill `machine` 断言 ≤ 6；3 次误报自动转 `semantic` |
| 数据漂移 | 报告只追加不覆盖，trend 在 PR 评论中以表格呈现 |

---

## 8. 范围外延（不进入 v0.7.0）

为防止 spec 蔓延，明确以下项**不在 v0.7.0**：

1. v0.7.1+ 才正式跑季度审计预演
2. v0.7.1+ 才把 feedback-distill 接为 CI 月度 job
3. v0.8.0+ 才考虑 CI 硬门禁（待 30 天观察 evals-report 误报率）
4. v0.8.0+ 才考虑多 consumer 文档统一收口
5. v0.8.0+ 才开新 skill 领域（45%→65% 之后那一截）

---

## 9. 自检（spec 写完后自检）

- [x] 无 TBD / TODO / 占位
- [x] 章节内部一致：8 高优 skill 名单在 §2.1 / §4.2 / §5.4 三处一致
- [x] 范围聚焦：v0.7.0 一个版本；延后事项全部 §8 列出
- [x] 歧义消解：`machine`/`semantic` 二分明确；`continue-on-error: true` 明确
- [x] 验收有 9 条具体 checklist，可执行

---

## 10. 下一步

1. **用户复核本 spec**（按 brainstorming 流程）
2. 复核通过后 → 调用 `superpowers:writing-plans` 拆实现计划
3. 计划批准后 → 进入实现（建议 `oh-my-claudecode:ultrawork` 走完全程）
