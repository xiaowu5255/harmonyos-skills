# 测试提示词 — ai-nlp

> 种子用例,取自仓库级回归集 `tools/evals/evals.json`。可按需补充边界条件 / 错误处理场景。

## 基础功能测试

### 场景 1
**提示词**：鸿蒙 App 里要实现搜索功能,用户输入一个句子,怎么匹配知识库里的相关文章?

**预期输出**：触发 ai-nlp;给出 textEmbedding.getEmbedding→余弦相似度→TopK 检索方案;大规模数据建议两级检索(关键词+向量)

### 场景 2
**提示词**：一段用户填的文本,自动提取里面的手机号和地址,鸿蒙怎么做?

**预期输出**：触发 ai-nlp;给出 textProcessing.getEntity→提取 PHONE_NUMBER/LOCATION 实体类型;提示文本长度≤1000字符
