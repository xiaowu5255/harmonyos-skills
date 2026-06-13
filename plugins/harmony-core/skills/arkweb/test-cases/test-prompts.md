# 测试提示词 — arkweb

> 种子用例,取自仓库级回归集 `tools/evals/evals.json`。可按需补充边界条件 / 错误处理场景。

## 基础功能测试

### 场景 1
**提示词**：App 里嵌了 H5 页面,H5 需要拿原生的登录态,JS 和 ArkTS 怎么互相调用?

**预期输出**：触发 arkweb;给出 JS Bridge 双向通信方案(javaScriptProxy/runJavaScript);提示安全域名校验
