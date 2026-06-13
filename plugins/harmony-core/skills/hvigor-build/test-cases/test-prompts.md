# 测试提示词 — hvigor-build

> 种子用例,取自仓库级回归集 `tools/evals/evals.json`。可按需补充边界条件 / 错误处理场景。

## 基础功能测试

### 场景 1
**提示词**：工程要拆出公共模块给两个 App 复用,HAR 和 HSP 应该怎么选?

**预期输出**：触发 hvigor-build;按共享方式/独立进程/按需加载给出 HAR vs HSP 决策依据
