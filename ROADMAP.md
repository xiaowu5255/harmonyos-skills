# harmonyos-skills 开发路线图

> 制定于 2026-06-12，基于 v0.2.0 重构评估报告。原则：**先让已发布的承诺成立，再扩张**。

## 总路线

```
v0.2.1 修复发布阻断 ✅ → v0.2.2 一致性基建 ✅ → v0.3.0 占位转正 ✅ → v0.4.0 覆盖扩展 ✅ → 持续:自进化闭环
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

## Phase 2 — v0.3.0 九个 P2 占位转正 ✅（2026-06-12 完成）

转正流程（每个 skill）：**sdk-diff 核实 API → SKILL.md 重写为方法论密度（600-1200 词）→ 补 2-3 条 eval → lint 通过**。

> 规约修订（v0.4.0 后）：`references/` 改为**按需补充**而非硬性产出——仅当某 skill 积累了
> 足够多**经核实**的 API 明细时才外置到 references/。强行为每个转正 skill 造 references/ 会
> 与「贯穿红线 #2(未核实 API 不入库)」冲突,得不偿失。深度 skill 正文已含方法论密度即达标。

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
| accessibility-i18n | harmony-core | **P1** | ✅ 已完成：Accessibility Kit 三要素 + Localization Kit 格式化/RTL/自检 |
| sensors-input | harmony-system | P2 | ✅ 已完成：Sensor(加速度/陀螺仪/光线/距离/振动)+Input(键盘/鼠标/手柄)+Pen(手写笔) |
| telephony | harmony-system | P2 | ✅ 已完成：拨打电话(拨号盘/应用内)、短信(收发/验证码)、网络状态、SIM管理 |
| ipc-localization → ipc-ime | harmony-core | P2 | ✅ 已完成：IPC(RPC三步骤/远端订阅)+IME(输入法开发/自绘编辑器)；Localization 已并入 accessibility-i18n |
| assets/ 首批模板 | hvigor-build、atomic-services-and-cards | P3 | ✅ 已完成：build-profile 多模块模板；卡片样板（form_config.json + WidgetCard.ets） |

每新增 skill 同步：领域索引路由 +1 行、plugin.json、README 矩阵、2-3 条 eval（lint 强制）。

## Phase 4 — 自进化闭环常态运转（持续）

1. **知识回流**：`/harmony-feedback` → `harmony-debugging/references/common-errors.md`，**每月审视回流质量**
   - ✅ 已落地：`tools/feedback-distill.sh` 蒸馏管道（支持 --dry-run）
2. **SDK 监测**：weekly-sdk-watch 检出变更 → `diff_api.py` 生成清单 → `version-guide/references/` → 触达相关 skill 修订
3. **防退化**：CI 每次 push 跑 lint；skill 修改必须跑对应 eval
4. **季度审计**：参照 AUDIT_REPORT 流程做季度审计（首次 2026-09）
   - ✅ 已落地：`tools/quarterly-audit-checklist.md` 标准化 checklist + 判定标准

## Phase 5 — 质量打磨（当前: v0.6.0）

### 5.1 全量审计与修复 ✅（2026-06-13 完成）

- [x] 45 个深度 skill 逐条 API 正确性审查（7 个并行 agent，跨 8 个领域）
- [x] P0 修复：media-system / ipc-ime / crash-diagnostics / arkts-syntax 共 4 处虚构 API/杜撰概念
- [x] P1 修复：2d-graphics / audio-playback / arkui-window / hvigor-build / release-and-compliance 共 6 处 ACK 但不准确的 API/术语
- [x] AUDIT_REPORT v3.0 产出，含 12 条修复记录 + P0/P1/P2 待处理清单
- [x] 可执行增强：feedback-distill.sh + quarterly-audit-checklist.md

### 5.2 待推进

| # | 项目 | 状态 |
|---|------|------|
| 1 | 3d-ar skill 重写（20+ 虚构 API） | 🔴 待办 |
| 2 | ai-speech 声纹模块删除 | 🔴 待办 |
| 3 | crypto-security HUKS API 示例重写 | 🟡 待办 |
| 4 | evals 质量断言升级（10-20 条高频 skill） | 🟡 待办 |
| 5 | examples/ 示例项目（5-8 个典型场景） | 🟡 待办 |
| 6 | 6 个 command 核心逻辑抽象为独立脚本 | ⚪ 待办 |
| 7 | cloud-foundation / huawei-kits 补充 kits 字段 | ⚪ 待办 |
| 8 | camera-capture / media-processing 错误码核实 | ⚪ 待办 |

## Phase 6 — 三层分工收敛（当前: v0.6.1 起，深化纲领）

> 核心判断：本库的护城河是**「教方法」**，不是「供事实」。事实层（API 签名、枚举值、
> 性能数值）以季度速度腐烂，且本库永远拼不过 Context7 的覆盖率（20 万 snippet）。
> 越往事实堆，越是 Context7 的劣化版；越往方法收，越不可替代。

### 6.0 三层分工（锁死，不可越界）

```
skills 库   →  方法 / 不变量 / 排查顺序 / 决策树 / 反例   (慢腐烂，核心资产)
Context7    →  官方 API 事实 + URL                        (周期快照，现查)
本地 d.ts   →  项目实际锁定的真相                          (最高优先级)
```

- skill 负责"**怎么想 + 去哪查**"，具体 API 签名/数值永远从后两层现取。
- 理想态：API 季度变化时，**一行 skill 都不用改**——这才是对抗鸿蒙迭代的真正手段。
- 检索优先级冲突时：**本地 d.ts > Context7 官方快照 > 通用搜索**。

### 6.1 事实退场体检（"该往方法收"清单）

判定准则：**性能臆测数值**（无信源的 %/fps/ms/速度倍数）→ 删或改定性；
**不变量/官方硬约束**（单位换算、官方包体上限、协议字段上限）→ 保留。

| 优先级 | Skill | 病灶（性能臆测，会腐烂） | 处置 |
|--------|-------|------------------------|------|
| 🔴 P1 | ai-vision | 精度 ~98%/~92%、speed 3x、省 500ms+、下载 ~15MB、3-5 秒 | 删数值，改定性 + "实测为准" |
| 🔴 P1 | ai-speech | 精度 ~97%/~90%、~50ms 偏差、delay 200ms、2000 字上限 | 删/软化；上限有官方依据才保留并标注 |
| 🔴 P1 | ai-nlp | "80% 端侧/20% 云端、延迟降 60%" | 删比例，改定性 |
| 🔴 P1 | ai-inference | 省 40% 显存、精度损失 ≤1%（残留） | 删百分比 |
| 🔴 P1 | connectivity | 连接时延 ~20ms/~1ms | 删，改"协商更慢/直连更快" |
| 🟡 P2 | media-processing / 2d-graphics / location-map / file-system | 码率公式、帧率档、节流 300ms、分块阈值（工程经验值） | 加"约/实测为准"对冲，不必删 |

> 🟢 **保留不动**：sensors-input 纳秒单位（20ms=20000000ns，单位真相）、
> atomic-services 2MB/10MB（已标"以官方为准"）、performance-tuning taskpool 16MB、
> distributed wantParam<100KB——这些是规则不是臆测，删了反而错。

### 6.2 写作约束（新 skill / 修订时强制）

1. **禁新增**无信源的性能数值（%/fps/ms/倍数）。要量化 → 写"实测为准 + 影响因素"。
2. **具体 API 签名**优先写成查证指令（"用 harmony-docs-retriever 查 X，签名以本地 d.ts 为准"），
   而非把完整签名钉进正文——除非该 API 已 D 级（Context7）或实测核实。
3. **覆盖率不是目标**。该领域是 Context7 的战场；本库只做方法、不做百科。

## 贯穿红线

1. **任何 SKILL.md 引用的文件必须存在** —— lint check #7 拦截
2. **任何具体 API 名/文档 URL 必须经 sdk-diff 或实测核实** —— 未核实内容只能以"参考官方文档"指引存在（本仓库曾因臆造 slug 产生 49 个失效链接，教训记录于 CHANGELOG 0.2.2）
3. **禁止无信源性能数值** —— %/fps/ms/速度倍数等臆测数值不入库；量化诉求改为"实测为准 + 影响因素"。事实层退给 Context7 与本地 d.ts，skill 只留方法（见 Phase 6）
