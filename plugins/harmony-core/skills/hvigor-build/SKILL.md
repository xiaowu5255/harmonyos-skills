---
name: hvigor-build
description: >-
  hvigor 构建系统与工程组织:HAP/HAR/HSP 三种包形态选型、多模块工程依赖、
  build-profile.json5 的 products/targets/buildOption、ohpm 依赖管理、release
  混淆配置。凡是涉及新建模块、抽公共库、配置多渠道/多环境构建、release 包行为
  异常(尤其混淆相关)、构建产物组织问题时使用本技能。构建报错的排查方法论在
  harmony-debugging 技能。
license: MIT
requires: 0-core-index
metadata:
  target-platform: "HarmonyOS 6.x / API 20-24"
---

# hvigor 构建与工程组织

## 包形态选型(最常被问错的问题)

| 形态 | 是什么 | 何时用 |
|---|---|---|
| HAP | 可安装运行的能力单元(entry/feature) | 应用入口与功能模块 |
| HAR | 静态共享库,编译期复制进宿主 | 公共组件/工具,多 App 复用,可发 ohpm |
| HSP | 动态共享库,运行时共享,App 内唯一副本 | 同一 App 内多 HAP 共享代码/资源,减包体 |

判断口诀:跨应用复用 → HAR;应用内多模块共享且在意包体 → HSP;能独立
运行/入口 → HAP。HSP 不能独立运行、不能跨 App。

## build-profile.json5 结构(根级)

- `app.products[]`:产品维度(签名、bundle 后缀、不同环境 buildOption)——
  多渠道/多环境在这里做,不要靠注释切换代码。
- `modules[]`:模块清单(name/srcPath/targets),目录改名必须同步。
- `app.signingConfigs[]`:签名(转 signing-and-certificates)。
- 模块级 build-profile.json5 的 `buildOption`:arkOptions、externalNativeOptions
  (NDK,转 native-ndk)、混淆配置。

## 依赖管理(ohpm)

- 模块间依赖写在各模块 `oh-package.json5` 的 dependencies:本地模块用
  `"lib": "file:../lib"`,三方库用版本号。
- 改了本地 HAR 代码宿主没生效 → 重新 ohpm install 或清缓存(HAR 是编译期复制)。
- 锁文件(oh-package-lock.json5)提交进 git,保证团队一致。

## release 混淆:暗坑高发区

**先确认混淆是否开启**:DevEco Studio 5.0.3.600 起新建工程混淆**默认关闭**
(模块级 build-profile.json5 的 `arkOptions.obfuscation.ruleOptions.enable: false`);
更早的工程模板或手动开过的工程才默认开。混淆仅在 release 编译生效。一旦开启,
**"debug 正常、release 异常/崩溃"九成与混淆有关**:
- 反射、动态调用、JSON 序列化字段名、native 回调的类/方法名被混淆 → 在
  `obfuscation-rules.txt` 中 keep(`-keep`/`-keep-property-name` 等)。
- 排查法:查混淆映射文件 `build/.../release/obfuscation/nameCache.json`,对照崩溃栈
  反解;或临时关混淆(`enable: false`)验证猜想(仅验证,不要当修复)。
- 上架前提醒:发布包通常应**显式开启**混淆(`enable: true`)以保护代码,开启后
  必须真机实测核心流程。

## 构建命令(CI 用)

```bash
hvigorw clean
hvigorw assembleHap --mode module -p product=default -p buildMode=release
hvigorw assembleApp ...   # 打 App Pack(上架用)
```
CI 上签名材料注入见 signing-and-certificates 的团队实践节。

## 设计建议

新工程从第一天就拆 common(HAR:工具/网络/组件)+ feature(HSP/HAP)结构;
等代码长大再拆,迁移成本翻几倍。
