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
不稳定、违规、会被风控。改走下面的稳态检索工作流。

## 稳态检索工作流

### 步骤 1 —— 先查本地锚点表(零搜索,精度最高)

读 `references/doc-anchors.md`,这是一张"常见主题 → 已核实稳定 URL"的映射表。
命中即拿到 canonical URL,直接跳步骤 4。锚点表里的 URL 都经 `scripts/check-doc-urls.sh`
校验过 200,是最可靠的入口。

### 步骤 2 —— ⭐ Context7 官方库检索(优先于通用搜索)

锚点表未命中时,**优先用 Context7**——它已把 developer.huawei.com 全量文档结构化收录,
直接返回正文 + 官方 URL,无需渲染 SPA,比通用搜索更准、比 web-fetch 更稳。

可用官方库(均为 High 声誉一手源):

| Context7 库 ID | 覆盖 | 取舍 |
|---|---|---|
| `/websites/developer_huawei_consumer_cn_doc_harmonyos-references` | **API 参考**(签名/枚举/错误码) | **验 API 签名首选** |
| `/websites/developer_huawei_consumer_cn_doc_harmonyos-guides` | 开发指南/最佳实践 | 查用法/流程 |
| `/websites/developer_huawei_consumer_cn_doc` | HarmonyOS 文档总入口 | 兜底 |
| `/websites/developer_huawei_consumer_cn_doc_harmonyos-references-v13` | API 参考 V13 锁定版 | 项目锁 V13 时 |
| `/websites/developer_huawei_consumer_cn_doc_app_agc-help-` | AGC 云服务/签名 Profile | 云侧/签名问题 |

用法:`resolve-library-id` 取库 → `query-docs(libraryId, query)`,query 带**具体 API 名**
(语义检索,问得越具体召回越准;不能用它"遍历列全部 Kit")。返回的每条 snippet 自带官方 URL。

**四条铁律**:
1. **快照非实时,新版有盲区**——Context7 是周期快照,典型滞后约一个季度。鸿蒙季度级迭代,
   **大版本发布后数周至数月内 Context7 必无新内容**(实证:2026-06 HarmonyOS 7/API 26 已发布,
   Context7 快照仍停在 ~2026-03、最高 API 19)。
2. **盲区降级(关键)**——出现以下任一信号,判定 Context7 对目标版本失效,**跳过它**改走
   本地 d.ts → 官方 SPA 抓取(步骤 5),都缺则如实声明"该版本文档尚未覆盖":
   - query-docs 召回的**最高 API 版本明显低于目标** `compatibleSdkVersion`;
   - 命中 snippet 的 `Last Updated` 早于目标版本的发布日期。
3. **版本混杂**——同一 query 可能跨版本召回,务必按步骤 4 消歧。
4. **优先级**——本地 SDK `.d.ts`(项目实际锁定版,零延迟最终托底) > Context7 官方快照 >
   官方 SPA 抓取 > 通用搜索。冲突时**以本地 d.ts 为准**。

### 步骤 3 —— 仍未命中则用 site 限定搜索(回退)

Context7 也查不到时,用通用搜索引擎(WebSearch 工具),查询拼成:

```
<关键词> site:developer.huawei.com/consumer/cn/doc
```

robots.txt 只禁 `/doc/search?`,**文档页本身允许被搜索引擎索引**,所以 site 限定搜索能
稳定返回 canonical 文档 URL(slug 形如 `harmonyos-guides/arkts-state-management-v2`)。
取排名靠前、路径含 `harmonyos-guides`(指南)或 `harmonyos-references`(API 参考)的结果。

### 步骤 4 —— ⚠️ 版本消歧(最容易出错的一步)

官方同一主题常有多套 URL 并存,**必须消歧后再取**:

| URL 形态 | 含义 | 取舍 |
|---|---|---|
| `harmonyos-guides/<slug>` | 当前最新版指南 | **默认优先** |
| `harmonyos-guides-V5/<slug>` / `-V2/<slug>` | 锁定旧版本(API 对应 V5/V2) | 仅当项目 `compatibleSdkVersion` 对应该版时取 |
| `<slug>-0000001xxxxxxxxx-V2` | 带长数字 ID 的历史归档页 | 尽量避开,优先无数字 ID 的新 slug |

判定规则:**先读工程 `build-profile.json5` 的 `compatibleSdkVersion`**,匹配对应版本路径;
无工程上下文时默认取无版本后缀的新 slug。**输出里必须标注命中的是哪一版文档。**

### 步骤 5 —— 取正文(仅 site 搜索路径需要)

若证据已由步骤 2 的 Context7 拿到(snippet 即正文),直接进入步骤 6。
仅当走步骤 3 的 site 搜索、只拿到 URL 时,把选定 URL 交给 `web-fetch` 技能
(firecrawl 能渲染 SPA),建议参数 `format: markdown`、`max_characters: 8000-12000`。
返回后**裁掉页头导航/页脚 chrome**(顶部"探索/设计/开发…"导航、底部备案信息),只留正文。

### 步骤 6 —— 输出纪律

- 给结论时附上:**命中 URL + 文档版本标注 + 关键原文片段**。
- 文档与本地 SDK `.d.ts` 冲突时,**以本地 SDK 声明为准**(那是项目实际锁定的版本)。
- 搜不到或正文不含答案时,明说"官方文档未直接覆盖,建议人工核对 X 页",**不要编造**。

## 检查清单

- [ ] 先查了 `references/doc-anchors.md` 再决定是否搜索
- [ ] 锚点未命中时优先用 Context7 官方库(references 验签名/guides 查用法),而非直接通用搜索
- [ ] 目标是新发布版本(Context7 召回最高 API 低于目标 / Last Updated 早于发布日)时,已跳过 Context7 降级到 d.ts / 官方抓取
- [ ] site 限定搜索作回退,未直连 `/doc/search?`
- [ ] 做了版本消歧,匹配 `compatibleSdkVersion`
- [ ] 输出标注了文档版本与 URL
- [ ] 与本地 SDK d.ts 冲突时以 d.ts 为准
- [ ] 不确定处如实说明,未编造 API

## 维护

`references/doc-anchors.md` 新增条目前,先用 `scripts/check-doc-urls.sh` 确认 URL 返回 200。
该脚本可纳入 `weekly-sdk-watch` 定期巡检,文档 URL 失效时及时发现。
