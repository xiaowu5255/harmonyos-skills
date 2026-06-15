# v0.7.0 信源质量 + 自进化硬化 — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 v0.7.0 把 evals 质量断言扩到 ≥30 条（实际 16→48）并接入 CI 轻量采集，让 v0.6.x 阶段已修复的杜撰 API 与性能臆测有可量化的防回潮手段；季度审计与 feedback-distill 走"节奏表文档化"。

**Architecture:** 只在 tooling 层 + evals 数据层叠加，不改 skill 业务内容。新增 `tools/evals/run_evals.py`（协议层脚本：调起 agent → 收 stdout → 跑正则/字符串 → 出报告）；CI 加 `evals-report` job（`continue-on-error: true` 不阻断）；报告输出 `tools/evals/reports/<sha>.json` 入 gitignore；ROADMAP 增 Phase 7；CHANGELOG 增 v0.7.0。

**Tech Stack:** Python 3.11（run_evals.py）、GitHub Actions（ci.yml）、JSON（evals.json / 报告）、Markdown（ROADMAP / CHANGELOG / ARCHITECTURE）、Bash（lint-skills.sh 软提示）。

**Spec:** `docs/superpowers/specs/2026-06-15-v070-quality-evals-design.md`

---

## File Structure

本 plan 涉及 11 个文件，全部为新增或小改动：

| # | 路径 | 动作 | 责任 |
|---|------|------|------|
| 1 | `tools/evals/run_evals.py` | 新建 | 协议层：调 agent / 收 stdout / 应用断言 / 出报告 |
| 2 | `tools/evals/reports/.gitkeep` | 新建 | 报告目录占位（报告本身 gitignore） |
| 3 | `tools/evals/reports/comment_template.md` | 新建 | PR 评论渲染模板 |
| 4 | `tools/evals/evals.json` | 修改 | +32 条 quality_assertion |
| 5 | `.github/workflows/ci.yml` | 修改 | 追加 evals-report job |
| 6 | `tools/lint-skills.sh` | 修改 | 第 12 项后追加 evals 覆盖软提示 |
| 7 | `tools/evals/test_run_evals.py` | 新建 | run_evals.py 单元测试 |
| 8 | `.gitignore` | 修改 | 加 `tools/evals/reports/*.json` |
| 9 | `ROADMAP.md` | 修改 | 新增 Phase 7 节奏表 |
| 10 | `CHANGELOG.md` | 修改 | 增 v0.7.0 条目 |
| 11 | `ARCHITECTURE.md` | 修改 | 新增"断言撰写规范"节 |

**单元测试放置**：与 run_evals.py 同目录 `tools/evals/test_run_evals.py`（仓库未建顶层 tests/，遵循现有"工具同目录测试"惯例——`arkts-syntax/scripts/` 即此模式）。

---

## Task 1: 新增 `tools/evals/run_evals.py` 协议层脚本（TDD）

**Files:**
- Create: `tools/evals/test_run_evals.py`
- Create: `tools/evals/run_evals.py`

### 1.1 写失败测试

`tools/evals/test_run_evals.py`：

```python
"""run_evals.py 协议层单元测试。"""
import json
import sys
from pathlib import Path

# 把 tools/evals/ 加入 sys.path，确保能 import run_evals
sys.path.insert(0, str(Path(__file__).parent))
import run_evals


def test_apply_machine_not_contains_pass():
    a = {"type": "machine", "check": "not_contains", "target": "stdout", "value": ["createAudioSession"]}
    assert run_evals.apply_machine_assertion(a, "我用 getSessionManager 创建会话") is True


def test_apply_machine_not_contains_fail():
    a = {"type": "machine", "check": "not_contains", "target": "stdout", "value": ["createAudioSession"]}
    assert run_evals.apply_machine_assertion(a, "我调 createAudioSession 创建会话") is False


def test_apply_machine_contains_pass():
    a = {"type": "machine", "check": "contains", "target": "stdout", "value": ["Picker", "安全控件"]}
    assert run_evals.apply_machine_assertion(a, "推荐用 Picker 安全控件") is True


def test_apply_machine_contains_fail():
    a = {"type": "machine", "check": "contains", "target": "stdout", "value": ["Picker", "安全控件"]}
    assert run_evals.apply_machine_assertion(a, "申请 READ_MEDIA 权限") is False


def test_apply_machine_regex_match():
    a = {"type": "machine", "check": "regex_match", "target": "stdout", "value": "permission.*ACL"}
    assert run_evals.apply_machine_assertion(a, "permission grant requires ACL") is True
    assert run_evals.apply_machine_assertion(a, "no match") is False


def test_semantic_returns_none():
    a = {"type": "semantic", "note": "人工 review"}
    assert run_evals.apply_machine_assertion(a, "anything") is None


def test_aggregate_summary():
    results = [
        {"skill": "a", "eval_id": 1, "type": "machine", "passed": True},
        {"skill": "a", "eval_id": 2, "type": "machine", "passed": False},
        {"skill": "b", "eval_id": 3, "type": "semantic", "passed": None},
    ]
    summary = run_evals.aggregate(results)
    assert summary["total"] == 3
    assert summary["machine_total"] == 2
    assert summary["machine_passed"] == 1
    assert summary["semantic_count"] == 1
    assert summary["by_skill"]["a"]["machine_pass"] == 1
    assert summary["by_skill"]["a"]["machine_fail"] == 1
```

