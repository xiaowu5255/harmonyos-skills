# 测试提示词 — sharing-social

> 种子用例,取自仓库级回归集 `tools/evals/evals.json`。可按需补充边界条件 / 错误处理场景。

## 基础功能测试

### 场景 1
**提示词**：实现把一张图分享到系统分享面板,还要支持从短信里的链接直接拉起 App 指定页面

**预期输出**：触发 sharing-social;分享走 Share Kit;拉起走 App Linking/DeepLink 并给出校验配置
