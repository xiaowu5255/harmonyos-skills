# 测试提示词 — version-guide

> 种子用例,取自仓库级回归集 `tools/evals/evals.json`。可按需补充边界条件 / 错误处理场景。

## 基础功能测试

### 场景 1
**提示词**：想把工程的 compatibleSdkVersion 从 20 升到 23,要注意什么?

**预期输出**：触发版本迁移技能;给出 diff→编译→api-scan→回归→老设备验证的流程
