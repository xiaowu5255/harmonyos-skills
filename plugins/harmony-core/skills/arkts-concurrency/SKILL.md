---
name: arkts-concurrency
description: >-
  鸿蒙 ArkTS 并发编程: TaskPool 任务池、Worker 线程、Sendable 对象共享、
  并发容器。涉及多线程、任务超时、线程通信、并发安全时使用本技能。
license: MIT
requires: 0-core-index
kits: ["@kit.ArkTS"]
metadata:
  target-platform: "HarmonyOS 6.x / API 20-24"
---

# ArkTS 并发编程

## 第一原则：TaskPool 优先，Worker 为后

ArkTS 提供了两种线程模型——TaskPool 和 Worker。**默认选 TaskPool**，
只有 TaskPool 无法满足时才考虑 Worker。TaskPool 由系统调度线程池，
自动复用线程资源，避免线程创建/销毁开销；Worker 则独立管理线程
生命周期，开销更大但控制更精细。

## TaskPool 与 Worker 选型决策树

```
需要长期存活的线程? → 是 → Worker(常驻线程,如音视频管线)
                   → 否 ↓
需要频繁线程间通信? → 是 → Worker(MessageChannel 双向通信)
                   → 否 ↓
任务可独立执行、无强时序? → 是 → TaskPool
                          → 否 → 串行化到单 Worker 或重审设计
```

| 场景 | 用 TaskPool | 用 Worker |
|------|------------|----------|
| 计算密集型(图像处理、加密运算) | 首选 | 仅在需要生命周期控制时 |
| 后台常驻服务(文件监听、设备心跳) | 不适用 | 首选 |
| 大量小任务并发(网络请求批处理) | 首选 | 会产生过多线程开销 |
| ArkTS ↔ C++ 桥接耗时操作 | 可选(napi线程安全函数+TaskPool) | 首选(常驻Worker+C++管线) |
| API 24+ 任务超时控制 | `taskpool.execute(task, priority, timeoutMs)` | 自建超时机制 |

## TaskPool timeout 模式(API 24+)

```ts
// 任务超时 3000ms,超时抛异常
const task = new taskpool.Task(longRunningFunc);
taskpool.execute(task, taskpool.Priority.MEDIUM, 3000)
  .then(ok) .catch(err => {
    if (err.message.includes('timeout')) { /* 超时处理 */ }
  });
```

未指定 timeout 时任务可能无限挂起——凡是调用外部接口或带等待逻辑的任务
**必须设置超时**。

## Sendable 共享约束

Sendable 对象可在 TaskPool/Worker 间共享，免序列化开销。约束：
- 只允许 `ArrayBuffer`、`SharedArrayBuffer` 及 Sendable class 实例
- Sendable class 内所有成员必须是 Sendable 类型，**禁止闭包捕获外部状态**
- 与 `@Concurrent` 装饰器标记的函数配合使用

## 并发容器

| 容器 | 用途 | 约束 |
|------|------|------|
| `ConcurrentHashMap` | 多线程安全 KV 存储 | Key/Value 必须是 Sendable |
| `ConcurrentArray` | 多线程安全列表 | 元素必须是 Sendable |
| `ConcurrentQueue` | 生产者-消费者队列 | 适合任务调度场景 |

## 排查清单：“TaskPool/Worker 崩溃或不执行”

1. 检查 `@Concurrent` 装饰器是否遗漏——未标记的函数 TaskPool 拒绝执行。
2. Sendable 对象是否违规包含非 Sendable 成员(闭包/普通对象引用是头号陷阱)。
3. Worker 脚本路径是否正确——`new worker.ThreadWorker("entry/ets/workers/xx.ets")`
   路径写错静默失败，hilog 搜 worker 相关日志确认。
4. TaskPool 任务中调用 napi 接口——只能在 JS 线程用 napi,通过
   `napi_threadsafe_function` 回调才是正确姿势。
5. 并发量过大——TaskPool 虽复用线程，但瞬间提交数万个任务仍会排队阻塞；
   用并发容器或自建限流器控制峰值。

## 常见错误反例

| 错误 | 正确 |
|------|------|
| Worker 内部直接 `import { xx } from 'module'`——Worker 脚本独立加载，不共享主线程模块实例 | 在 Worker 内独立 import，或通过 MessageChannel 从主线程获取数据 |
| 不加 timeout 调用网络请求——Worker 可能永久挂起 | API 24+ 用 taskpool timeout，低版本 Worker 自建超时 Promise.race |
| 多 Worker 无脑并发——10 个 Worker 同时做小任务，创建开销超过任务本身 | 小任务用 TaskPool 统一调度，或限制 Worker 数量 ≤ CPU 核数 |
