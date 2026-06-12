---
name: atomic-services-and-cards
description: >-
  鸿蒙元服务(原子化服务)与服务卡片开发:免安装形态约束、FormExtensionAbility
  卡片生命周期、卡片刷新与交互、卡片与应用数据通路。凡是涉及"元服务""原子化服务"
  "服务卡片""桌面卡片""万能卡片"开发、卡片不刷新/点击无响应类问题时使用本技能。
  元服务不是小型 App,直接套应用开发思路会在工程结构和包体上翻车。
license: MIT
requires: 0-core-index
metadata:
  target-platform: "HarmonyOS 6.x / API 20-24"
---

# 元服务与服务卡片

## 元服务 ≠ 小 App:三条根本差异

1. **免安装、即用即走**:严格包体上限(当前:单包含 dependency 分包 ≤ 2MB,同设备
   类型下所有包总和 ≤ 10MB,以当期官方文档为准),设计时按"分包 + 按需加载"思路而非整包思维。
2. **工程形态独立**:DevEco 创建时选元服务(Atomic Service)模板,与应用
   (Application)是不同工程类型,部分 API 与权限在元服务中不可用——写代码前
   先确认目标形态。
3. **分发入口不同**:负一屏/搜索/卡片/扫码等,意味着冷启动路径与参数携带
   (Want)是核心场景,必须处理好任意入口直达任意页面。

## 服务卡片架构

```
桌面(卡片使用方)←渲染← 卡片提供方:FormExtensionAbility(你写的)
                                  └── ArkTS 卡片页面(.ets,受限子集)
```
- 卡片运行在**受限环境**:ArkTS 卡片能用的组件与 API 是子集,不能 import
  任意模块;复杂逻辑放 FormExtensionAbility 或拉起的应用里。
- 关键生命周期:onAddForm(创建,返回初始数据)/ onUpdateForm(定时或主动
  刷新)/ onFormEvent(卡片消息)/ onRemoveForm,另有 onChangeFormVisibility /
  onAcquireFormState 等。

## 卡片刷新的三条通路(不刷新问题按此排查)

1. 定时/定点刷新:form_config.json(resources/base/profile/ 下)中 updateEnabled +
   updateDuration(**单位为 30 分钟的倍数**,取自然数)或 scheduledUpdateTime;两者同配时
   updateDuration 优先。系统对刷新频率有管控,过于频繁的配置不会生效。
2. 提供方主动刷新:formProvider.updateForm(formId, data)。formId 必须持久化
   (onAddForm 时存下来),丢了 formId 就丢了刷新能力——这是头号实现错误。
3. 使用方触发:卡片上 postCardAction 消息 → onFormEvent 处理后 updateForm。

## 卡片交互

postCardAction 三种 action:
- `router`:拉起 UIAbility 指定页面(带参数,处理好直达)。
- `message`:发消息给 FormExtensionAbility(轻交互,不拉起应用)。
- `call`:把指定 UIAbility 拉到后台并调用其方法(提供方需在 module.json5 声明
  `ohos.permission.KEEP_BACKGROUND_RUNNING`)。

> **实况窗(Live View Kit)≠ 服务卡片**:锁屏/状态栏胶囊/通知中心的实时进度(外卖、
> 出行、体育比分等)用实况窗,需申请资质权限、场景受白名单约束,可经 Push Kit 远程更新;
> 不要用服务卡片去模拟。另有"数据代理刷新"作为第三种卡片刷新机制(免拉起提供方)。

## 数据通路与限制

卡片与应用进程隔离,不能直接共享内存:小数据走卡片 data 与 postCardAction
参数;持久数据两边各自读同一存储(Preferences/数据库,见 data-storage)。

## 排查入口

卡片类问题先看:① form_config.json 配置 ② formId 是否持久化 ③ 刷新频率
是否被管控 ④ 卡片页面是否用了受限环境不支持的 API(hilog 中通常有提示)。

## 模板

`assets/` 下有可参考的样板:`form_config.json`(卡片配置含刷新字段注释)、
`WidgetCard.ets`(受限环境卡片页 + postCardAction 三种 action 示例)。字段与接口
以本地 SDK / 当期官方文档为准。
