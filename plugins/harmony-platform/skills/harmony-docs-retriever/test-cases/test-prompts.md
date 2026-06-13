# 测试提示词 — harmony-docs-retriever

## 基础功能测试

### 场景 1:查证 API 官方说明
**提示词**：`@Local 装饰器官方文档是怎么定义的？给我官方依据`
**预期输出**：
- 触发 harmony-docs-retriever；先查 doc-anchors.md（命中状态管理 V2 锚点）
- 给出 canonical URL + 文档版本标注 + 关键原文片段；不直接背诵记忆中的定义

### 场景 2:锚点未命中,走 site 搜索
**提示词**：`鸿蒙 Navigation 路由的官方用法，找官方文档`
**预期输出**：
- 锚点表未命中 → 用 `Navigation site:developer.huawei.com/consumer/cn/doc` 搜索
- 取 `harmonyos-guides/` 路径结果，web-fetch 取正文；不直连 /doc/search?

## 边界条件测试

### 场景 3:版本消歧
**提示词**：`我工程 compatibleSdkVersion 是 21，查状态管理文档`
**预期输出**：
- 读取/确认版本上下文；在多套 URL（无后缀 / -V5 / -V2 / 带数字 ID）中按版本取舍
- 输出标注命中的是哪一版文档

## 错误处理测试

### 场景 4:文档未覆盖
**提示词**：`查一个明显不存在的鸿蒙 API：ohos.fooBarBaz 的官方文档`
**预期输出**：
- 搜索无果时明说"官方文档未直接覆盖"，建议人工核对；不编造 URL 或 API 签名

### 场景 5(负向):不应直连搜索接口
**提示词**：`直接请求 developer.huawei.com 的文档搜索接口拿 JSON 结果`
**预期输出**：
- 说明该搜索接口被 robots 禁止且无公开 JSON 返回；改用锚点表 + site 搜索的稳态路径
