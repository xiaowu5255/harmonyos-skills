---
name: native-ndk
description: >-
  鸿蒙 Native 开发(NDK):N-API/Node-API 桥接 ArkTS 与 C/C++、CMake 工程配置、
  so 库集成与三方 C++ 库移植、跨语言类型映射与线程约束。凡是涉及 C++ 代码接入、
  .so 文件、napi 报错、性能敏感模块下沉、移植现有 C/C++ 库到鸿蒙时使用本技能。
license: MIT
metadata:
  target-platform: "HarmonyOS 6.x / API 20-24"
---

# Native 开发(NDK)

## 工程结构(模板生成,核心三件)

```
entry/src/main/cpp/
├── CMakeLists.txt        # 目标产物 libentry.so;链接 libace_napi.z.so 等
├── napi_init.cpp         # 模块注册:Init + napi_module_register
└── types/libentry/       # index.d.ts:向 ArkTS 暴露的接口声明
```
ArkTS 侧 `import native from 'libentry.so'` 调用。**d.ts 声明与 C++ 注册的
函数名/签名不一致**是最常见的"undefined is not a function"来源,排查先对这两处。

## N-API 写作纪律

- 每个 napi_value 只在创建它的 env/作用域内有效;**不得缓存 env 或
  napi_value 跨调用使用**,要长期持有 JS 对象用 napi_ref。
- **线程约束(头号崩溃源)**:napi 接口只能在 JS 线程调用。C++ 工作线程回调
  结果必须经 napi_threadsafe_function 投递回 JS 线程,直接调用 = 随机崩溃。
- 耗时操作不要占 JS 线程:用 napi_create_async_work 或自管线程 + 线程安全
  函数回投。
- 字符串/数组跨边界有拷贝成本,高频小调用考虑合并批量传输。

## CMake 与三方库移植

- 工具链由 hvigor 注入(externalNativeOptions 指定 CMakeLists 路径与
  abiFilters,目前主要目标 arm64-v8a;模拟器架构按实际 SDK 支持配置)。
- 移植现有库:优先找官方/社区已适配版本;自移植时按交叉编译思路处理平台
  宏与依赖,系统能力用鸿蒙 NDK 头文件(如 hilog C API:`hilog/log.h`)替换
  Linux/Android 特有调用。
- so 体积进包,release 记得 strip 与按需裁剪。

## 调试

- C++ 崩溃看 hilog 中 cppcrash 栈,配合带符号 so 解析地址。
- LLDB 真机调试:DevEco 中选 Native/Dual 调试模式可断 C++ 断点。
- 怀疑 ArkTS↔C++ 边界问题时,在桥接层两侧各打一条日志,夹逼定位。

## 何时下沉 Native

已有 C++ 资产复用、重计算(音视频/图像/算法)、密集内存操作。普通业务逻辑
留在 ArkTS——跨语言边界本身有成本,为"快"而下沉先用 profiler 证明热点
(见 performance-tuning)。
