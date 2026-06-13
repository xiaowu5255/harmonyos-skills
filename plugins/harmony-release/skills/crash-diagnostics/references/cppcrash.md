# CppCrash(Native 层崩溃)分析

> 适用:faultlogger `cppcrash-*.log`,堆栈含 `#00 pc <addr>` 形式的 Native 帧。
> 根因在 C/C++/NDK 代码或 NAPI 桥接。

## 日志结构与阅读顺序

1. **Reason / Signal 行**——最先看。常见:
   - `SIGSEGV`(段错误):空指针解引用、野指针、数组越界、use-after-free。
   - `SIGABRT`(abort):assert 失败、C++ 未捕获异常、std 容器越界、二次 free/free 非法指针、检测到堆破坏。
   - `SIGBUS`:未对齐访问、mmap 文件被截断。
   - `SIGILL`:非法指令,常见于损坏的代码页或 ABI 不匹配。
2. **Fault thread 的 backtrace**——崩溃线程的调用栈。栈顶 `#00` 是崩溃指令地址,
   往下是调用链。重点找**第一个属于你自己 so 的帧**(系统库帧多为触发点而非根因)。
3. **寄存器 / maps**——高级排查用(判断地址落在哪个内存区、是否近 0 地址=空指针)。

## 符号化(Release 包必做)

裸地址形如 `#00 pc 0001a2b4  libxxx.so`,必须还原成 `函数名 + 文件:行号`:

- 用**与崩溃 so 完全同一次构建**产出的带符号 `.so`(unstripped)或符号文件。
- 工具链随 DevEco/NDK 版本不同(类 `addr2line`/`ndk-stack` 的能力),**以本机 NDK 实际工具为准**。
- 校验:符号文件的 build-id 必须与崩溃日志中的 so build-id 一致,否则行号全错。
- 纪律:发布前归档每个版本的 unstripped so + 符号文件,否则线上崩溃无法定位。

## 高频根因模式

| 栈/信号特征 | 典型根因 | 修复方向 |
|---|---|---|
| SIGSEGV + 近 0 地址 | 空指针解引用 | 调用前判空;NAPI 取参后校验 |
| SIGSEGV + 在释放后访问 | use-after-free / 悬垂指针 | 明确所有权,RAII/智能指针 |
| SIGABRT + `free`/`malloc` 相关帧 | 二次释放 / 越界写坏堆元数据 | ASan 定位;检查 buffer 边界 |
| SIGABRT + `__cxa_throw` | C++ 异常穿透到边界未捕获 | 在 NAPI 边界 try/catch,转成 JS 错误 |
| 崩在 napi_* 调用后 | 跨线程误用 env / 句柄失效 | env 不可跨线程;回主线程用 threadsafe function |

## NAPI / 跨线程专项

Native 崩溃很大一部分来自 ArkTS↔C++ 桥接:

- `napi_env`、`napi_value` **不能跨线程使用**;在 worker/native 线程回调 JS 必须走
  `napi_threadsafe_function`。误用常表现为偶现 SIGSEGV。
- 从 JS 取到的对象在 Native 侧长期持有需 `napi_create_reference`,否则被 GC 回收后即悬垂。
- 详见 `native-ndk`(harmony-system)的 N-API 线程约束。

## 定位流程

1. 读 signal/reason → 大方向(空指针 / abort / 越界)。
2. 符号化崩溃线程栈 → 找第一个自有 so 帧。
3. 对照根因模式表 → 形成假设。
4. 能复现:用 ASan 构建复跑(Address Sanitizer 直接点出越界/UAF 位置)。
5. 偶现:按"同栈 + 同机型 + 同 ROM"聚类,缩小到具体设备/路径。

> ASan:鸿蒙支持以 Address Sanitizer 方式构建运行(含 Instrument Test 的 ASan 检测),
> 是定位内存破坏类 CppCrash 最有效的手段。具体开启方式以 DevEco 当前版本为准。
