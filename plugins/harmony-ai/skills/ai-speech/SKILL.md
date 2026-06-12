---
name: ai-speech
description: "鸿蒙语音AI: Speech Kit 场景化语音(朗读/AI字幕)、Core Speech Kit 基础语音识别。涉及语音识别、TTS朗读、字幕生成时使用本技能。[P2 待完善]"
license: MIT
metadata:
  target-platform: "HarmonyOS 6.x / API 20-24"
requires: 0-ai-index
kits: ["@kit.SpeechKit", "@kit.CoreSpeechKit"]
---

# 语音 AI：识别、合成与字幕

> **状态：P2 待完善** —— 本文档为轻量速查占位，后续将补充完整示例、API 详解与最佳实践。

## 覆盖 Kit 说明

**Speech Kit** 提供场景化语音服务：AI 字幕可从音频流中实时生成字幕文本，支持离线引擎。**Core Speech Kit** 提供文本转语音(TextToSpeech)与语音识别(SpeechRecognizer)基础能力，支持多语种朗读、语速/音调调节，支持实时流式识别与离线短句识别，可配置语言模型适应不同场景(搜索/输入/对话)。

## 常见场景速查

| 场景 | 需关注的 Kit | 官方文档入口 |
|------|-------------|------------|
| TTS 文本朗读 | SpeechKit | [TTS 朗读指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/core-speech-introduction) |
| 实时语音识别 | CoreSpeechKit | [语音识别指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/core-speech-introduction) |
| AI 字幕生成 | SpeechKit | [AI 字幕指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/speech-production) |
| 离线语音识别 | CoreSpeechKit | [离线识别指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/core-speech-introduction) |
| 多语种朗读 | SpeechKit | [TTS 语种配置](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/core-speech-introduction) |
| 语音指令控制 | CoreSpeechKit, NaturalLanguageKit | [语音指令集成](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/speech-production) |

## P2 完善计划

以下内容将在后续版本补全：

- [ ] Speech Kit TTS 引擎的初始化、语种切换、回调管理的完整示例
- [ ] Core Speech Kit 流式识别的 Buffer 管理与结果回调解析
- [ ] AI 字幕从音频流采集到字幕文本输出的端到端流程
- [ ] 离线语音识别的模型下载、安装与切换方案
- [ ] 麦克风权限与音频焦点配合(语音识别期间与其他音频的协调)
- [ ] TTS 朗读与 AVSession 播控的集成(朗读暂停/恢复/进度)
- [ ] 用 sdk-diff 验证所有 API 名后再补回速查表
