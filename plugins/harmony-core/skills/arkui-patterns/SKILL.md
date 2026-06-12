---
name: arkui-patterns
description: >-
  ArkUI 声明式 UI 开发模式:布局组件选型、Navigation 路由、列表性能(LazyForEach/
  组件复用)、@Builder/@Styles/@Extend 复用、动画与转场、自定义弹窗、资源引用。
  凡是要实现具体界面、写页面布局、做页面跳转、优化列表卡顿、加动画效果时使用本技能。
  注意:语言级语法约束与状态管理装饰器在 arkts-syntax 技能中,两者经常需要配合使用。
license: MIT
requires: 0-core-index
metadata:
  target-platform: "HarmonyOS 6.x / API 20-24"
---

# ArkUI 开发模式

## 布局组件选型决策

| 需求 | 首选 | 备注 |
|---|---|---|
| 线性排布 | Row / Column | 配 justifyContent / alignItems |
| 层叠 | Stack | alignContent 控制对齐 |
| 等分/流式 | Flex / Grid | Flex 频繁换行性能不如 Column+Row 组合 |
| 长列表 | List + LazyForEach | 必配 cachedCount;数据源实现 IDataSource |
| 轮播 | Swiper | |
| 相对布局 | RelativeContainer | 复杂相对约束,减少嵌套层级 |
| 响应式多端 | GridRow / GridCol | 见 multi-device-adaptation 技能 |

嵌套深度直接影响渲染性能:超过约 10 层时优先考虑 RelativeContainer 拍平。

## 路由:Navigation 优先于 router

新代码一律用 **Navigation + NavDestination + NavPathStack**(支持页面栈操作、
转场动画、一多自适应分栏);`@ohos.router` 是旧方案,仅维护存量代码时使用。
页面间传参用 NavPathStack 的 param,回传用 pop 携带结果。

## 列表性能三件套(列表卡顿先查这三项)

1. **LazyForEach** 替代 ForEach(数据 > 一屏必须);数据源正确实现增删通知,
   否则更新不刷新。
2. **cachedCount** 设为约一屏条目数,预加载减少滑动白块。
3. **@Reusable 组件复用**:列表项组件标注 @Reusable 并实现 aboutToReuse
   更新数据,避免反复创建销毁。

## 复用机制选型

- 结构复用 → `@Builder`(本组件)/ 全局 @Builder;按引用传参用对象字面量保持响应式。
- 纯样式复用 → `@Styles`(通用属性)/ `@Extend(组件)`(组件特有属性,可传参)。
- 跨页面复用 → 抽公共 HAR 模块(见 hvigor-build 技能)。

## 动画速查

- 状态驱动:`animateTo({duration, curve}, () => { 改状态 })` —— 最常用。
- 属性动画:组件 `.animation()` 修饰需要动画的属性(注意属性书写顺序,
  animation 只对其之前的属性生效)。
- 页面/组件转场:Navigation 自定义转场、`transition()`。
- 优先用系统 curve(如 curves.spring 系列),手写贝塞尔参数难以达到系统质感。

## 高频细节

- 尺寸单位:vp(布局)、fp(字体,跟随系统字号);写死 px 是适配事故源头。
- 资源引用:`$r('app.string.xxx')` / `$r('app.media.xxx')`,字符串硬编码
  会在国际化与审核环节返工。
- 弹窗:优先 promptAction / 自定义 @CustomDialog;避免用全屏 Stack 模拟弹窗。
- 图片:网络图配占位与错误图;大图列表注意 Image 的 syncLoad 与采样。

## 写界面的工作流

1. 先问/看设计稿的多端要求,决定是否引入栅格断点(转 multi-device-adaptation)。
2. 静态结构 → 抽 @Builder/@Styles → 接状态(转 arkts-syntax 状态管理)→ 动画最后加。
3. 涉及具体组件属性签名不确定时,先在本地 SDK `ets/api/@internal/component/`
   相关声明文件中确认,再写代码。
