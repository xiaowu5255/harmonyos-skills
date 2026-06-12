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
| 等分/流式 | Flex / Grid | Flex 有二次布局开销,性能敏感场景用 Row/Column 代替(官方建议) |
| 长列表 | List + LazyForEach | 必配 cachedCount;数据源实现 IDataSource |
| 轮播 | Swiper | |
| 相对布局 | RelativeContainer | 复杂相对约束,减少嵌套层级 |
| 响应式多端 | GridRow / GridCol | 见 multi-device-adaptation 技能 |

嵌套深度直接影响渲染性能:官方建议布局嵌套不超过 5 层,过深用 RelativeContainer
拍平(它不参与二次布局,扁平化收益明显)。

## 路由:Navigation 优先于 router

新代码一律用 **Navigation + NavDestination + NavPathStack**(支持页面栈操作、
转场动画、一多自适应分栏);`@ohos.router` 是旧方案,仅维护存量代码时使用。
页面间传参用 NavPathStack 的 param,回传通过 pushPath/pushDestination 的 onPop 回调
接收结果。API 12+ 首推**系统路由表**(各模块 `router_map.json` 声明)降低耦合,免手写跳转分支。

## 列表性能四件套(列表卡顿先查这四项)

1. **LazyForEach** 替代 ForEach(数据 > 一屏必须);数据源正确实现增删通知,
   否则更新不刷新。仅 List/ListItemGroup/Grid/Swiper/WaterFlow 支持懒加载。
2. **cachedCount** 设为约一屏条目数,预加载减少滑动白块。
3. **@Reusable 组件复用**:列表项组件标注 @Reusable 并实现 aboutToReuse
   更新数据,避免反复创建销毁;多类型列表项用 reuseId 区分复用池。
4. **组件冻结 freezeWhenInactive**:不可见列表项/页面不参与状态刷新,减少无效重渲染。

## 复用机制选型

- 结构复用 → `@Builder`(本组件)/ 全局 @Builder;按引用传参用对象字面量保持响应式。
- 纯样式复用 → **优先 AttributeModifier**(支持跨文件 export、继承组件 Modifier、可写
  业务逻辑动态设属性)。`@Styles`/`@Extend` 官方已声明**不再继续演进且不支持 export**,
  仅简单场景/存量代码使用。
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
- 弹窗:优先 `UIContext.getPromptAction().openCustomDialog`(配合 ComponentContent);
  `@CustomDialog`/CustomDialogController 为旧方案,复杂/动态弹窗官方已不推荐;避免用全屏 Stack 模拟弹窗。
- 图片:网络图配占位与错误图;大图列表注意 Image 的 syncLoad 与采样。

## 写界面的工作流

1. 先问/看设计稿的多端要求,决定是否引入栅格断点(转 multi-device-adaptation)。
2. 静态结构 → 抽 @Builder/@Styles → 接状态(转 arkts-syntax 状态管理)→ 动画最后加。
3. 涉及具体组件属性签名不确定时,先在本地 SDK `ets/api/@internal/component/`
   相关声明文件中确认,再写代码。
