# 测试提示词 — data-storage

> 种子用例,取自仓库级回归集 `tools/evals/evals.json`。可按需补充边界条件 / 错误处理场景。

## 基础功能测试

### 场景 1
**提示词**：App 的设置项和用户数据存哪里?本地数据库后续还要能升级表结构

**预期输出**：触发 data-storage;设置项用 Preferences;结构化数据用 RDB 并给出版本迁移方案
