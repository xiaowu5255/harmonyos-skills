---
name: ai-nlp
description: "鸿蒙NLP: Natural Language Kit 自然语言处理(分词/实体识别/意图理解)。涉及文本分析、语义理解时使用本技能。[P2 待完善]"
license: MIT
metadata:
  target-platform: "HarmonyOS 6.x / API 20-24"
requires: 0-ai-index
kits: [@kit.NaturalLanguageKit]
---

# 自然语言处理：分词、实体与意图

> **状态：P2 待完善** —— 本文档为轻量速查占位，后续将补充完整示例、API 详解与最佳实践。

## 覆盖 Kit 说明

**Natural Language Kit** 提供端侧自然语言处理能力：分词(`WordSegmenter`)支持多种粒度的中文/英文分词策略；词性标注(`POSTagger`)识别实词与虚词；实体识别(`EntityExtractor`)提取人名、地名、组织、时间、数量等实体；意图理解(`IntentDetector`)匹配用户输入意图类别；文本相似度(`TextEmbedding`)计算语义向量用于检索与聚类。

## 常见场景速查

| 场景 | 核心 API | 需关注的 Kit |
|------|---------|-------------|
| 中文分词 | `NaturalLanguageKit.createWordSegmenter()` | NaturalLanguageKit |
| 实体提取 | `NaturalLanguageKit.createEntityExtractor()` | NaturalLanguageKit |
| 意图识别 | `NaturalLanguageKit.createIntentDetector()` | NaturalLanguageKit |
| 文本分类 | `NaturalLanguageKit.createTextClassifier()` | NaturalLanguageKit |
| 语义相似度 | `TextEmbedding.computeSimilarity()` | NaturalLanguageKit |
| 搜索关键词提取 | 分词 + 词性过滤 + 实体加权 | NaturalLanguageKit |

## P2 完善计划

以下内容将在后续版本补全：

- [ ] 中文分词的多粒度策略选型(词粒度/字粒度/细粒度)与性能对比
- [ ] 实体识别的完整输出解析与归一化处理
- [ ] 意图检测器的自定义意图训练与注册流程
- [ ] TextEmbedding 的向量存储与检索(结合向量数据库)的应用示例
- [ ] 多 Kit 联合：语音识别 → 分词 → 实体提取 → 意图执行 的端到端流水线
- [ ] 端侧 NLP 与云侧大模型的混合推理策略
