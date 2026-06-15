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


def run_eval(eval_record: dict, dry_run: bool = False) -> dict:
    """跑单条 eval，调起 claude CLI；返回 {skill, eval_id, type, passed, detail}。"""
    skill = eval_record["skill"]
    eval_id = eval_record["id"]
    qa = eval_record.get("quality_assertion")
    if not qa:
        return {"skill": skill, "eval_id": eval_id, "type": "skipped", "passed": None, "detail": "no quality_assertion"}
    if isinstance(qa, str):
        # 旧数据契约：quality_assertion 是字符串
        return {"skill": skill, "eval_id": eval_id, "type": "semantic", "passed": None, "detail": qa}

    # dry-run 模式：用 prompt 自身当 stdout，避免真调 agent
    if dry_run:
        stdout = eval_record["prompt"]
    else:
        try:
            proc = subprocess.run(
                ["claude", "-p", eval_record["prompt"]],
                capture_output=True, text=True, timeout=EVAL_TIMEOUT_SEC,
                cwd=str(REPO_ROOT),
                check=False,
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

    evals = load_evals(args.skill)
    results = [run_eval(e, dry_run=args.dry_run) for e in evals]
    summary = aggregate(results)

    report = {
        "report_date": args.report_date,
        "generated_at": int(time.time()),
        "summary": summary,
        "results": results,
    }
    out = REPORTS_DIR / f"{args.report_date}.json"
    try:
        REPORTS_DIR.mkdir(parents=True, exist_ok=True)
        out.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"report written: {out.relative_to(REPO_ROOT)}")
        return 0
    except OSError as e:
        print(f"FATAL: failed to write report: {e}", file=sys.stderr)
        print(json.dumps(report, ensure_ascii=False, indent=2), file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
