# AppFreeze(卡死 / 无响应 / ANR 类)分析

> 适用:faultlogger `appfreeze-*.log`,含 `THREAD_BLOCK`、`watchdog`、主线程超时等关键字。
> 本质:**主线程(UI 线程)被长时间阻塞**,watchdog 看门狗超时后生成故障。

## 关键事件类型

faultlog 顶部的 reason / 事件名指明严重度,常见:
- `THREAD_BLOCK_3S` / `THREAD_BLOCK_6S`:主线程被阻塞 3s/6s(看门狗分级)。
- `APP_INPUT_BLOCK`:输入事件分发超时(用户点了没反应)。
- `LIFECYCLE_TIMEOUT`:生命周期回调(如 onForeground)执行超时,归入系统冻屏范畴。

## 阅读顺序:直奔主线程栈

冻屏分析的核心是**看主线程当时卡在哪一帧**:

1. 找到故障日志里 **main 线程(tid 通常等于 pid)的调用栈**——这是它被采样时卡住的位置。
2. 看栈顶在做什么:
   - **同步 IO / 大文件读写**:主线程读写磁盘、解析大 JSON。
   - **同步 IPC / Binder 等待**:`sendMessageRequest` 同步调用对端无响应,主线程干等。
   - **锁等待**:主线程在等一把被子线程长期持有的锁(死锁/锁竞争)。
   - **大计算**:主线程做图像处理/排序/正则回溯等重 CPU 工作。
   - **死循环**:业务逻辑或状态驱动的无限循环。
3. 看 **其他线程栈**:如果主线程在等锁,要找持锁线程在干什么(它才是根因)。

## 高频根因模式

| 主线程栈特征 | 根因 | 修复方向 |
|---|---|---|
| 卡在文件/网络同步调用 | 主线程做了阻塞 IO | 移到 TaskPool/Worker;IO 异步化 |
| 卡在 binder/IPC 同步等待 | 同步跨进程调用对端慢/挂死 | 改异步;加超时;检查对端服务 |
| 卡在 lock/wait | 锁竞争或死锁 | 缩小临界区;避免主线程持锁;排查持锁线程 |
| 卡在 JS 长任务 | 主线程重计算 | 拆分/让出;重活进并发线程 |
| 启动期冻屏 | onCreate/首帧前同步初始化过重 | 初始化后置/懒加载(见 performance-tuning) |

## 与性能问题的边界

- **冻屏(本技能)= 触发 watchdog 的硬阻塞**,会生成 appfreeze faultlog。
- **掉帧/启动慢但不冻 = 性能问题**,走 `performance-tuning`(Profiler 火焰图/Trace)。
- 两者常同源(主线程干了重活),但取证不同:冻屏看 faultlog 主线程栈,性能看 Trace。

## 定位流程

1. 读 reason(THREAD_BLOCK_xS / INPUT_BLOCK / LIFECYCLE_TIMEOUT)。
2. 定位 main 线程栈顶 → 判定阻塞类型(IO / IPC / 锁 / 计算 / 死循环)。
3. 若是等锁 → 找持锁线程栈,定位真正占用者。
4. 给出"主线程上不该做的事 → 挪走"的修复;启动期冻屏交叉看 performance-tuning。
5. 偶现冻屏:按同主线程栈聚类,关注特定机型/弱设备/特定数据量触发。
