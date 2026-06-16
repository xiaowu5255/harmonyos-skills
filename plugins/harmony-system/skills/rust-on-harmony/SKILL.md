---
name: rust-on-harmony
description: >-
  鸿蒙 Rust 开发:基于 napi-rs OpenHarmony fork(ohos-rs/ohos-rs)的 Node-API 绑定、
  Rust 标准库交叉编译(`aarch64-unknown-linux-ohos` 等 tier-2 目标)、OHOS SDK Clang
  wrapper、Cargo + hvigor 协同构建、ArkTS↔Rust FFI 安全模型、线程约束。
  涉及 Rust 性能模块、密码学/音视频 Rust 库移植、.so 通过 napi-rs 暴露给 ArkTS
  时使用本技能。
license: MIT
requires: 0-system-index
metadata:
  target-platform: "HarmonyOS 6.x / API 20-24"
---

## Overview

Rust 鸿蒙开发:通过 napi-rs 的 OpenHarmony fork(`ohos-rs/ohos-rs`)将 Rust 实现以 .so 形式暴露给 ArkTS。Rust 标准库支持三个 tier-2 目标(aarch64/armv7/x86_64 的 `*-unknown-linux-ohos`),需通过 OHOS SDK Clang wrapper + `-Z build-std` 完成交叉编译。

## When to Use

- 涉及 Rust 集成 时
- 涉及 Rust 模块 时
- 涉及 Rust 到鸿蒙 时
- 涉及 napi-rs 时
- 涉及 Rust 性能 时

# Rust 在鸿蒙上的开发

> **本领域成熟度提醒**：Rust→OHOS 链路已可用(`ohos-rs` 是 napi-rs 的官方 fork,
> tier-2 官方目标),但生态规模远小于 Rust→Android/iOS。生产使用前先在目标设备
> 实测 ABI 兼容、信号处理、Panic 行为;不要凭 Rust 直觉假设与 Linux 行为一致。

## 三个 tier-2 目标(实测可用)

| 目标 triple | 适用 | rustup 等级 |
|------------|------|------------|
| `aarch64-unknown-linux-ohos` | 手机/平板/2in1 真机 | **Tier 2** |
| `armv7-unknown-linux-ohos` | 32 位 ARM 设备(罕见,多为早期 IoT) | **Tier 2** |
| `x86_64-unknown-linux-ohos` | 模拟器 | **Tier 2** |

