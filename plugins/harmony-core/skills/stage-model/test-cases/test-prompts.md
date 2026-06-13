# 测试提示词 — stage-model

> 种子用例,取自仓库级回归集 `tools/evals/evals.json`。可按需补充边界条件 / 错误处理场景。

## 基础功能测试

### 场景 1
**提示词**：UIAbility 的 onCreate 和 onWindowStageCreate 有什么区别?全局初始化代码应该放在哪里?

**预期输出**：触发 stage-model;讲清生命周期次序与职责边界;给出初始化代码归属建议