### 1.2 跑测试确认失败

```bash
cd /home/xiao5/projects/harmonyos-skills && python -m pytest tools/evals/test_run_evals.py -v
```

Expected：FAIL（ModuleNotFoundError: No module named 'run_evals'）。

### 1.3 写最小实现

`tools/evals/run_evals.py`：

```python
"""v0.7.0 evals 报告协议层。

只负责：读 evals.json、跑 quality_assertion、聚合报告。
不负责：调起 agent（由调用方传 stdout 进来）、PR 评论渲染。

CLI:
    python tools/evals/run_evals.py --report-date <sha-or-date>
    python tools/evals/run_evals.py --dry-run --skill <skill-slug>
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
import time
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
EVALS_JSON = REPO_ROOT / "tools" / "evals" / "evals.json"
REPORTS_DIR = REPO_ROOT / "tools" / "evals" / "reports"
EVAL_TIMEOUT_SEC = 120


def apply_machine_assertion(assertion: dict, stdout: str) -> bool | None:
    """应用 machine 类断言；semantic 类返回 None（不自动化）。"""
    if assertion.get("type") == "semantic":
        return None
    check = assertion["check"]
    value = assertion["value"]
    if check == "not_contains":
        return all(token not in stdout for token in value)
    if check == "contains":
        return all(token in stdout for token in value)
    if check == "regex_match":
        return re.search(value, stdout) is not None
    raise ValueError(f"unknown check: {check}")


def run_eval(eval_record: dict) -> dict:
    """跑单条 eval，调起 claude CLI；返回 {skill, eval_id, type, passed, detail}。"""
    skill = eval_record["skill"]
    eval_id = eval_record["id"]
    qa = eval_record.get("quality_assertion")
    if not qa:
        return {"skill": skill, "eval_id": eval_id, "type": "skipped", "passed": None, "detail": "no quality_assertion"}

    # dry-run 模式：用 prompt 自身当 stdout，避免真调 agent
    if "--dry-run" in sys.argv:
        stdout = eval_record["prompt"]
    else:
        try:
            proc = subprocess.run(
                ["claude", "-p", eval_record["prompt"]],
                capture_output=True, text=True, timeout=EVAL_TIMEOUT_SEC,
            )
            stdout = proc.stdout
        except subprocess.TimeoutExpired:
            return {"skill": skill, "eval_id": eval_id, "type": qa.get("type", "?"),
                    "passed": None, "detail": "timeout"}
        except FileNotFoundError:
            return {"skill": skill, "eval_id": eval_id, "type": qa.get("type", "?"),
                    "passed": None, "detail": "claude CLI not available"}

    passed = apply_machine_assertion(qa, stdout)
    return {"skill": skill, "eval_id": eval_id, "type": qa.get("type", "?"),
            "passed": passed, "detail": qa.get("note", "") if passed is None else ""}


def aggregate(results: list[dict]) -> dict:
    """聚合：总数 / machine 通过率 / 按 skill 分组。"""
    machine = [r for r in results if r.get("type") == "machine"]
    semantic = [r for r in results if r.get("type") == "semantic"]
    by_skill: dict[str, dict] = {}
    for r in results:
        s = r["skill"]
        by_skill.setdefault(s, {"machine_total": 0, "machine_pass": 0, "machine_fail": 0, "semantic_count": 0})
        if r.get("type") == "machine":
            by_skill[s]["machine_total"] += 1
            if r["passed"] is True:
                by_skill[s]["machine_pass"] += 1
            elif r["passed"] is False:
                by_skill[s]["machine_fail"] += 1
        elif r.get("type") == "semantic":
            by_skill[s]["semantic_count"] += 1
    return {
        "total": len(results),
        "machine_total": len(machine),
        "machine_passed": sum(1 for r in machine if r["passed"] is True),
        "semantic_count": len(semantic),
        "by_skill": by_skill,
    }


def load_evals(skill_filter: str | None = None) -> list[dict]:
    data = json.loads(EVALS_JSON.read_text(encoding="utf-8"))
    evals = data["evals"]
    if skill_filter:
        evals = [e for e in evals if e.get("skill") == skill_filter]
    return evals


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--report-date", required=True, help="输出文件名（用 sha 或日期）")
    ap.add_argument("--dry-run", action="store_true", help="不真调 agent，用 prompt 当 stdout")
    ap.add_argument("--skill", default=None, help="只跑该 skill 的 eval")
    args = ap.parse_args()

    REPORTS_DIR.mkdir(parents=True, exist_ok=True)
    evals = load_evals(args.skill)
    results = [run_eval(e) for e in evals]
    summary = aggregate(results)

    report = {
        "report_date": args.report_date,
        "generated_at": int(time.time()),
        "summary": summary,
        "results": results,
    }
    out = REPORTS_DIR / f"{args.report_date}.json"
    out.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"report written: {out.relative_to(REPO_ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
```

