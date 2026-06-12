---
name: arkui-window
description: >-
  鸿蒙窗口管理与屏幕适配: 窗口创建/移动/缩放、悬浮窗、分屏、屏幕方向/密度/
  刷新率。涉及多窗口、悬浮窗权限、横竖屏切换时使用本技能。
license: MIT
requires: 0-core-index
kits: [@kit.ArkUI]
metadata:
  target-platform: "HarmonyOS 6.x / API 20-24"
---

# 窗口管理与屏幕适配

## 核心入口：WindowStage

所有窗口操作从 `WindowStage` 开始。Ability 的 `onWindowStageCreate` 回调
是唯一合法的窗口创建时机——不要在 Ability 外部或异步回调中凭空创建窗口。

```
WindowStage → createSubWindow() → WindowClass
            → getMainWindow()   → WindowClass(主窗口)
```

`WindowClass` 是操作句柄：移动、缩放、设置亮度、锁定方向、全屏切换均通过它。

## 窗口类型选型

| 窗口类型 | 用途 | 关键约束 |
|---------|------|---------|
| 主窗口(mainWindow) | 应用主界面 | 自动创建，跟随 Ability 生命周期 |
| 子窗口(subWindow) | 对话框、浮层、辅助面板 | 需 WindowStage 显式创建，跟随主窗口销毁 |
| 系统窗口(systemWindow) | 悬浮窗(PIP/全局浮层) | 需 `ohos.permission.SYSTEM_FLOAT_WINDOW` 权限 |
| 分屏窗口 | 多窗格并行 | 支持上下/左右分屏，由系统手势与 `splitScreen` 模式触发 |

## 悬浮窗(PIP)设计与权限

悬浮窗必须走 `window.createWindow` 并指定 `WindowType.TYPE_FLOAT`。
权限路径：
1. module.json5 声明 `ohos.permission.SYSTEM_FLOAT_WINDOW`
2. **用户需在设置中手动开启"悬浮窗权限"**——此权限为 user_grant 且无法
   通过弹窗引导，必须在首次使用时引导用户跳转系统设置页
3. 悬浮窗尺寸受系统限制(通常 25%-75% 屏幕)，超出会被裁剪

## 屏幕方向锁定与监听

```ts
windowClass.setPreferredOrientation(window.Orientation.PORTRAIT); // 锁定竖屏
windowClass.setPreferredOrientation(window.Orientation.AUTO_ROTATION); // 跟随传感器
```

- 通过 `display.on('change')` 监听旋转事件，**不要轮询方向**
- 横竖屏切换会导致 Activity 重建(类似 Android configChange)，需在
  `onConfigurationUpdate` 中保存/恢复状态
- 折叠屏展开/闭合也会触发方向变更，需一并处理

## 屏幕密度适配策略

| 密度等级 | dpi 参考 | 资源目录 |
|---------|---------|---------|
| sdpi | 120-160 | resources/sdpi |
| mdpi | 160-240 | resources/mdpi(默认) |
| ldpi | 240-320 | resources/ldpi |
| xldpi | 320-480 | resources/xldpi |

- 图片资源放多密度目录，系统按屏幕自动选择；代码中尺寸用 vp 单位
- `display.getDefaultDisplaySync().densityPixels` 获取当前密度值
- 不要硬编码像素值——"300px"在轻量手表上可能超出整屏

## 多窗口协作

- 主窗口与子窗口间通过 `windowClass.on('avoidAreaChange')` 监听安全区
  (刘海/圆角/导航栏)避免内容遮挡
- 子窗口失去焦点时考虑 `hide()` 而非 `destroy()`——频繁创建/销毁导致闪烁
- 分屏时布局需响应窗口宽高变化，用 `on('windowSizeChange')` 动态调整

## 排查清单：“窗口异常/浮窗不显示”

1. 检查 WindowStage 回调中是否调用了 `loadContent`——窗口创建不等于加载内容。
2. 悬浮窗：权限是否授予？用户是否手动开启了"显示悬浮窗"开关？
3. 分屏不支持：检查 module.json5 中 `supportSplitScreen` 是否设为 true。
4. 横竖屏切换崩溃：onConfigurationUpdate 中是否有未处理的 null 引用？
