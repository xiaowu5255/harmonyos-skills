---
name: performance-tuning
description: >-
  鸿蒙应用性能优化:冷启动、丢帧/卡顿、内存、列表滑动性能;DevEco Profiler
  与 HiTraceMeter 的使用方法。凡是用户反馈"启动慢""卡顿""掉帧""内存涨""列表
  滑动不流畅",或上架前性能达标整改时使用本技能。性能工作的铁律:先测量定位
  热点,再优化——没有 profiler 数据支撑的优化建议一律视为猜测。
license: MIT
metadata:
  target-platform: "HarmonyOS 6.x / API 20-24"
---

# 性能优化

## 工作流(强制顺序)

复现(固定机型/数据量/操作路径)→ 测量(Profiler 抓 trace)→ 定位热点
→ 单点优化 → 回归测量对比。跳过测量直接改代码 = 浪费时间 + 引入回归。

## 工具箱

- **DevEco Profiler**:Time(CPU 热点)/ Frame(丢帧归因)/ Allocation与
  Snapshot(内存)/ Launch(启动分析)。性能问题先选对应模板抓数据。
- **HiTraceMeter**:代码内 startTrace/finishTrace 自定义打点,在 trace 中
  量出自己业务段耗时——定位"到底慢在哪一段"的标尺。
- **hilog 时间戳**:粗定位用,精细分析以 trace 为准。

## 冷启动优化(按收益排序)

1. 入口瘦身:onCreate/onWindowStageCreate 里只做必须项;SDK 初始化、
   网络预热延后到首帧后或按需懒加载。
2. 首页 aboutToAppear 不做同步重活;首屏数据异步 + 占位 UI。
3. 减少启动链路上的模块加载:延迟 import 非首屏依赖(动态 import)。
4. 启动页与首页合并/缩短,避免多级跳转。
用 Profiler 的 Launch 模板量化每阶段耗时,优化最大段。

## 丢帧/卡顿

- Frame 模板抓丢帧点,看主线程在干嘛:布局过深(转 arkui-patterns 拍平)、
  build 中重计算(挪到状态变更处缓存)、主线程 IO/JSON 大解析(挪
  taskpool/Worker)。
- 状态滥用:一个 @State 变更牵动大子树刷新 → 拆组件、缩小状态影响面、
  V2 精确观察(@Trace)。
- 动画卡:优先系统动画与转场(系统侧渲染),少用逐帧改状态驱动。

## 列表与内存

- 列表三件套(LazyForEach + cachedCount + @Reusable)见 arkui-patterns;
  滑动卡顿九成在列表项过重或未复用。
- 内存:Snapshot 对比操作前后,找只增不减的对象;常见泄漏源——全局缓存
  context/组件引用、监听器注册未注销(页面 aboutToDisappear 成对清理)、
  Worker/taskpool 任务持有大对象不释放。
- 大图:按显示尺寸解码采样,列表头像类用小图 URL 而非原图缩放。

## 并发选型

- 短任务/可并行计算 → taskpool(优先,系统调度)。
- 长驻后台逻辑/独立消息循环 → Worker(数量有限制,用完销毁)。
- 两者都不共享内存,数据经序列化传递——传大对象本身就是开销,设计时减少
  跨线程数据量。
