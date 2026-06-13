---
name: harmony-docs-retriever
description: >-
  鸿蒙官方文档检索层:按关键词定位 developer.huawei.com 官方文档页并取回正文证据,只检索不写码。
  涉及"查官方文档、验证某 API/装饰器官方说明、某 Kit 官方用法、确认接口在哪个版本引入、
  这个错误码官方怎么解释"时使用。本技能是证据来源层,代码由具体开发技能完成。
license: MIT
requires: harmony-index
metadata:
  target-platform: "HarmonyOS 6.x / API 20-24"
  layer: retrieval
---

# 鸿蒙官方文档检索

## 定位:检索层,不是开发层

本技能只做一件事——**把"我需要官方依据"变成"这是官方原文 + URL"**。它不生成业务代码;
拿到证据后由 `arkts-syntax`、`arkui-patterns`、各 Kit 技能等开发层技能完成编码。
这种"检索/开发分层"避免开发技能凭记忆编造 API(鸿蒙 API 季度级变化,记忆不可靠)。

## 第零条原则:官方文档搜索框不能直连

`developer.huawei.com/consumer/cn/doc/` 是一个 Vue 单页应用,**它的搜索接口
`/consumer/cn/doc/search?*` 被 robots.txt 明确禁止抓取**,且任意 `/doc/*` 路径都只返回
1.6KB 空壳(结果靠未公开的 XHR + JS 渲染)。所以**禁止**把搜索框 URL 当 API 直连——
不稳定、违规、会被风控。改走下面的稳态两步法。

## 稳态检索工作流

### 步骤 1 —— 先查本地锚点表(零搜索,精度最高)

读 `references/doc-anchors.md`,这是一张"常见主题 → 已核实稳定 URL"的映射表。
命中即拿到 canonical URL,直接跳步骤 3。锚点表里的 URL 都经 `scripts/check-doc-urls.sh`
校验过 200,是最可靠的入口。

### 步骤 2 —— 未命中则用 site 限定搜索定位 URL

用通用搜索引擎(WebSearch 工具),查询拼成:

```
<关键词> site:developer.huawei.com/consumer/cn/doc
```

robots.txt 只禁 `/doc/search?`,**文档页本身允许被搜索引擎索引**,所以 site 限定搜索能
稳定返回 canonical 文档 URL(slug 形如 `harmonyos-guides/arkts-state-management-v2`)。
取排名靠前、路径含 `harmonyos-guides`(指南)或 `harmonyos-references`(API 参考)的结果。

### 步骤 3 —— ⚠️ 版本消歧(最容易出错的一步)

官方同一主题常有多套 URL 并存,**必须消歧后再取**:

| URL 形态 | 含义 | 取舍 |
|---|---|---|
| `harmonyos-guides/<slug>` | 当前最新版指南 | **默认优先** |
| `harmonyos-guides-V5/<slug>` / `-V2/<slug>` | 锁定旧版本(API 对应 V5/V2) | 仅当项目 `compatibleSdkVersion` 对应该版时取 |
| `<slug>-0000001xxxxxxxxx-V2` | 带长数字 ID 的历史归档页 | 尽量避开,优先无数字 ID 的新 slug |

判定规则:**先读工程 `build-profile.json5` 的 `compatibleSdkVersion`**,匹配对应版本路径;
无工程上下文时默认取无版本后缀的新 slug。**输出里必须标注命中的是哪一版文档。**

### 步骤 4 —— 取正文

把选定 URL 交给 `web-fetch` 技能(firecrawl 能渲染 SPA),建议参数
`format: markdown`、`max_characters: 8000-12000`。返回后**裁掉页头导航/页脚 chrome**
(顶部"探索/设计/开发…"导航、底部备案信息),只留正文。

### 步骤 5 —— 输出纪律

- 给结论时附上:**命中 URL + 文档版本标注 + 关键原文片段**。
- 文档与本地 SDK `.d.ts` 冲突时,**以本地 SDK 声明为准**(那是项目实际锁定的版本)。
- 搜不到或正文不含答案时,明说"官方文档未直接覆盖,建议人工核对 X 页",**不要编造**。

## 检查清单

- [ ] 先查了 `references/doc-anchors.md` 再决定是否搜索
- [ ] site 限定搜索,未直连 `/doc/search?`
- [ ] 做了版本消歧,匹配 `compatibleSdkVersion`
- [ ] 输出标注了文档版本与 URL
- [ ] 不确定处如实说明,未编造 API

## 维护

`references/doc-anchors.md` 新增条目前,先用 `scripts/check-doc-urls.sh` 确认 URL 返回 200。
该脚本可纳入 `weekly-sdk-watch` 定期巡检,文档 URL 失效时及时发现。
