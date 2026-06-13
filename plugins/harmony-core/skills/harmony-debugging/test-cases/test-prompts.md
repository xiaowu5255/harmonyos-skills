# 测试提示词 — harmony-debugging

> 种子用例,取自仓库级回归集 `tools/evals/evals.json`。可按需补充边界条件 / 错误处理场景。

## 基础功能测试

### 场景 1
**提示词**：我的鸿蒙应用在模拟器上正常,装到真机上提示 install failed,怎么排查?

**预期输出**：触发 harmony-debugging;按层定位到签名/安装层;给出 UDID 注册排查路径而不是泛泛建议