> Tier 2 = 官方 std 库 + 自动构建 + host 工具支持(详见 [rustc platform-support](https://doc.rust-lang.org/stable/rustc/platform-support/openharmony.html))。
> 这三个目标由 rustc 官方维护者(Amanieu、cceerczw)维护,不是社区三方案。

## Clang wrapper(必须)

OHOS SDK 不直接支持 Rust 编译,需写 wrapper 脚本调用 SDK 内 Clang:

```text
// 文件名:aarch64-unknown-linux-ohos-clang.sh
#!/bin/sh
exec /path/to/ohos-sdk/linux/native/llvm/bin/clang \
  -target aarch64-linux-ohos \
  --sysroot=/path/to/ohos-sdk/linux/native/sysroot \
  -D__MUSL__ \
  "$@"
```

`aarch64-linux-ohos` 中的 `-linux-` 段是 Clang 的 target 标志,跟 rustc 的
`aarch64-unknown-linux-ohos` 不是同一字符串——混用是构建失败的常见原因。

## 交叉编译配置(.cargo/config.toml)

```toml
[target.aarch64-unknown-linux-ohos]
linker = "/path/to/aarch64-unknown-linux-ohos-clang.sh"

[build]
target = "aarch64-unknown-linux-ohos"

[unstable]
build-std = ["core", "alloc"]   # OHOS 不在预编译 std 列表里,必须 build-std
```

> `cargo` 自身在该目标下可用,需要 ohos-rs 提供的 `ohos-openssl` 等补丁包——
> 不要假设 `cargo build --target aarch64-unknown-linux-ohos` 一次跑通。

## napi-rs OpenHarmony fork

官方 napi-rs 仓库([napi-rs/napi-rs](https://github.com/napi-rs/napi-rs))的目标
triples 列表中**已包含 3 个 OHOS target**,但 napi-rs 主线尚未正式将 OHOS 列为
稳定支持平台。生产用法是 fork 版本 **[ohos-rs/ohos-rs](https://gitee.com/ohos-rs/ohos-rs)**:

- 维护者:southorange0929 等
- 提供 `ohos-rs` 命名空间的 crate(同步 napi-rs 主线 + OHOS 适配)
- 同组织还提供 `ohos-native-bindings`(HarmonyOS native API 的 Rust 绑定)
- 官网:https://ohos.rs

**用法骨架**(伪代码,签名以仓库 README 为准):

```rust
// Cargo.toml
[dependencies]
napi = { git = "https://gitee.com/ohos-rs/napi-rs", branch = "ohos" }
napi-derive = { git = "https://gitee.com/ohos-rs/napi-rs", branch = "ohos" }

// src/lib.rs
use napi_derive::napi;

#[napi]
pub fn add(a: i32, b: i32) -> i32 { a + b }
```

## FFI 边界安全模型

ArkTS↔Rust 跨语言边界有四类坑,任一处理不当即随机崩溃:

| 风险 | 触发场景 | 正确做法 |
|------|---------|---------|
| **生命周期错配** | Rust 持有 JS 对象引用 | 用 `napi::Env` 的 ref/handle,不要裸 `*mut` 缓存 |
| **线程错配** | Rust spawn 的线程回调 JS | 必须经 `ThreadsafeFunction` 投递回 JS 线程,直接调 = 随机崩溃 |
| **字符串/数组拷贝** | 高频小字符串跨边界 | 合并为 batch 接口;Rust 侧不要 zero-copy 跨语言边界假设 |
| **Panic 跨界** | Rust panic 传到 JS 侧 | `catch_unwind` 边界;否则 abort() 整个进程 |

> 与 native-ndk 的 napi 纪律**完全一致**——Rust 走 napi-rs 只是把 C++ 换成了 Rust,
> 线程约束、env 作用域、async work 这些铁律不变。先读 `native-ndk` 再读本 skill。

## Cargo + hvigor 协同

hvigor 通过 `externalNativeOptions` 调用 CMake 构建。Rust 项目两种集成路径:

1. **CMake `add_custom_command`** — 在 CMakeLists.txt 里调 `cargo build --release --target aarch64-unknown-linux-ohos`,产物 `librust_module.so` 再 `add_library(... SHARED IMPORTED)`。
2. **hvigor 任务** — 直接在 build-profile 中加自定义 task,绕过 CMake(DevEco 工程少用,生产项目需维护)。

推荐路径 1:CMake + cargo 链路成熟,DevEco 调试链路完整支持。

## 何时用 Rust 下沉(决策框架)

满足**任一**条件再考虑 Rust 沉淀:

- 已有 Rust 资产复用(密码学、Rust 写的算法/解析器)
- CPU 密集且已用 profiler 证明热点在 ArkTS 侧
- 需要 `no_std` 极小运行时(嵌入式场景)

不满足时留在 ArkTS:跨语言边界本身有 FFI 开销 + 构建复杂度翻倍 + 调试链路变长,
为"听起来更快"而下沉不划算(见 performance-tuning)。

## ⚠️ 常见误区与反模式

| 误区 | 正确做法 | 来源 |
|------|---------|------|
| `cargo build --target aarch64-unknown-linux-ohos` 一次跑通 | OHOS 不在预编译 std 列表,必须 `-Z build-std` + Clang wrapper | rustc platform-support |
| 用上游 `napi-rs` 仓库 | 上游未正式支持 OHOS;生产用 `ohos-rs/ohos-rs` fork | ohos-rs 官网 |
| Clang target 写 `aarch64-unknown-linux-ohos` | Clang 写 `aarch64-linux-ohos`(无 `-unknown-`);rustc triple 与 Clang target 是两套字符串 | OHOS SDK |
| Rust 工作线程直接调 napi 接口 | 必须经 `ThreadsafeFunction` 投回 JS 线程 | napi 线程约束 |
| 用 `extern "C"` + `unsafe` 跨边界传 `String` | Rust String 非 C 兼容;用 `napi::JsString` / `CString` 显式边界 | napi FFI 安全模型 |
| Rust panic 跨越 FFI 边界 | 进程级 abort;用 `catch_unwind` 在边界捕获并转为 napi 错误 | unwind 边界 |

> **验证方法**：1) `rustup target list --installed` 看是否安装 ohos triple;
> 2) `cargo build --target aarch64-unknown-linux-ohos` 跑通 build-std;
> 3) 用 `nm librust_module.so | grep napi_register` 确认导出符号;
> 4) 真机导入测试 ArkTS 侧能否 `import` 模块;
> 5) 不确定 API 走 `harmony-docs-retriever` 查官方文档。

> 官方文档：[rustc OpenHarmony 平台支持](https://doc.rust-lang.org/stable/rustc/platform-support/openharmony.html) · [ohos-rs 官网](https://ohos.rs) · [napi-rs triples 列表](https://github.com/napi-rs/napi-rs/blob/main/triples/target-list)