### 1.4 跑测试确认通过

```bash
cd /home/xiao5/projects/harmonyos-skills && python -m pytest tools/evals/test_run_evals.py -v
```

Expected：7 passed。

### 1.5 提交

```bash
cd /home/xiao5/projects/harmonyos-skills
git add tools/evals/run_evals.py tools/evals/test_run_evals.py
git commit -m "feat(tools): 新增 evals 报告协议层 run_evals.py (v0.7.0 Task 1)

- apply_machine_assertion: not_contains / contains / regex_match
- run_eval: 调起 claude CLI（dry-run 模式用 prompt 当 stdout）
- aggregate: 按 skill 分组 + machine 通过率统计
- CLI: --report-date / --dry-run / --skill
- 单条 120s 超时；claude CLI 缺失降级而非崩溃

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 2: 报告目录占位 + PR 评论模板

**Files:**
- Create: `tools/evals/reports/.gitkeep`
- Create: `tools/evals/reports/comment_template.md`

### 2.1 建目录与 .gitkeep

```bash
mkdir -p /home/xiao5/projects/harmonyos-skills/tools/evals/reports
touch /home/xiao5/projects/harmonyos-skills/tools/evals/reports/.gitkeep
```

### 2.2 写 PR 评论模板

`tools/evals/reports/comment_template.md`：

```markdown
## 📊 Evals 报告（v0.7.0 自进化硬化）

**报告日期**：{{ report_date }}  
**总条数**：{{ summary.total }}  
**Machine 通过率**：{{ summary.machine_passed }} / {{ summary.machine_total }}  
**Semantic 等待人工 review**：{{ summary.semantic_count }}

### 按 Skill 趋势

| Skill | Machine 总 | 通过 | 失败 | 待人工 |
|-------|-----------|------|------|--------|
{%- for skill, s in summary.by_skill.items() %}
| {{ skill }} | {{ s.machine_total }} | {{ s.machine_pass }} | {{ s.machine_fail }} | {{ s.semantic_count }} |
{%- endfor %}

> 📈 与上一次报告对比：{{ trend_note }}  
> 🔍 报告原文：`tools/evals/reports/{{ report_date }}.json`（CI artifact）  
> ⚠️ 本 job 默认 `continue-on-error: true`，不阻断合并
```

### 2.3 提交

```bash
cd /home/xiao5/projects/harmonyos-skills
git add tools/evals/reports/.gitkeep tools/evals/reports/comment_template.md
git commit -m "feat(tools): evals 报告目录占位 + PR 评论模板 (v0.7.0 Task 2)

- reports/ 目录入 git（.gitkeep）
- comment_template.md 给 CI 渲染用
- 报告本体 *.json 在 Task 7 加 gitignore

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 3: 扩展 `tools/evals/evals.json` —— 8 高优 skill × 4 断言 = +32 条

**Files:**
- Modify: `tools/evals/evals.json`

本任务为**纯数据增改**，不写新代码。每个 skill 增 4 条 quality_assertion（3 machine + 1 semantic）。先看 evals.json 末尾，在最后一个 eval 后追加新条目。

### 3.1 在文件末尾追加 32 条新 eval

读 `tools/evals/evals.json` 找到最后一个 `}` 的位置（id=72 附近），在该 `]` 前追加以下 32 条：

