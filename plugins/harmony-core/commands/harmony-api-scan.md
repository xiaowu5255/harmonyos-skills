---
description: 扫描工程中高于 compatibleSdkVersion 的 API 调用
---

检查当前工程的 API 版本风险:

1. 读 build-profile.json5,取 compatibleSdkVersion(记为 N)。
2. 若仓库 tools/sdk-diff/ 下已有针对 >N 版本的 diff 产物(api-changes-*.md),
   提取其中"新增 API"清单,在工程 .ets 源码中 grep 这些 API 名,列出命中处。
3. 没有 diff 产物时的兜底:对用户指出的可疑 API,在本地 SDK ets/api/ 中
   grep 其声明,读取 @since 标注与 N 比较。
4. 对每个超版本调用,给出三选一建议:canIUse 运行时分支 / 换低版本等价 API /
   评估提升 compatibleSdkVersion 的设备覆盖代价(见 version-guide 技能)。
5. 输出扫描报告:文件:行号 → API → @since → 建议。
