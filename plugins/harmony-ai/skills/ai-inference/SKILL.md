---
name: ai-inference
description: "鸿蒙端侧AI推理: MindSpore Lite Kit 模型加载/推理、Neural Network Runtime Kit 跨芯片推理(CANN)、Agent Framework Kit 智能体引擎。涉及AI模型部署、端侧推理、智能体集成时使用本技能。[P2 待完善]"
license: MIT
metadata:
  target-platform: "HarmonyOS 6.x / API 20-24"
requires: 0-ai-index
kits: ["@kit.MindSporeLiteKit", "@kit.NeuralNetworkRuntimeKit", "@kit.CANNKit", "@kit.AgentFrameworkKit"]
---

# 端侧 AI 推理：模型部署与智能体

> **状态：P2 待完善** —— 本文档为轻量速查占位，后续将补充完整示例、API 详解与最佳实践。

## 覆盖 Kit 说明

**MindSpore Lite Kit** 是鸿蒙官方端侧推理引擎，支持 MindIR/ONNX/TFLite 模型加载与推理，提供量化压缩、模型转换、NPU 加速等优化手段。**Neural Network Runtime Kit** 提供跨芯片 AI 推理运行时，通过统一接口调度 CPU/NPU/DSP 异构计算资源。**CANN Kit** 是昇腾 AI 处理器的计算引擎，为 NPU 推理提供算子库与图编译能力。**Agent Framework Kit** 提供智能体框架，支持工具注册、规划调度、多智能体协作。

## 常见场景速查

| 场景 | 需关注的 Kit | 官方文档入口 |
|------|-------------|------------|
| 模型推理 | MindSporeLiteKit | [模型推理指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/mindspore-lite-kit-introduction) |
| 模型量化部署 | MindSporeLiteKit | [模型量化指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/mindspore-lite-kit-introduction) |
| 异构推理 | NeuralNetworkRuntimeKit | [异构推理指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/neural-network-runtime-kit-introduction) |
| NPU 加速 | CANNKIT | [NPU 推理指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hiaifoundation-introduction) |
| 智能体构建 | AgentFrameworkKit | [智能体框架指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hmaf-introduction) |
| 多智能体协作 | AgentFrameworkKit | [多智能体协作指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hmaf-introduction) |

## P2 完善计划

以下内容将在后续版本补全：

- [ ] MindSpore Lite 模型从训练到端侧部署的完整转换流程(MindIR 生成 → 量化 → 加载)
- [ ] Neural Network Runtime 多设备(CPU/NPU/DSP)调度的配置与 fallback 策略
- [ ] CANN Kit 的自定义算子注册与 NPU 性能调优
- [ ] Agent Framework 工具注册、规划器配置、对话管理的完整示例
- [ ] 端侧推理性能基准：不同量化策略(FP16/INT8/INT4)的延迟与精度对比
- [ ] 模型安全：端侧模型加密存储与热更新分发方案
- [ ] 用 sdk-diff 验证所有 API 名后再补回速查表
