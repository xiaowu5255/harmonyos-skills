# 测试提示词 — ai-inference

> 种子用例,取自仓库级回归集 `tools/evals/evals.json`。可按需补充边界条件 / 错误处理场景。

## 基础功能测试

### 场景 1
**提示词**：想把一个 ONNX 图像分类模型部署到鸿蒙手机上端侧推理,怎么做?

**预期输出**：触发 ai-inference;给出 mindspore-lite-converter(ONNX→MS)→MindSpore Lite loadModel→predict 完整流程;CPU/NPU 选型依据

### 场景 2
**提示词**：MindSpore Lite 推理速度太慢,ImageNet 模型一张图要 500ms,怎么加速?

**预期输出**：触发 ai-inference;给出 NPU 加速/Int8 量化/warmup 预热/张量复用 优化方案;检查 target:['npu','cpu'] 自动回退
