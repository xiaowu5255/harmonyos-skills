---
name: arkts-syntax
description: >-
  HarmonyOS 6 (API 20-24) ArkTS 语言与 ArkUI 声明式开发规范。凡是涉及编写、审查、修改
  .ets 文件,使用 @Entry/@Component/@State 等装饰器,处理 ArkTS 编译器报错(arkts-* 规则),
  或将 TypeScript/JavaScript 代码迁移到 ArkTS 时,务必先使用本技能——即使任务看起来只是
  "写一个简单页面"或"改一个小 bug"。ArkTS 与 TypeScript 存在大量不兼容约束,凭 TS 直觉
  写代码会直接产生编译错误。
license: MIT
requires: 0-core-index
metadata:
  target-platform: "HarmonyOS 6.x / API 20-24"
---

# ArkTS 语法与 ArkUI 开发规范

## 第零条原则:先核对项目事实,再写代码

在回答任何 API 细节或动手写代码之前,按顺序做这三件事:

1. **读 `build-profile.json5`**(工程根目录),确认 `compatibleSdkVersion` 与
   `targetSdkVersion`。所有回答必须以项目实际锁定的 API 版本为准,不要假设用户在用最新版。
2. **查本地 SDK 接口声明**。SDK 中的 `.d.ts` / `.d.ets` 文件是 API 签名的唯一真相来源,
   永远比记忆可靠。典型位置(按实际安装路径调整):
   - DevEco 安装目录或 `~/`下的 SDK 路径:`.../sdk/<版本>/openharmony/ets/api/`
   - 工程内查找:`grep -r "declare" oh_modules/` 或对可疑 API 名做全局搜索
3. **对不确定的 API,明确说"需要查证"**,并给出查证方法(本地 d.ts 或官方文档),
   而不是给出一个看起来合理但可能不存在的 API 名。鸿蒙 API 每个季度都在变化,
   编造的 API 比承认不确定的伤害大得多。

## ArkTS 不是 TypeScript:硬性差异清单

写代码前默念这份清单。每条都对应一个编译器强制规则,违反即报错:

1. **禁止 `any` 和 `unknown`**。所有类型必须显式、静态可知。处理 JSON 时定义
   interface/class 再反序列化,不要 `as any` 蒙混。
2. **对象布局运行时不可变**。禁止动态增删属性、禁止 `delete obj.prop`、禁止用字符串
   索引访问非索引类型的对象属性。需要动态键值对时用 `Map<string, T>` 或 `Record<string, T>`。
3. **类字段必须显式初始化**(声明时或构造函数中),或显式声明为可选/可空类型。
4. **禁止 `var`**,只用 `let` / `const`。
5. **限制结构化类型**。两个形状相同的类不能互相赋值,需要显式继承或实现接口。
6. **不支持 `#` 私有字段语法**,使用 `private` 关键字。
7. **限制解构等动态特性**:部分解构写法、`arguments`、原型链操作(`Object.setPrototypeOf`
   等)被禁止。遇到编译器报 `arkts-` 开头的规则名时,**把规则名原文告诉用户并解释绕行写法**,
   不要只说"语法错误"。
8. **UI 结构体用 `struct` 而非 `class`**,且自定义组件必须有 `build()` 方法。

## 状态管理装饰器:V1 与 V2 不可混用

先判断项目用哪一代状态管理(看现有代码用的装饰器),保持一致,不要混搭:

**V1(存量项目常见)**
- `@State`:组件内部状态,变化驱动 UI 刷新。只能观察第一层属性变化。
- `@Prop`:父→子单向同步(值拷贝)。`@Link`:父子双向同步。
- `@Provide` / `@Consume`:跨层级传递。
- `@Observed` + `@ObjectLink`:解决嵌套对象/类实例的观察问题。
- V1 最常见的 bug 来源:**修改嵌套对象的深层属性 UI 不刷新**。根因是 V1 只观察一层。
  修复方向:用 @Observed 类 + @ObjectLink 拆分子组件,或整体替换对象引用。

**V2(API 12+ 引入,新项目推荐)**
- `@ObservedV2` + `@Trace`:类属性级精确观察,天然支持深层嵌套。
- `@Local`(替代 @State)、`@Param`(替代 @Prop,默认只读)、`@Event`(子→父回调)、
  `@Provider()` / `@Consumer()`。
- `@Param` 默认不可在子组件内直接修改——要改就配 `@Event` 回调让父组件改。

## build() 函数内的限制

`build()` 是 UI 声明区,不是普通函数体:

- 不允许声明局部变量、不允许 `console.log` 等任意语句。
- 条件渲染用 `if/else`,列表用 `ForEach` / `LazyForEach`(长列表必须用 LazyForEach
  并配合 `cachedCount`,否则有性能问题)。
- 复杂逻辑提取到 `@Builder` 方法、`@Styles`(通用样式)、`@Extend`(组件级样式扩展)中。
- `@Builder` 按引用传参时用对象字面量 `{ param: this.value }` 才能保持响应式更新。

## 工程文件速查

| 文件 | 作用 | 高频错误 |
|---|---|---|
| `build-profile.json5`(根) | SDK 版本、签名配置、产物定义 | compatibleSdkVersion 与设备/API 调用不匹配 |
| `module.json5` | 模块/Ability/权限声明 | 权限没声明就调 API;Ability 没注册 |
| `oh-package.json5` | ohpm 依赖 | 依赖版本与 API 版本不兼容 |
| `app.json5`(AppScope) | bundleName、版本号 | bundleName 与签名 Profile 不一致 |

## 需要深入时读 references/

- `references/ts-to-arkts.md` — TS→ArkTS 迁移常见报错与逐条改写示例。
  当用户在做代码迁移或批量出现 arkts-* 编译错误时再读。

## 输出纪律

- 给出的每段代码标注适用 API 版本(如"API 20+ 可用")。
- 涉及 API 21-24 新增能力(如 taskpool 任务超时、组件跨 Ability 迁移)时,
  显式提醒用户检查 compatibleSdkVersion。
- 不确定的 API 签名,先建议用户(或自己用工具)在本地 SDK d.ts 中验证。
