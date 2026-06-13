---
name: crash-diagnostics
description: >-
  鸿蒙故障日志分型诊断:把 faultlogger/DevEco 抓到的崩溃、卡死、内存泄漏日志按类型定位根因。
  涉及 CppCrash(Native 崩溃)、JsCrash(ArkTS/JS 闪退)、AppFreeze(卡死/无响应/ANR)、
  内存泄漏(rawheap/heapsnapshot/native 内存涨)、错误码与 faultlog 分析时使用。
  收到崩溃堆栈、应用闪退/冻屏、内存只涨不降等问题先用本技能分型,再读对应 references 深挖。
license: MIT
requires: 0-release-index
metadata:
  target-platform: "HarmonyOS 6.x / API 20-24"
---

# 鸿蒙故障日志分型诊断

## 先分型:不同故障读不同的日志、找不同的根因

拿到一个"崩了/卡了/内存涨了"的问题,**第一步永远是判定故障类型**,因为证据来源和定位
方法完全不同。按下表分流到对应深度参考:

| 现象 | 故障类型 | 证据来源 | 深度参考 |
|---|---|---|---|
| 应用突然消失,Native 信号(SIGSEGV/SIGABRT)、含 `#00 pc` 地址堆栈 | **CppCrash** | faultlogger `cppcrash-*.log` | `references/cppcrash.md` |
| 应用闪退,堆栈是 `.ets`/`.ts` 帧 + Error message + ArkTS 调用链 | **JsCrash** | faultlogger `jscrash-*.log` | `references/jscrash.md` |
| 界面卡死/转圈无响应,日志含 `THREAD_BLOCK`、`watchdog`、主线程超时 | **AppFreeze** | faultlogger `appfreeze-*.log` + 主线程栈 | `references/appfreeze.md` |
| 内存只涨不降、最终被 LMK 杀、`.rawheap`/`.heapsnapshot`、native 内存攀升 | **内存泄漏** | DevEco Profiler / rawheap / hidumper | `references/memory-leak.md` |

> 不确定属于哪类时:看 faultlogger 文件名前缀(`cppcrash`/`jscrash`/`appfreeze`)是最快的判定;
> 内存问题通常不是单条 faultlog,而是 Profiler 里的增长曲线 + 一次堆快照。

## 通用取证(任何类型都先做这三步)

1. **拿到原始 faultlog,不要只看 DevEco 弹窗摘要**。faultlogger 日志在设备
   `/data/log/faultlog/faultloggerd/`(需要权限/hdc),DevEco 的 FaultLog 面板也可导出。
   用 `hdc file recv` 取出完整文件再分析。
2. **确认符号化是否完成**。Release 包堆栈是裸地址,必须用**与崩溃包同一次构建产物**
   配套的符号文件还原;符号表对不上 = 行号全错。详见各 references 的符号化小节。
3. **锁定版本上下文**。读工程 `build-profile.json5` 的 `compatibleSdkVersion`,
   崩溃常与 API 版本/设备 ROM 相关;跨版本堆栈含义可能不同。

## 根因定位心法(贯穿四类)

- **先看 reason/signal 行,再看栈顶**:faultlog 顶部的 reason、signal、错误码决定大方向,
  比逐帧读栈高效。
- **区分"崩溃点"与"根因点"**:栈顶往往只是症状(如 `abort`/空指针解引用),
  根因常在调用链中段(谁传了空值、谁释放了二次)。
- **复现优先于猜测**:能稳定复现就上 Profiler/断点;偶现的先按日志聚类找共性
  (同一栈、同一机型、同一 ROM)。
- **证据链完整才下结论**:给出"reason → 关键帧 → 根因代码 → 修复方向",
  缺任一环就说明还需要哪条信息(更全的栈、符号文件、复现步骤)。

## 输出纪律

- 明确标注故障类型与判定依据(哪一行/哪个前缀)。
- 涉及具体工具命令(hdc/hilog/符号化)时,提示"以本机 DevEco/SDK 版本实际命令为准"——
  工具子命令随版本变化,不要把记忆中的参数当唯一真相。
- 无法从现有日志定位时,明确列出"还缺什么证据"而不是强行给结论。

## 与其他技能的关系

- 通用六层诊断法、hdc/hilog 基操、错误码对照 → `harmony-debugging`(harmony-core)。
  本技能是其中"崩溃/卡死/泄漏"三类的分型深挖。
- 性能卡顿但**没崩没冻**(掉帧/启动慢)→ `performance-tuning`。
- 想查某错误码/故障的官方解释 → `harmony-docs-retriever` 取官方原文。
