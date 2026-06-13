# 测试提示词 — native-ndk

> 种子用例,取自仓库级回归集 `tools/evals/evals.json`。可按需补充边界条件 / 错误处理场景。

## 基础功能测试

### 场景 1
**提示词**：把一个 C++ 图像处理库移植到鸿蒙,在 native 回调里更新 JS 侧数据就崩溃

**预期输出**：触发 native-ndk;定位 N-API 线程约束问题;给出 napi_threadsafe_function 方案
