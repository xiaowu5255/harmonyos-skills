# 测试提示词 — camera-capture

> 种子用例,取自仓库级回归集 `tools/evals/evals.json`。可按需补充边界条件 / 错误处理场景。

## 基础功能测试

### 场景 1
**提示词**：鸿蒙自定义相机,切到后台再回来预览就冻结了,怎么修?

**预期输出**：触发 camera-capture;定位为生命周期联动问题;给出 onForeground session.start() + onBackground releaseCamera 方案

### 场景 2
**提示词**：做一个扫码功能,是直接拿相机预览自己解析还是用系统能力?

**预期输出**：触发 camera-capture;优先推荐 Scan Kit;深度控制才用 Camera Kit 会话模型