```json
    {
      "id": 73,
      "skill": "arkts-syntax",
      "prompt": "我想在鸿蒙页面里用解构赋值给一个对象初始化,这样写能编译过吗?",
      "expected_output": "触发 arkts-syntax;明确解构为错误级禁止;给出替代写法",
      "quality_assertion": {
        "type": "machine",
        "check": "not_contains",
        "target": "stdout",
        "value": ["markContentDirty"]
      }
    },
    {
      "id": 74,
      "skill": "arkts-syntax",
      "prompt": "鸿蒙里有 @Styles 这个装饰器吗?和 Vue 的 scoped style 比有什么区别?",
      "expected_output": "触发 arkts-syntax;指出 @Styles/@Extend 已废弃,推荐 AttributeModifier",
      "quality_assertion": {
        "type": "machine",
        "check": "not_contains",
        "target": "stdout",
        "value": ["@Styles", "@Extend"]
      }
    },
    {
      "id": 75,
      "skill": "arkts-syntax",
      "prompt": "我在 TaskPool 里传一个普通对象到子任务,提示 can't sendable,怎么处理?",
      "expected_output": "触发 arkts-syntax 并联;指出需 @Sendable 或用 Worker",
      "quality_assertion": {
        "type": "machine",
        "check": "contains",
        "target": "stdout",
        "value": ["@Sendable", "TaskPool"]
      }
    },
    {
      "id": 76,
      "skill": "arkts-syntax",
      "prompt": "鸿蒙里能 const {a, b} = obj 这么解构吗?",
      "expected_output": "触发 arkts-syntax;ArkTS 不允许解构赋值的描述必须出现",
      "quality_assertion": {
        "type": "semantic",
        "note": "维护者必读:输出必须显式说明 ArkTS 不允许解构赋值,不能含糊带过"
      }
    },
    {
      "id": 77,
      "skill": "arkui-patterns",
      "prompt": "鸿蒙里 LazyForEach 和 if 一起用报错,怎么办?",
      "expected_output": "触发 arkui-patterns;不要把 if 嵌进 LazyForEach 内部",
      "quality_assertion": {
        "type": "machine",
        "check": "contains",
        "target": "stdout",
        "value": ["LazyForEach", "if"]
      }
    },
    {
      "id": 78,
      "skill": "arkui-patterns",
      "prompt": "长列表滑动掉帧,怎么系统性优化?",
      "expected_output": "触发 arkui-patterns;列出三/四件套(缓存项布局/组件复用/分帧加载/freezeWhenInactive)",
      "quality_assertion": {
        "type": "machine",
        "check": "contains",
        "target": "stdout",
        "value": ["reuseId", "cachedCount", "LazyForEach"]
      }
    },
    {
      "id": 79,
      "skill": "arkui-patterns",
      "prompt": "Navigation 跳转和 router 跳转哪个好?",
      "expected_output": "触发 arkui-patterns;推荐 Navigation(router 已是历史)",
      "quality_assertion": {
        "type": "machine",
        "check": "not_contains",
        "target": "stdout",
        "value": ["router.pushUrl（?!\b.*deprecated）"]
      }
    },
    {
      "id": 80,
      "skill": "arkui-patterns",
      "prompt": "鸿蒙里能做自定义动画吗?",
      "expected_output": "触发 arkui-patterns;提及 animateTo/显式动画/属性动画",
      "quality_assertion": {
        "type": "semantic",
        "note": "维护者必读:必须给出动画选型决策(animateTo/属性动画/转场动画),不能只说用 animation"
      }
    },
    {
      "id": 81,
      "skill": "stage-model",
      "prompt": "UIAbility 的 onCreate 和 onWindowStageCreate 区别?",
      "expected_output": "触发 stage-model;区分 UIAbility 生命周期与 WindowStage 生命周期",
      "quality_assertion": {
        "type": "machine",
        "check": "contains",
        "target": "stdout",
        "value": ["onCreate", "onWindowStageCreate"]
      }
    },
    {
      "id": 82,
      "skill": "stage-model",
      "prompt": "应用被外部拉起多次,Want 怎么读?",
      "expected_output": "触发 stage-model;onNewWant + want.parameters 必现",
      "quality_assertion": {
        "type": "machine",
        "check": "contains",
        "target": "stdout",
        "value": ["onNewWant", "want"]
      }
    },
    {
      "id": 83,
      "skill": "stage-model",
      "prompt": "module.json5 里 abilities 字段怎么写?",
      "expected_output": "触发 stage-model;指出 module.json5 + UIAbility 配置",
      "quality_assertion": {
        "type": "machine",
        "check": "contains",
        "target": "stdout",
        "value": ["module.json5", "abilities"]
      }
    },
    {
      "id": 84,
      "skill": "stage-model",
      "prompt": "怎么从我的应用跳到系统设置页?",
      "expected_output": "触发 stage-model;startAbility + 设置页 Want 必现",
      "quality_assertion": {
        "type": "semantic",
        "note": "维护者必读:必须显式给出 startAbility 跳设置页的 action + entity 写法,不能只说 openLink"
      }
    },
    {
      "id": 85,
      "skill": "security-permissions",
      "prompt": "用户选一张照片上传,需要什么权限?",
      "expected_output": "触发 security-permissions;PhotoViewPicker 免权限",
      "quality_assertion": {
        "type": "machine",
        "check": "contains",
        "target": "stdout",
        "value": ["Picker", "安全控件"]
      }
    },
    {
      "id": 86,
      "skill": "security-permissions",
      "prompt": "我要申请相机权限直接拍,要不要先想想?",
      "expected_output": "触发 security-permissions;提到 Picker 优先",
      "quality_assertion": {
        "type": "machine",
        "check": "regex_match",
        "target": "stdout",
        "value": "permission.*ACL"
      }
    },
    {
      "id": 87,
      "skill": "security-permissions",
      "prompt": "READ_MEDIA 申请被拒了,怎么办?",
      "expected_output": "触发 security-permissions;建议改用 PhotoViewPicker",
      "quality_assertion": {
        "type": "machine",
        "check": "not_contains",
        "target": "stdout",
        "value": ["直接申请 READ_MEDIA"]
      }
    },
    {
      "id": 88,
      "skill": "security-permissions",
      "prompt": "应用启动时一堆权限请求,合规怎么过?",
      "expected_output": "触发 security-permissions;按需申请 + 用途说明",
      "quality_assertion": {
        "type": "semantic",
        "note": "维护者必读:必须显式给出 Picker 优先于权限申请的判断逻辑,不能只列权限清单"
      }
    },
    {
      "id": 89,
      "skill": "network-requests",
      "prompt": "鸿蒙里怎么发 HTTPS 请求?",
      "expected_output": "触发 network-requests;http.createHttp + RequestOptions",
      "quality_assertion": {
        "type": "machine",
        "check": "contains",
        "target": "stdout",
        "value": ["http.createHttp", "RequestOptions"]
      }
    },
    {
      "id": 90,
      "skill": "network-requests",
      "prompt": "WebSocket 断了怎么重连?",
      "expected_output": "触发 network-requests;指数退避 + 状态机",
      "quality_assertion": {
        "type": "machine",
        "check": "contains",
        "target": "stdout",
        "value": ["WebSocket", "on"]
      }
    },
    {
      "id": 91,
      "skill": "network-requests",
      "prompt": "弱网下大文件上传失败?",
      "expected_output": "触发 network-requests;分块 + 重试 + 断点续传",
      "quality_assertion": {
        "type": "machine",
        "check": "not_contains",
        "target": "stdout",
        "value": ["一口气传完"]
      }
    },
    {
      "id": 92,
      "skill": "network-requests",
      "prompt": "鸿蒙里 Socket 编程怎么搞?",
      "expected_output": "触发 network-requests;socket.createTCPSocket 必现",
      "quality_assertion": {
        "type": "semantic",
        "note": "维护者必读:必须区分 TCP/UDP 选型并说明线程模型,不能只给 createTCPSocket 一句"
      }
    },
    {
      "id": 93,
      "skill": "audio-playback",
      "prompt": "鸿蒙里怎么播放网络音频?",
      "expected_output": "触发 audio-playback;AVPlayer + url",
      "quality_assertion": {
        "type": "machine",
        "check": "not_contains",
        "target": "stdout",
        "value": ["createAudioSession"]
      }
    },
    {
      "id": 94,
      "skill": "audio-playback",
      "prompt": "音频焦点怎么管理?多个音频同时播放谁优先?",
      "expected_output": "触发 audio-playback;getSessionManager + activateAudioSession",
      "quality_assertion": {
        "type": "machine",
        "check": "contains",
        "target": "stdout",
        "value": ["getSessionManager", "activateAudioSession"]
      }
    },
    {
      "id": 95,
      "skill": "audio-playback",
      "prompt": "鸿蒙支持 MIDI 设备吗?怎么用?",
      "expected_output": "触发 audio-playback;MIDI 是 native C-API",
      "quality_assertion": {
        "type": "machine",
        "check": "not_contains",
        "target": "stdout",
        "value": ["MIDI.*ArkTS", "midi.createMIDIDevice"]
      }
    },
    {
      "id": 96,
      "skill": "audio-playback",
      "prompt": "音频播放怎么监听耳机拔出?",
      "expected_output": "触发 audio-playback;routingManager.on deviceChange",
      "quality_assertion": {
        "type": "semantic",
        "note": "维护者必读:必须显式给出 routingManager.on('deviceChange', DeviceFlag, cb) 而非 audioManager.on"
      }
    },
    {
      "id": 97,
      "skill": "media-system",
      "prompt": "锁屏播控怎么做?",
      "expected_output": "触发 media-system;AVSession + Controller",
      "quality_assertion": {
        "type": "machine",
        "check": "contains",
        "target": "stdout",
        "value": ["AVSession", "Controller"]
      }
    },
    {
      "id": 98,
      "skill": "media-system",
      "prompt": "鸿蒙里扫码用什么 Kit?",
      "expected_output": "触发 media-system;Scan Kit + customScan.init",
      "quality_assertion": {
        "type": "machine",
        "check": "not_contains",
        "target": "stdout",
        "value": ["CustomScanView"]
      }
    },
    {
      "id": 99,
      "skill": "media-system",
      "prompt": "DRM 内容保护怎么接?",
      "expected_output": "触发 media-system;DRM Kit + MediaKeySession",
      "quality_assertion": {
        "type": "machine",
        "check": "contains",
        "target": "stdout",
        "value": ["DRM", "MediaKeySession"]
      }
    },
    {
      "id": 100,
      "skill": "media-system",
      "prompt": "怎么自定义扫码界面?",
      "expected_output": "触发 media-system;customScan.init(ViewControl) + scanTypes",
      "quality_assertion": {
        "type": "semantic",
        "note": "维护者必读:必须显式给出 customScan.init + start + scanTypes 三个调用,不能只说 Scan Kit"
      }
    },
    {
      "id": 101,
      "skill": "ai-inference",
      "prompt": "MindSpore Lite 推理在鸿蒙上怎么用 NPU 加速?",
      "expected_output": "触发 ai-inference;context.target = ['nnrt'],KIRIN_NPU 保留未支持",
      "quality_assertion": {
        "type": "machine",
        "check": "contains",
        "target": "stdout",
        "value": ["nnrt", "context"]
      }
    },
    {
      "id": 102,
      "skill": "ai-inference",
      "prompt": "模型加载很慢,要不要量化?",
      "expected_output": "触发 ai-inference;INT8 量化 + ms 工具链",
      "quality_assertion": {
        "type": "machine",
        "check": "not_contains",
        "target": "stdout",
        "value": ["5-15 fps", "30-60 fps", "省 40% 显存"]
      }
    },
    {
      "id": 103,
      "skill": "ai-inference",
      "prompt": "ONNX 模型怎么转 MindSpore?",
      "expected_output": "触发 ai-inference;onnx→ms + 量化 + NPU 适配三板斧",
      "quality_assertion": {
        "type": "machine",
        "check": "contains",
        "target": "stdout",
        "value": ["ONNX", "convert"]
      }
    },
    {
      "id": 104,
      "skill": "ai-inference",
      "prompt": "端侧推理和云侧推理怎么选?",
      "expected_output": "触发 ai-inference;给端云分工决策树",
      "quality_assertion": {
        "type": "semantic",
        "note": "维护者必读:必须给出端侧 vs 云侧的选型维度(隐私/延迟/算力/费用),不能只列比例"
      }
    }
```

