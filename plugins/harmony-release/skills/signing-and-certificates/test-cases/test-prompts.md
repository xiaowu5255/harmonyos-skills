# 测试提示词 — signing-and-certificates

> 种子用例,取自仓库级回归集 `tools/evals/evals.json`。可按需补充边界条件 / 错误处理场景。

## 基础功能测试

### 场景 1
**提示词**：换了一台新的测试手机后 HAP 装不上了,报 signature verify 失败

**预期输出**：触发 signing 技能;第一步即核对 Profile 设备列表与新机 UDID;提醒重新生成 p7b
