# 测试提示词 — performance-tuning

> 种子用例,取自仓库级回归集 `tools/evals/evals.json`。可按需补充边界条件 / 错误处理场景。

## 基础功能测试

### 场景 1
**提示词**：App 冷启动要好几秒才进首页,帮我优化

**预期输出**：触发性能技能;先要求 Profiler Launch 数据定位,再按入口瘦身清单优化