### 3.2 验证 JSON 合法

```bash
cd /home/xiao5/projects/harmonyos-skills && python -c "import json; d=json.load(open('tools/evals/evals.json')); print(len(d['evals']), 'evals'); print('quality_assertion count:', sum(1 for e in d['evals'] if 'quality_assertion' in e))"
```

Expected：`104 evals` / `quality_assertion count: 48`（原 16 + 新 32）。

### 3.3 跑 lint 第 9 项确认 JSON 严格解析通过

```bash
cd /home/xiao5/projects/harmonyos-skills && bash tools/lint-skills.sh 2>&1 | tail -30
```

Expected：12 PASS / 0 FAIL。

### 3.4 提交

```bash
cd /home/xiao5/projects/harmonyos-skills
git add tools/evals/evals.json
git commit -m "feat(evals): 8 高优 skill 补 32 条 quality_assertion (v0.7.0 Task 3)

arkts-syntax/arkui-patterns/stage-model/security-permissions/
network-requests/audio-playback/media-system/ai-inference 各 +4 条(3 机 1 语)

质量断言 16→48（机器可判定 24，semantic 24），lint 12 PASS 不退步。

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 4: CI 加 `evals-report` job

**Files:**
- Modify: `.github/workflows/ci.yml`

### 4.1 读 ci.yml 现状

（已读取，仅一个 lint job 15 行）

### 4.2 替换文件内容

替换 `.github/workflows/ci.yml`：

```yaml
name: CI

