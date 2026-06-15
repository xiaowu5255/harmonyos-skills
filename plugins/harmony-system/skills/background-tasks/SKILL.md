---
name: background-tasks
description: >-
  鸿蒙后台任务体系:短时任务、长时任务(continuousTask)、延迟任务
  (workScheduler)、提醒代理。凡是出现"应用切后台就停了/被杀了""后台下载/
  播放/定位中断""定时任务不执行"类问题,或需要设计任何后台执行逻辑时,务必
  使用本技能。鸿蒙的后台管控比 Android 严格得多,不按系统提供的任务类型申请,
  代码写得再对也会被冻结——这是 Android 转鸿蒙开发者踩得最狠的坑。
license: MIT
requires: 0-system-index
metadata:
  target-platform: "HarmonyOS 6.x / API 20-24"
---

## Overview

鸿蒙后台任务体系:短时任务、长时任务(continuousTask)、延迟任务 (workScheduler)、提醒代理。凡是出现"应用切后台就停了/被杀了""后台下载/ 播放/定位中断""定时任务不执行"类问题,或需要设计任何后台执行逻辑时,务必 使用本技能。鸿蒙的后台管控比 Android 严格得多,不按系统提供的任务类型申请, 代码写得再对也会被冻结——这是 Android 转鸿蒙开发者踩得最狠的坑。

## When to Use

- 当用户请求与 background-tasks 相关的开发任务时

# 后台任务体系

## 第一原则:后台默认死,活着要申请

应用切后台后,系统会很快挂起进程(冻结 CPU 调度)。任何"后台还要干活"的
需求,必须映射到系统认可的任务类型之一,否则讨论代码细节毫无意义。

## 任务类型选型(先选对类型)

| 需求 | 用什么 | 关键约束 |
|---|---|---|
| 切后台后再收个尾(秒级~分钟级) | 短时任务 transientTask | 配额有限,到时必须主动取消,超时不放手会被强杀并记账 |
| 后台持续运行(音乐/导航/录音/VoIP等) | 长时任务 continuousTask | 仅限系统枚举的场景类型;需权限 KEEP_BACKGROUND_RUNNING;伴随前台通知,用户可见 |
| 不急但要做(同步/清理/上报) | 延迟任务 workScheduler | 执行时机由系统按资源/网络/充电等条件调度,不保证准时 |
| 定点提醒用户(闹钟/日历) | 提醒代理 reminderAgentManager | 系统代发,应用可不活着 |
| 跨端/云触发 | 推送(Push Kit,见 huawei-kits) | 让云端叫醒,别让本地硬扛 |

> 另有**能效资源 efficiencyResources**(applyEfficiencyResources)面向特权/系统级场景豁免管控,
> 普通三方应用一般用不到,知道存在即可。长时任务可用 bgMode 枚举:DATA_TRANSFER / AUDIO_PLAYBACK /
> AUDIO_RECORDING / LOCATION / BLUETOOTH_INTERACTION / MULTI_DEVICE_CONNECTION / WIFI_INTERACTION /
> VOIP / TASK_KEEPING 等(以官方当前列表为准)。

**没有"通用后台常驻"选项。**需求映射不到任何类型 → 重新设计方案
(通常改为:前台完成 / 延迟任务 / 推送触发)。

## 长时任务实现要点

1. module.json5 声明 `ohos.permission.KEEP_BACKGROUND_RUNNING`。
2. 申请时指定 bgMode(类型必须与真实业务一致——类型与实际行为不符是审核
   驳回与运行时被回收的双重雷区)。
3. 必须关联前台通知;任务结束立即 stop,挂着不用会被系统治理。
4. API 21+ 同一 UIAbility 最多可同时申请 **10 个**长时任务(类型可同可不同);
   API 20 及之前每个 UIAbility 仅能申请 **1 个**。写代码前查 compatibleSdkVersion。

## 延迟任务要点

- WorkSchedulerExtensionAbility 中实现 onWorkStart/onWorkStop;单次回调有
  时长预算,大活拆分多次。
- 触发条件(网络/充电/存储/定时)按需组合;**不要用它做"准点"任务**,
  它的语义是"条件满足后的某个时机"。

## 排查路径:"我的后台任务被杀了"

1. 确认用的是哪种任务类型;没用任何类型 → 这就是答案,按上表选型重做。
2. 长时任务:通知是否还在?类型与行为是否一致?是否超出场景(如申请了
   audioPlayback 但没在放音频,系统会回收)?
3. hilog 搜进程冻结/回收相关日志,确认是系统治理还是自身 crash(后者转
   harmony-debugging)。
4. 设备侧省电策略/后台管理设置也会影响,联调时排除该变量。
