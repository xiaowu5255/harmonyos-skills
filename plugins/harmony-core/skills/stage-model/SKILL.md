---
name: stage-model
description: >-
  HarmonyOS Stage 模型:UIAbility 生命周期、AbilityStage、各类 ExtensionAbility、
  Want 与页面/应用拉起、module.json5 配置、Context 体系、应用内事件与数据共享。
  凡是涉及应用入口与生命周期问题、新建/配置 Ability、应用间跳转、后台前台切换行为、
  module.json5 改动时使用本技能。
license: MIT
requires: 0-core-index
metadata:
  target-platform: "HarmonyOS 6.x / API 20-24"
---

# Stage 模型

## 心智模型

```
App(bundle)
└── Module(entry/feature,各有 module.json5)
    └── AbilityStage(Module 级容器)
        ├── UIAbility(界面入口,可多实例,生命周期挂窗口)
        └── ExtensionAbility(无界面场景:卡片 Form/后台 Service/输入法/分享等)
```

## UIAbility 生命周期(顺序必须记准)

onCreate → onWindowStageCreate(在此 loadContent 加载首页)→ onForeground
⇄ onBackground → onWindowStageWillDestroy → onWindowStageDestroy → onDestroy

- **onNewWant**:实例已存在再次被拉起(singleton/specified 复用)走此回调,
  **不再走 onCreate/onWindowStageCreate**——复用实例时的新参数在这里取。
- **onWindowStageWillDestroy**:WindowStage 销毁前触发,此时窗口仍可用,常用于注销窗口事件订阅。
- 初始化重活不要放 onCreate/onWindowStageCreate 同步执行(拖慢冷启动,
  见 performance-tuning);放异步或首页 aboutToAppear 后。
- onBackground 内保存必要状态:鸿蒙后台管控严格,进程可能随时被回收
  (见 background-tasks)。
- launchType(module.json5):singleton(默认,单实例)/ multiton(旧称 standard)/ specified。
  跳转行为不符预期时先查这里,并配合 onNewWant 理解复用。

## Want 与拉起

- 显式 Want:指定 bundleName + abilityName,应用内/已知目标用。
- 隐式 Want:按 action/entities/uri 匹配,目标 Ability 需在 module.json5 的
  skills 中声明匹配规则;目标选择由系统裁决。
- 拉起方式:context.startAbility(Want);需要返回结果用 startAbilityForResult。
- 常见坑:隐式匹配失败报"无可用 Ability"——检查目标方 skills 声明与 Want
  字段是否逐项匹配,大小写敏感。

## 拉起其他应用(API 12+ 已收紧,重点)

从 API 12 起**不再推荐三方应用用显式 Want 拉起其他三方应用**:
- 拉**指定三方应用** → 首选 `openLink` + **App Linking**(https 链接 + 域名资产校验,安全);
  次选 Deep Linking(自定义 scheme,安全性低)。
- 拉**某一类应用**(浏览器/导航/邮件等) → `startAbilityByType`,由系统给候选列表。
- 应用内、拉系统应用仍可 startAbility。隐式 Want 由系统裁决,三方不能强拉指定三方应用。

## module.json5 高频字段

mainElement(入口 Ability)、abilities[](每个 Ability 的 name/srcEntry/
exported/launchType/skills)、requestPermissions[](权限声明,转
security-permissions)、extensionAbilities[]。
**改了 Ability 类文件名/路径,必须同步改 srcEntry,否则启动即崩。**

## Context 体系

UIAbilityContext(拉起、终止)/ ApplicationContext(全局、监听前后台)/
ExtensionContext 各司其职。工具类需要 context 时通过参数传入,
不要用全局变量缓存早期 context(模块化与多实例下会出错)。

## 应用内通信与共享

- 事件:EventHub(同 Ability 内)、emitter(进程内跨模块)。
- 状态共享:AppStorage(全局)、LocalStorage(Ability 级,可随 Want 传递)。
- 跨进程/跨应用 → 走 Want 参数或公共事件,不要试图共享内存对象。

## 诊断入口

"应用起不来/入口不对/跳转失败"类问题:① module.json5 的 mainElement 与
abilities 声明 ② srcEntry 路径 ③ launchType ④ 隐式 Want 匹配规则,
按此顺序核对,再看代码逻辑。