on:
  push:
    branches: [master, main]
  pull_request:

jobs:
  lint:
    name: 技能一致性校验
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run lint-skills
        run: bash tools/lint-skills.sh

  evals-report:
    name: Evals 报告（v0.7.0 轻量采集）
    runs-on: ubuntu-latest
    needs: lint
    if: github.event_name == 'pull_request'
    continue-on-error: true
    permissions:
      contents: read
      pull-requests: write
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: '3.11'
      - name: 跑 evals 报告
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          python tools/evals/run_evals.py \
            --report-date "${{ github.event.pull_request.head.sha }}"
      - name: 上传报告
        uses: actions/upload-artifact@v4
        with:
          name: evals-report
          path: tools/evals/reports/
      - name: PR 评论
        if: hashFiles('tools/evals/reports/${{ github.event.pull_request.head.sha }}.json') != ''
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const sha = context.payload.pull_request.head.sha;
            const path = `tools/evals/reports/${sha}.json`;
            const r = JSON.parse(fs.readFileSync(path, 'utf8'));
            const s = r.summary;
            const lines = [
              '## 📊 Evals 报告（v0.7.0）',
              `**报告 sha**: \`${sha}\`  `,
              `**总条数**: ${s.total}  `,
              `**Machine 通过率**: ${s.machine_passed} / ${s.machine_total}  `,
              `**Semantic 等待人工 review**: ${s.semantic_count}`,
              '',
              '### 按 Skill',
              '',
              '| Skill | Machine 总 | 通过 | 失败 | 待人工 |',
              '|-------|-----------|------|------|--------|',
            ];
            for (const [k, v] of Object.entries(s.by_skill)) {
              lines.push(`| ${k} | ${v.machine_total} | ${v.machine_pass} | ${v.machine_fail} | ${v.semantic_count} |`);
            }
            lines.push('', '> ⚠️ 本 job 默认 `continue-on-error: true`，不阻断合并');
            await github.rest.issues.createComment({
              owner: context.repo.owner, repo: context.repo.repo,
              issue_number: context.issue.number,
              body: lines.join('\n'),
            });
```

### 4.3 提交

```bash
cd /home/xiao5/projects/harmonyos-skills
git add .github/workflows/ci.yml
git commit -m "ci: 新增 evals-report job (v0.7.0 Task 4)

- 依赖 lint，仅 PR 触发
- continue-on-error: true 不阻断
- 复用 ANTHROPIC_API_KEY secret
- 报告上传为 artifact + 自动 PR 评论趋势表

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 5: `tools/lint-skills.sh` 追加 evals 覆盖软提示

**Files:**
- Modify: `tools/lint-skills.sh`

### 5.1 在文件末尾追加节 13

在 `tools/lint-skills.sh` 末尾（最后一个 `check 0` 之后、可能的 `exit` 之前）追加：

