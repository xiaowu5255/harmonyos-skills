# 测试提示词 — ai-vision

> 种子用例,取自仓库级回归集 `tools/evals/evals.json`。可按需补充边界条件 / 错误处理场景。

## 基础功能测试

### 场景 1
**提示词**：做一个身份证识别功能,OCR 取到文字后怎么提取姓名和身份证号?

**预期输出**：触发 ai-vision;Core Vision Kit OCR→TextBlock 解析 + Natural Language Kit 实体抽取(PERSON+ID_CARD_NUMBER)

### 场景 2
**提示词**：用相机实时检测画面中的人脸并标记五官位置,鸿蒙怎么做?

**预期输出**：触发 ai-vision;给出 faceDetection.init→detect→Face.landmarks(106点) 流程;提示 trackerMode 用于视频场景
