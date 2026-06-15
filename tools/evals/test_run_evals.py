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


def test_run_eval_skips_string_assertion():
    """evals.json 旧契约：quality_assertion 是字符串，run_eval 应 skip。"""
    # 通过 import run_eval 后 monkeypatch subprocess.run 来验证；但更简洁是直接验证 apply_machine_assertion 对 str 的处理
    import run_evals
    # apply_machine_assertion 不接受 str——但 run_eval 内部已 isinstance 拦截
    # 验证拦截：在 run_eval 中传入带 str quality_assertion 的 eval 不会 KeyError
    rec = {"id": 999, "skill": "test", "prompt": "x", "quality_assertion": "旧字符串断言"}
    r = run_evals.run_eval(rec, dry_run=True)
    assert r["type"] == "semantic"
    assert r["passed"] is None
    assert r["detail"] == "旧字符串断言"