```bash
# ── 13. 高优 skill evals 覆盖软提示（v0.7.0 引入）──
section "13. 8 高优 skill quality_assertion 覆盖（软提示，不拦截）"
declare -A priority_skills=(
  [arkts-syntax]=4 [arkui-patterns]=4 [stage-model]=4
  [security-permissions]=4 [network-requests]=4
  [audio-playback]=4 [media-system]=4 [ai-inference]=4
)
for skill in "${!priority_skills[@]}"; do
  target=${priority_skills[$skill]}
  count=$(python -c "
import json
d = json.load(open('$ROOT/tools/evals/evals.json'))
print(sum(1 for e in d['evals']
          if e.get('skill') == '$skill'
          and 'quality_assertion' in e))
")
  if [ "$count" -ge "$target" ]; then
    check 0 "$skill: $count / $target quality_assertion"
  else
    check 0 "$skill: $count / $target quality_assertion（建议补足，非阻断）"
  fi
done
```

### 5.2 跑 lint 确认不退步

```bash
cd /home/xiao5/projects/harmonyos-skills && bash tools/lint-skills.sh 2>&1 | tail -30
```

Expected：13 sections / 仍然 0 FAIL（13 项全部 OK，缺的会显示"建议补足"但不计数 FAIL）。

### 5.3 提交

```bash
cd /home/xiao5/projects/harmonyos-skills
git add tools/lint-skills.sh
git commit -m "feat(lint): 第 13 项 8 高优 skill evals 覆盖软提示 (v0.7.0 Task 5)

- 遍历 priority_skills 字典读 evals.json 计数
- 全部 OK 计 PASS；不足显示提示但仍 PASS（不阻断）
- 12→13 sections，FAIL 仍 0

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 6: ROADMAP 新增 Phase 7

**Files:**
- Modify: `ROADMAP.md`

### 6.1 在文件末尾追加 Phase 7

读 `ROADMAP.md` 末尾（在最后一段"贯穿红线"之后）追加：

```markdown

## Phase 7 — 自进化主动脉节奏化（v0.7.0 引入，v0.7.1+ 首跑）

### 7.0 节奏表

| 主动脉 | 频率 | 责任人 | 入口 | 首跑 |
|--------|------|--------|------|------|
| 季度审计 | 每季度 | 维护者 | `tools/quarterly-audit-checklist.md` | 2026-09 |
| feedback-distill | 每月 | 维护者 | `tools/feedback-distill.sh` | 2026-07 |
| weekly-sdk-watch | 每周 | 自动化 | `.github/workflows/weekly-sdk-watch.yml` | 已跑 |
| CI evals-report | 每次 PR | 自动化 | `.github/workflows/ci.yml` (evals-report job) | v0.7.0 |

### 7.1 季度审计判定标准

参照 AUDIT_REPORT v3.0 流程，输出"通过 / 有 P0 修复项 / 有 P1 修复项 / 有 P2 修复项"四级结论；P0 必须当版本修复。

### 7.2 feedback-distill 判定标准

输出"新增 N 条 / 合并入 X skill / 拒收 M 条"三栏。**拒收必须记录原因**，归档 6 个月。

### 7.3 CI evals-report 判定标准

- `machine` 类断言：通过率趋势（与上一次报告对比）
- `semantic` 类断言：维护者人工 review（PR 评论列出待审条目）
- 30 天观察期：误报率 > 30% 时可一键 disable（仓库 Settings → Actions）
```

### 7.0 节奏表 4 行 + 7.1/7.2/7.3 三节判据，commit

```bash
cd /home/xiao5/projects/harmonyos-skills
git add ROADMAP.md
git commit -m "docs(roadmap): 新增 Phase 7 自进化主动脉节奏化 (v0.7.0 Task 6)

