---
name: ai-nlp
description: >-
  鸿蒙NLP: Natural Language Kit 分词、实体抽取(时间/地点/人名等)、
  文本向量化(嵌入)、词性标注。涉及文本分析、搜索优化、
  语义理解时使用本技能。
license: MIT
requires: 0-ai-index
kits: ["@kit.NaturalLanguageKit"]
metadata:
  target-platform: "HarmonyOS 6.x / API 20-24"
---

## Overview

鸿蒙NLP: Natural Language Kit 分词、实体抽取(时间/地点/人名等)、 文本向量化(嵌入)、词性标注。

## When to Use

- 涉及 文本分析 时
- 涉及 搜索优化 时
- 涉及 语义理解 时

# 自然语言处理：分词、实体与嵌入

## Natural Language Kit 能力矩阵

| 能力 | 功能 | 输入限制 | 语言支持 |
|------|------|---------|---------|
| 分词 | 将文本切分为最小语义单元 | ≤1000 字符 | 简体中文、繁体中文 |
| 实体抽取 | 识别时间/地点/人名/电话/邮箱/证件号/快递单号/航班号/链接/验证码 | ≤1000 字符 | 简体中文、繁体中文 |
| 词性标注 | 标注名词/动词/形容词等 | ≤1000 字符 | 简体中文 |
| 文本向量化 | 将文本转成固定维度的向量用于相似度检索 | 无硬上限 | 中文 |

**约束**：纯端侧运行，不需网络。不支持并发调用同一能力——同一个 process 里同时调两次分词会返回"系统繁忙"。

## 分词：最少代码最快出结果

```typescript
import { textProcessing } from '@kit.NaturalLanguageKit';

// 同步优先级最高——分词是毫秒级操作
let result = textProcessing.getWordSegmentation('今天天气真好', { language: 'zh' });
console.log(JSON.stringify(result));
// 输出：[{word:"今天", tag:"时间词"}, {word:"天气", tag:"名词"}, {word:"真好", tag:"形容词"}]

// 异步方式（适合批量处理）
textProcessing.getWordSegmentationAsync(text).then(result => { /* ... */ });
```

**分词粒度控制**：词粒度 vs 细粒度。`segmentationType: 'word'` 分"人工智能"，`segmentationType: 'fineGrained'` 分"人工"+"智能"——文本向量化场景用细粒度效果更好。

## 实体抽取：结构化提取关键信息

```typescript
let text = '张伟的快递SF1234567890123将在2026年6月15日送到北京市朝阳区，电话13800138000';
let entities = textProcessing.getEntity(text);

// 输出：
// { type: 'PERSON', word: '张伟', beginCharOffset: 0, endCharOffset: 2 }
// { type: 'EXPRESS_ID', word: 'SF1234567890123', beginCharOffset: 5, ... }
// { type: 'DATE_TIME', word: '2026年6月15日', ... }
// { type: 'LOCATION', word: '北京市朝阳区', ... }
// { type: 'PHONE_NUMBER', word: '13800138000', ... }
```

**支持的实体类型**：`PERSON` / `LOCATION` / `DATE_TIME` / `PHONE_NUMBER` / `EMAIL` / `URL` / `EXPRESS_ID`(快递单号) / `FLIGHT_NUMBER`(航班号) / `VERIFICATION_CODE`(验证码) / `ID_CARD_NUMBER`(证件号) / `AMOUNT`(金额)。

**实用技巧**：先分词再实体抽取——分词缩小了候选范围，实体抽取精度更高。

## 文本向量化：相似度检索的基石

```typescript
import { textEmbedding } from '@kit.NaturalLanguageKit';

// 获取句向量（async 方式——首次调用模型加载需 1-2s）
let embedding = await textEmbedding.getEmbedding('人工智能是第四次工业革命的核心驱动力');
// embedding: Float32Array(256) — 256 维稠密向量

// 计算两个句子的余弦相似度
function cosineSimilarity(a: Float32Array, b: Float32Array): number {
  let dot = 0, normA = 0, normB = 0;
  for (let i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }
  return dot / (Math.sqrt(normA) * Math.sqrt(normB));
}
```

**向量的三个用途**：
1. **语义搜索**：用户输入 → 向量化 → 与知识库中所有文本向量做余弦相似度 → TopK 返回
2. **文本聚类**：批量向量化后用 K-means 聚类，自动分组相似文章
3. **去重**：余弦相似度 > 0.95 视为重复内容

**大规模检索**：文档量 > 1 万条时，用 `@ohos.data.relationalStore` 本地向量存储，或自建粗排(关键词) + 精排(向量) 两级检索。别用 `Array.filter` 遍历全量向量——1 万条就卡。

## 端侧 NLP 与云侧大模型的混合策略

端侧 NLP 分担简单任务，云侧大模型处理复杂语义：

```
用户输入
  ├── 分词+实体抽取（端侧，0 延迟）→ 提取关键词/实体 → 结构化查询
  ├── 文本向量化（端侧）→ 本地相似度检索 → TopN 候选返回
  └── 复杂 NLU（云侧大模型）→ 意图理解 + 多轮对话
```

**收益**：多数轻量查询(关键词匹配 + 向量检索)在端侧即可完成，仅复杂语义走云端大模型——降低延迟、省流量、减少云端调用成本。端云分流比例依业务而定。

## 排查清单

1. **分词结果为空** → 输入为空字符串或仅含标点符号；检查 `language: 'zh'` 参数
2. **实体未识别** → 确认文本在 1000 字符限制内；超长文本先分段再分别抽取
3. **并发调用报"系统繁忙"** → NLP Kit 不支持同进程并发调同一能力；加互斥锁串行执行
4. **向量相似度异常（全接近 1.0）** → 向量化模型未完成加载：首次调用后等 1-2s 再调第二次
5. **短语"成都市"的实体类型不对** → 实体识别依赖上下文。单地名默认 `LOCATION`，但"成都市龙泉驿区"中"成都市"也是 `LOCATION`

> 官方文档：[Natural Language Kit](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/natural-language-kit-guide)
