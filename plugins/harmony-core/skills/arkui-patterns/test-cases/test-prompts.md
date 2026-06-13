# 测试提示词 — arkui-patterns

> 种子用例,取自仓库级回归集 `tools/evals/evals.json`。可按需补充边界条件 / 错误处理场景。

## 基础功能测试

### 场景 1
**提示词**：鸿蒙长列表滑动卡顿严重,几千条数据一滑就掉帧,怎么优化?

**预期输出**：触发 arkui-patterns;给出列表性能三件套(LazyForEach/cachedCount/组件复用)而非泛泛建议
