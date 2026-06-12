# harmonyos-skills 开发路线图

> 制定于 2026-06-12，基于 v0.2.0 重构评估报告。原则：**先让已发布的承诺成立，再扩张**。

## 总路线

```
v0.2.1 修复发布阻断 ✅ → v0.2.2 一致性基建 ✅ → v0.3.0 占位转正 → v0.4.0 覆盖扩展 → 持续:自进化闭环
```

## Phase 0 — v0.2.1 发布修复 ✅（2026-06-12 完成）

- [x] marketplace.json 重写为 8-plugin 清单（修复安装阻断）
- [x] 20 个 skill 的 `kits: [@kit.X]` 非法 YAML 加引号
- [x] README 计数对齐

## Phase 1 — v0.2.2 一致性基建 ✅（2026-06-12 完成）

- [x] 核实 references/、scripts/ 引用文件齐全（common-errors.md、ts-to-arkts.md、qa-checklist.md、check_project_config.sh）
- [x] lint 升级 10 项检查 + CI（push/PR 自动拦截漂移）
- [x] evals 22→38 条（13 个深度 skill 补样、占位域路由、负样本）
- [x] 版本号/作者/拼写统一（harmonic-debugging、security-and-permissions 旧名清除）
- [x] ARCHITECTURE.md：目录规约、发布 Checklist、共享数据 skill 内化
- [x] sync-skills.sh 加 harmony- 前缀防冲突
- [x] 占位 skill 52 个文档 URL 全量核实，49 个失效链接替换为已验证 Kit 入口

## Phase 2 — v0.3.0 九个 P2 占位转正（目标：+1 个月）

转正流程（每个 skill）：**sdk-diff 核实 API → SKILL.md 重写为方法论密度（600-1200 词）→ 核实 API 明细放 references/ → 补 2-3 条 eval → lint 通过**。

| 批次 | Skill | 理由 |
|------|-------|------|
| 1 | camera-capture | 拍照是 P0 级高频场景 |
| 1 | media-processing | 图片处理几乎所有应用都用 |
| 2 | media-system | AVSession 播控是音视频上架硬要求 |
| 2 | ai-vision、ai-speech | OCR/语音是差异化能力，文档完备 |
| 3 | 2d-graphics、ai-inference | 特定场景 |
| 3 | 3d-ar、ai-nlp | 最长尾 |

## Phase 3 — v0.4.0 覆盖率扩展（目标：+2-3 个月，45%→65%）

| 新 Skill | 落点 | 优先级 | 说明 |
|----------|------|--------|------|
| accessibility-i18n | harmony-core | **P1** | 无障碍是上架合规要求，审计列 P1 但 v0.2.0 未做 |
| sensors-input | harmony-system | P2 | Sensor Service / Input / Pen Kit |
| telephony | harmony-system | P2 | 蜂窝通信、通话场景 |
| ipc-localization | harmony-core | P2 | IPC Kit、IME Kit、Localization Kit |
| assets/ 首批模板 | hvigor-build、atomic-services-and-cards | P3 | build-profile 模板、卡片样板 |

每新增 skill 同步：领域索引路由 +1 行、plugin.json、README 矩阵、2-3 条 eval（lint 强制）。

## Phase 4 — 自进化闭环常态运转（持续）

1. **知识回流**：`/harmony-feedback` → `harmony-debugging/references/common-errors.md`，每月审视回流质量
2. **SDK 监测**：weekly-sdk-watch 检出变更 → `diff_api.py` 生成清单 → `version-guide/references/` → 触达相关 skill 修订
3. **防退化**：CI 每次 push 跑 lint；skill 修改必须跑对应 eval
4. **季度审计**：参照 AUDIT_REPORT v2.0 流程做 v3.0（约 2026-09），重测覆盖率与正确性

## 贯穿红线

1. **任何 SKILL.md 引用的文件必须存在** —— lint check #7 拦截
2. **任何具体 API 名/文档 URL 必须经 sdk-diff 或实测核实** —— 未核实内容只能以"参考官方文档"指引存在（本仓库曾因臆造 slug 产生 49 个失效链接，教训记录于 CHANGELOG 0.2.2）
