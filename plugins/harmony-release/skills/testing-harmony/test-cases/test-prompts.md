# 测试提示词 — testing-harmony

> 种子用例,取自仓库级回归集 `tools/evals/evals.json`。可按需补充边界条件 / 错误处理场景。

## 基础功能测试

### 场景 1
**提示词**：给我们的鸿蒙 App 制定一套上架前的完整测试方案,要覆盖兼容性和稳定性

**预期输出**：触发 testing-harmony;按 QA 全景图分维度输出;包含云测与压力遍历;引用 qa-checklist

### 场景 2
**提示词**：用 Hypium 给这个工具类写单元测试,顺便教我为什么我的用例写了但跑不起来

**预期输出**：触发 testing-harmony;给出 Hypium 骨架;指出测试入口注册问题;不提 JUnit
