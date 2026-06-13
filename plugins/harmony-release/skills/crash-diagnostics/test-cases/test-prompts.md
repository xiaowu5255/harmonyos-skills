# 测试提示词 — crash-diagnostics

## 基础功能测试

### 场景 1:CppCrash 分型
**提示词**：`应用突然闪退，faultlog 里是 SIGSEGV，堆栈有 #00 pc 地址和我的 libnative.so，帮我看`
**预期输出**：
- 判定为 CppCrash；先看 signal=SIGSEGV → 空指针/UAF 方向
- 要求符号化（同次构建的 unstripped so）；定位第一个自有 so 帧；提示 ASan 复跑

### 场景 2:JsCrash 分型
**提示词**：`鸿蒙应用闪退，报 TypeError: Cannot read property 'name' of undefined，栈在 Index.ets`
**预期输出**：
- 判定为 JsCrash；空值访问方向；回溯哪个值为空；建议 ?./?? + 状态初值；不是去查 native

### 场景 3:AppFreeze 分型
**提示词**：`界面卡死转圈，faultlog 显示 THREAD_BLOCK_6S，怎么定位？`
**预期输出**：
- 判定为 AppFreeze；直奔 main 线程栈顶判断阻塞类型（IO/IPC/锁/计算）
- 若等锁则找持锁线程；区分与 performance-tuning 的边界

### 场景 4:内存泄漏分型
**提示词**：`App 用着用着内存越来越大最后被杀，怎么查鸿蒙内存泄漏？`
**预期输出**：
- 先分 JS 堆 vs Native；JS 堆用两次快照 diff 找线性增长对象 + 保留路径
- 排查监听/定时器/PixelMap 未释放；不是直接猜代码

## 边界条件测试

### 场景 5:证据不足
**提示词**：`我的鸿蒙 App 崩了`（无任何日志）
**预期输出**：
- 不强行下结论；先要 faultlog 文件名前缀做分型 + 完整堆栈 + 是否符号化 + 版本上下文
