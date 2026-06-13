# 内存泄漏分析(JS 堆 / Native 内存)

> 适用:内存只涨不降、最终被 LMK(low memory killer)杀、OOM、`.rawheap`/`.heapsnapshot`、
> native 内存持续攀升。与单条崩溃日志不同,泄漏靠**增长曲线 + 堆快照对比**定位。

## 先分两类:JS 堆 vs Native 内存

| 现象 | 类型 | 证据 |
|---|---|---|
| ArkTS 对象越积越多,`.heapsnapshot`/`.rawheap` 增大 | **JS/ArkTS 堆泄漏** | DevEco Profiler 堆快照 |
| Native 内存(malloc/mmap)涨,JS 堆稳定 | **Native 泄漏** | hidumper / native 内存分析 |
| 图片相关内存暴涨 | PixelMap 未释放 | 介于两者,重点查 PixelMap 生命周期 |

## JS/ArkTS 堆泄漏定位

核心方法是**两次快照对比(diff)**:

1. 进入怀疑泄漏的场景前打一次快照(baseline)。
2. 反复进出该场景 N 次(触发疑似泄漏路径)、手动触发 GC 后再打一次快照。
3. 对比两次快照的**对象数量增量**:稳定线性增长的类型就是泄漏对象。
4. 看该对象的**保留路径(retainer / GC root 引用链)**——谁在强引用它不放,那就是根因。

`.rawheap` 是 ArkTS 运行时的堆转储,经聚类工具(如 heap 聚类脚本)处理后看对象聚类与
引用关系;`.heapsnapshot` 为标准堆快照格式。**具体打快照/转储入口以 DevEco Profiler 当前版本为准。**

### ArkTS 高频泄漏根因

| 模式 | 说明 | 修复 |
|---|---|---|
| 监听/订阅未反注册 | `on()`/emitter/sensor/AVSession 订阅后未 `off()` | 在 aboutToDisappear/onBackground 成对反注册 |
| 定时器未清 | setInterval/animator 未停 | 组件销毁时 clear |
| 全局/单例持有页面对象 | AppStorage/静态表缓存了页面级对象 | 弱引用或显式移除 |
| 闭包捕获大对象 | 回调闭包长期持有大数据/this | 缩小捕获范围 |
| 图片缓存无上限 | PixelMap 累积不释放 | LRU 上限 + 及时 `release()` |

## Native 内存泄漏

- malloc/new 后未释放、句柄(fd/buffer/PixelMap native 侧)未关闭。
- 用 hidumper 等查进程内存构成(以本机工具实际子命令为准),定位增长的内存类别。
- NAPI 创建的引用(`napi_create_reference`)未 delete → JS 对象无法回收,表现为 JS 堆也涨。
- 可结合 ASan/内存检测构建定位分配点。详见 `native-ndk`(harmony-system)。

## 静态预防(写码阶段)

不少泄漏在评审期可拦截,扫描这些点:
- 每个 `on/register/subscribe` 是否有配对的 `off/unregister/unsubscribe`。
- 每个 `setInterval/animator/timer` 是否有清理。
- 每个 `PixelMap`/native 句柄是否有 `release`/close。
- NAPI `napi_create_reference` 是否有 `napi_delete_reference`。

## 定位流程

1. 先判 JS 堆 vs Native(看 Profiler 内存分项哪部分在涨)。
2. JS 堆:两次快照 diff → 找线性增长对象 → 看保留路径 → 定位强引用源。
3. Native:hidumper/内存检测构建定位分配点;查句柄/引用是否成对释放。
4. 对照根因模式表给修复;补静态预防清单进 PR 评审。
