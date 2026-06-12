---
name: api-version-migration
description: >-
  鸿蒙 API 版本治理与升级:compatibleSdkVersion/targetSdkVersion 语义、
  canIUse 运行时探测、@since/@deprecated 注释解读、SDK 版本间 API diff、
  升级 API 版本的完整流程。凡是涉及"升级到新 API 版本""这个 API 在 API XX
  能不能用""deprecated 怎么替换""不同设备系统版本兼容"时使用本技能。
  鸿蒙 API 每季度迭代(6.x 周期已历 API 20→24),版本治理是长期必修课。
license: MIT
requires: harmony-index
metadata:
  target-platform: "HarmonyOS 6.x / API 20-24"
---

# API 版本治理与升级

## 两个版本号的语义(混淆即事故)

- **compatibleSdkVersion**:承诺支持的最低系统版本。代码中调用了高于它的
  API,在老设备上运行时报错。**它决定你的用户覆盖面**。
- **targetSdkVersion**:按哪个版本的系统行为运行。升它可能改变运行时行为
  (权限策略、组件默认值等),升级后必须全量回归。

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
2. 改 build-profile.json5 两个版本号 → 全量编译,逐个清理编译错误
   (多为 API 签名变更)。
3. 跑 `/harmony-api-scan` 检查是否仍有高于 compatible 版本的裸调用。
4. 全量回归重点:权限弹窗行为、后台任务、生命周期时序——target 升级最
   容易在这三处出现"代码没改行为变了"。
5. 留一台老系统真机验证 compatible 下限设备。

## 多版本共存的代码组织

版本分支逻辑收口到适配层(如 `compat/` 目录),UI/业务代码不直接写版本
判断——散落各处的 if(version) 在下次升级时是地雷阵。

## 维护本插件自身

新 API 版本发布后:跑 sdk-diff → 把变更摘要更新进各技能 references →
更新各 SKILL.md 中的版本标注 → 跑 tools/evals 回归。
