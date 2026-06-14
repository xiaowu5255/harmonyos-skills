---
name: version-guide
description: >-
  鸿蒙 API 版本治理与升级:compatibleSdkVersion/targetSdkVersion 语义、
  canIUse 运行时探测、@since/@deprecated 注释解读、SDK 版本间 API diff、
  升级 API 版本的完整流程。凡是涉及"升级到新 API 版本""这个 API 在 API XX
  能不能用""deprecated 怎么替换""不同设备系统版本兼容"时使用本技能。
  鸿蒙 API 每季度迭代(6.x 历 API 20→24,7.0 起 API 26),版本治理是长期必修课。
license: MIT
requires: harmony-index
metadata:
  target-platform: "HarmonyOS 6.x / API 20-24（兼顾 7.0 / API 26）"
---

# API 版本治理与升级

## 三个版本号的语义(混淆即事故)

- **compileSdkVersion**:按哪个版本的 SDK 编译,**决定哪些 API 能通过编译**。
- **compatibleSdkVersion**:承诺支持的最低系统版本。调用了高于它的 API,在老设备上
  运行时报错。**它决定你的用户覆盖面**。
- **targetSdkVersion**(可选):目标运行行为版本。升它可能改变运行时行为(权限策略、
  组件默认值等),升级后必须全量回归。

口诀:**能否编译看 compileSdkVersion;能否在老设备跑看 compatibleSdkVersion + canIUse 守卫**。

## 判断"这个 API 我能不能用"的标准动作

1. 在本地 SDK `ets/api/` 中找到该 API 的声明,看注释中的 `@since N`
   —— N ≤ compatibleSdkVersion 才能无条件使用。
2. N 更高但确实要用:用 `canIUse("SystemCapability.xxx")` 或版本判断做
   运行时分支,老设备走降级路径。**裸调用 + 祈祷 = 线上崩溃**。
3. 标了 `@deprecated` 的:注释通常给出替代 API(useinstead),新代码禁用,
   存量按计划替换——deprecated API 在后续版本可能直接移除。

## 升级 compatible/target 版本的流程清单

1. 升级前:`tools/sdk-diff/diff_api.py <旧SDK> <新SDK>` 生成 API 变更清单,
   重点看 removed 与 deprecated 列表与本工程的交集。
2. 改 build-profile.json5 的 compileSdkVersion / compatibleSdkVersion(及如有
   targetSdkVersion)→ 全量编译,逐个清理编译错误(多为 API 签名变更)。
3. 跑 `/harmony-api-scan` 检查是否仍有高于 compatible 版本的裸调用。
4. 全量回归重点:权限弹窗行为、后台任务、生命周期时序——target 升级最
   容易在这三处出现"代码没改行为变了"。
5. 留一台老系统真机验证 compatible 下限设备。

## 多版本共存的代码组织

版本分支逻辑收口到适配层(如 `compat/` 目录),UI/业务代码不直接写版本
判断——散落各处的 if(version) 在下次升级时是地雷阵。

## 版本基线速览(写代码前先定位项目在哪一档)

| 系统版本 | API Level | 状态(截至 2026-06) |
|---|---|---|
| HarmonyOS 6.0.0 | 20 | 存量主力 |
| 6.0.1 / 6.0.2 | 21 / 22 | |
| 6.1.0 / 6.1.1 | 23 / 24 | 6.x 末段,覆盖大量存量设备 |
| **HarmonyOS 7.0** | **26** | **2026-06-12 HDC 2026 发布 Developer Beta;正式版定于 2026 秋随 Mate90 系列** |

- 记法惯例 `系统版本(API Level)`,如 `6.1.1(24)`、`7.0(26)`。
- HarmonyOS 7 = **API 26**(已核实);主打端侧 Agent/盘古大模型、安全、连接、流畅四向。
- ⚠ **待核实**:有单一来源称"API 26 起版本号改用 SemVer X.Y.Z 格式",二次检索未获官方佐证。
  **按本仓库红线,未核实不写成事实**——需要时用 harmony-docs-retriever 查官方发布说明或以本地 SDK 为准。
- 注意 API 25 在公开材料中未见单独露出,HarmonyOS 7 直接对应 API 26;遇 API 25 声明先存疑核实。

## 维护本插件自身

新 API 版本发布后:跑 sdk-diff → 把变更摘要更新进各技能 references →
更新各 SKILL.md 中的版本标注 → 跑 tools/evals 回归。
