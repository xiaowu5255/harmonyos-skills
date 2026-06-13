# 测试提示词 — crypto-security

> 种子用例,取自仓库级回归集 `tools/evals/evals.json`。可按需补充边界条件 / 错误处理场景。

## 基础功能测试

### 场景 1
**提示词**：鸿蒙应用里要把用户密码安全存储到本地,应该用什么方案?

**预期输出**：触发 crypto-security;推荐 HUKS 安全存储而非明文/SharedPreferences;警告 MD5/SHA256 不可用于密码存储