- 7.0 节奏表：4 条主动脉 × 频率 × 责任人 × 入口 × 首跑日期
- 7.1 季度审计判定标准（四级结论）
- 7.2 feedback-distill 判定标准（三栏+拒收归档）
- 7.3 CI evals-report 判定标准（machine 趋势 + semantic 人工 + 30 天观察期）

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 7: CHANGELOG 增 v0.7.0 条目 + .gitignore 加 reports/*.json

**Files:**
- Modify: `CHANGELOG.md`
- Modify: `.gitignore`

### 7.1 CHANGELOG.md 顶部追加

在 `[0.6.2] - 2026-06-15` 之前追加：

```markdown
## [0.7.0] - 待发布

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
- `tools/evals/test_run_evals.py`（7 个单元测试覆盖）
- `tools/lint-skills.sh` 第 13 项：高优 skill evals 覆盖软提示（不阻断）
- `ARCHITECTURE.md` 新增"断言撰写规范"节

**回归**
- lint 13 PASS / 0 FAIL；frontmatter 53 skill / 0 CRITICAL / 0 WARNING
- evals 72→104（含 32 machine 断言 + 0 semantic 新增沿用旧约定）
- 整体新增 < 800 行（不含 evals 文本与 spec）

```

### 7.2 .gitignore 追加

若 `.gitignore` 不存在则新建；存在则在末尾追加：

```
# v0.7.0 evals 报告输出（仅保留 .gitkeep）
tools/evals/reports/*.json
```

### 7.3 提交

```bash
cd /home/xiao5/projects/harmonyos-skills
git add CHANGELOG.md .gitignore
git commit -m "docs(changelog): v0.7.0 条目 + .gitignore evals 报告 (v0.7.0 Task 7)

- CHANGELOG 顶部新增 v0.7.0 段（信源质量 + 自进化硬化）
- .gitignore 加 tools/evals/reports/*.json（保留 .gitkeep）

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 8: ARCHITECTURE.md 新增"断言撰写规范"节

**Files:**
- Modify: `ARCHITECTURE.md`

### 8.1 读 ARCHITECTURE.md 末尾位置

确认 ARCHITECTURE.md 现有结构（用 `head -50` 探查），在文件末尾追加新节。

### 8.2 追加新节

```markdown

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
```

### 8.3 提交

```bash
cd /home/xiao5/projects/harmonyos-skills
git add ARCHITECTURE.md
git commit -m "docs(arch): 新增 断言撰写规范 节 (v0.7.0 Task 8)

- 6 条规范：可追溯 / 可判定 / 数量上限 / 命名 / 误报转 semantic / 撰写模板
- 与 ROADMAP 6.1/5.2 修复记录挂钩，确保黑名单有据

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 9: 端到端验收

**Files:** 无修改（验收用）

### 9.1 跑全套 lint

```bash
cd /home/xiao5/projects/harmonyos-skills && bash tools/lint-skills.sh 2>&1 | tail -20
```

Expected：13 PASS / 0 FAIL。

### 9.2 跑 run_evals.py 单元测试

```bash
cd /home/xiao5/projects/harmonyos-skills && python -m pytest tools/evals/test_run_evals.py -v
```

Expected：7 passed。

### 9.3 dry-run 全量

```bash
cd /home/xiao5/projects/harmonyos-skills && python tools/evals/run_evals.py --report-date dryrun-$(date +%Y%m%d) --dry-run 2>&1 | tail -5
```

Expected：报告写入 `tools/evals/reports/dryrun-YYYYMMDD.json`。

### 9.4 dry-run 单 skill

```bash
cd /home/xiao5/projects/harmonyos-skills && python tools/evals/run_evals.py --report-date single-test --dry-run --skill security-permissions 2>&1 | tail -5
```

Expected：报告写入 `tools/evals/reports/single-test.json`，仅含 security-permissions 的 4 条新断言。

### 9.5 报告内容 spot check

```bash
cd /home/xiao5/projects/harmonyos-skills && python -c "
import json
r = json.load(open('tools/evals/reports/single-test.json'))
print('summary:', json.dumps(r['summary'], ensure_ascii=False, indent=2))
print('result count:', len(r['results']))
for x in r['results']:
    print(' -', x['skill'], x['eval_id'], x['type'], 'passed=' + str(x['passed']))
"
```

Expected：4 条 security-permissions 结果，每条 `type=machine`，passed 为 True/False 合理（dry-run 用 prompt 当 stdout，contains 类可能 True、not_contains 类可能 False 是预期）。

### 9.6 清理 dry-run 报告（不入版本控制）

```bash
rm /home/xiao5/projects/harmonyos-skills/tools/evals/reports/dryrun-*.json
rm /home/xiao5/projects/harmonyos-skills/tools/evals/reports/single-test.json
git -C /home/xiao5/projects/harmonyos-skills status --short
```

Expected：仅 `README.md`、`.omc/`、`HERMES.md` 在 untracked / modified（既有未提交项），本 plan 9 个 commit 全部 clean。

### 9.7 行数审计

```bash
cd /home/xiao5/projects/harmonyos-skills && git diff master~9 --stat
```

Expected：总变更 < 800 行（不含 evals 文本与 spec）。

### 9.8 最终提交

```bash
cd /home/xiao5/projects/harmonyos-skills
git tag v0.7.0-rc1
git log --oneline -10
```

Expected：9 个 feat/docs/ci commit + tag v0.7.0-rc1。

---

## Self-Review（写完 plan 后自检）

- [x] **Spec 覆盖**：spec 9 个验收 checklist → 全部有 task 对应（1→协议层、2→目录/模板、3→evals 数据、4→CI、5→lint、6→ROADMAP、7→CHANGELOG+gitignore、8→ARCHITECTURE、9→E2E 验收）
- [x] **占位扫描**：0 命中
- [x] **类型一致**：`apply_machine_assertion` / `run_eval` / `aggregate` / `load_evals` 在 Task 1 定义，Task 9 spot check 调用一致
- [x] **路径精确**：所有 `git add` / `pytest` / `python tools/evals/...` 路径与 spec §3.1 表一致
- [x] **可执行**：每条命令可在仓库根 `/home/xiao5/projects/harmonyos-skills` 下直接跑

---

## Handoff

Plan 已落 `docs/superpowers/plans/2026-06-15-v070-quality-evals.md`，9 个 task 全部带 TDD/命令/提交。

**两种执行方式**：

1. **Subagent-Driven（推荐）** — 每个 task 派一个 fresh subagent，做完一个 review 一个，迭代快
2. **Inline Execution** — 当前会话批量执行，checkpoint 让你 review

请告知选哪种。
