# 测试提示词 — arkts-concurrency

> 种子用例,取自仓库级回归集 `tools/evals/evals.json`。可按需补充边界条件 / 错误处理场景。

## 基础功能测试

### 场景 1
**提示词**：鸿蒙里想把图片压缩放到子线程跑,TaskPool 和 Worker 怎么选?对象传过去还报 not sendable 错误

**预期输出**：触发 arkts-concurrency;给出 TaskPool/Worker 选型依据;解释 @Sendable 约束与序列化边界
