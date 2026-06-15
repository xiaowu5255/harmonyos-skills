---
name: sensors-input
description: >-
  鸿蒙传感器与输入: Sensor Service Kit 加速度/陀螺仪/光线/距离/振动、
  Input Kit 多模输入(键盘/鼠标/手柄事件)、Pen Kit 手写笔。涉及摇一摇、
  计步器、游戏手柄、手写输入时使用本技能。
license: MIT
requires: 0-system-index
kits: ["@kit.SensorServiceKit", "@kit.InputKit", "@kit.PenKit"]
metadata:
  target-platform: "HarmonyOS 6.x / API 20-24"
---

## Overview

鸿蒙传感器与输入: Sensor Service Kit 加速度/陀螺仪/光线/距离/振动、 Input Kit 多模输入(键盘/鼠标/手柄事件)、Pen Kit 手写笔。

## When to Use

- 涉及 摇一摇 时
- 涉及 计步器 时
- 涉及 游戏手柄 时
- 涉及 手写输入 时

# 传感器与输入：感知、交互与手写笔

## 三 Kit 边界

| Kit | 职责 | 典型数据 |
|-----|------|---------|
| **Sensor Service Kit** | 物理传感器读数 + 振动马达控制 | x/y/z 加速度、光照 lux、旋转向量 |
| **Input Kit** | 外接输入设备事件(键盘/鼠标/手柄/触控板) | 按键码、鼠标坐标、摇杆值 |
| **Pen Kit** | 手写笔压力/倾角/一笔成形 | 压力等级、倾斜角、笔画序列 |

**决策原则**：设备旋转/摇一摇走 Sensor；键盘快捷键/鼠标光标走 Input；手写输入走 Pen。三者硬件独立，互不干扰。

## Sensor Service Kit：传感器选型表

| 传感器 | 常量 | 用途 | 权限 |
|--------|------|------|------|
| 加速度 | `SENSOR_TYPE_ID_ACCELEROMETER` | 摇一摇、步数计算 | 无需 |
| 陀螺仪 | `SENSOR_TYPE_ID_GYROSCOPE` | 游戏旋转、VR 头部追踪 | 无需 |
| 光线 | `SENSOR_TYPE_ID_AMBIENT_LIGHT` | 自动亮度调节 | 无需 |
| 距离 | `SENSOR_TYPE_ID_PROXIMITY` | 接电话时灭屏 | 无需 |
| 旋转向量 | `SENSOR_TYPE_ID_ROTATION_VECTOR` | 指南针、AR 方向 | 无需 |
| 心率 | `SENSOR_TYPE_ID_HEART_RATE` | 健康监测 | `ohos.permission.READ_HEALTH_DATA` |

### 传感器生命周期

```typescript
import { sensor } from '@kit.SensorServiceKit';

// 订阅加速度——不需要权限，直接 on
sensor.on(sensor.SensorId.ACCELEROMETER, {
  interval: 20000000,  // 20ms 采样间隔(纳秒)，即 50Hz
  callback: (data) => {
    console.info(`ax=${data.x}, ay=${data.y}, az=${data.z}`);
    // 摇一摇检测：sqrt(ax² + ay² + az²) > 15
  }
});

// 用完必须取消
sensor.off(sensor.SensorId.ACCELEROMETER);
```

**不变量**：
1. `on()` 返回后立即开始采样——不需要 `start()`
2. `interval` 单位是**纳秒**，不是毫秒。20ms = 20000000ns，写错单位 = 传感器不工作
3. 切后台后传感器**自动暂停**，回到前台自动恢复。不要在 `onBackground` 里手动 off
4. 高采样率 (>100Hz) 耗电显著，游戏设 50-100Hz，省电场景 10-20Hz

### 振动

```typescript
import { vibrator } from '@kit.SensorServiceKit';

vibrator.startVibration({
  type: 'time',       // 按时长振动
  duration: 500       // ms
}, { usage: 'alarm' }); // alarm(闹钟)/notification(通知)/touch(触摸反馈)
```

**震动类型决策**：通知用 `usage: 'notification'`，闹钟用 `usage: 'alarm'`——系统静音模式下前者会压低震动强度。

## Input Kit：外接设备事件

Input Kit 负责 ArkUI **触摸事件之外的**硬件输入——键盘、鼠标、游戏手柄、触控板。

### 快捷键监听

```typescript
import { inputDevice } from '@kit.InputKit';

// 监听键盘按键（系统级快捷键拦截）
inputDevice.on('keyDown', (event) => {
  if (event.keyCode === 2074 && event.isCtrlKeyPressed) {
    // Ctrl+S 保存
  }
});
```

### 光标控制（PC 模式）

```typescript
// 设置自定义光标样式
inputDevice.setPointerStyle(windowClass, 'resize_left_right');

// 获取鼠标位置
inputDevice.on('mouseMove', (event) => {
  console.info(`x=${event.x}, y=${event.y}`);
});
```

## Pen Kit：手写笔

手写笔的独特能力——压力感应、倾角检测、一笔成形（系统自动平滑手写）：

```typescript
import { pen } from '@kit.PenKit';

// 手写输入——自动识别笔画
pen.startHandwriting(inputMethodAbility, {
  recognitionLanguage: 'zh-CN',
  enablePrediction: true     // 开启笔迹预测
});

pen.on('stroke', (stroke) => {
  // stroke.points: [{x, y, pressure, tiltX, tiltY}]
  // stroke.type: 'pen' / 'eraser'
});
```

**一笔成形的坑**：只在支持手写笔的平板设备上生效。手机上 Pen Kit API 虽然可调用但无实际硬件。

## 排查清单

1. **传感器无回调** → `interval` 单位错用了毫秒；检查后台是否暂停（前台恢复自动重连）
2. **游戏手柄按键不响应** → Input Kit 事件优先级低于 ArkUI 手势系统；需用 `inputDevice.on` 而非 `onTouch`
3. **手写笔画不连续** → `enablePrediction: false` 导致笔迹跟手慢；开启预测可降低感知延迟
4. **心率传感器返回空** → 检查 `ohos.permission.READ_HEALTH_DATA` 权限 + 设备是否配备心率传感器
5. **振动对 elderly 模式不减弱** → 使用 `usage: 'alarm'` 时系统会跳过静音策略，非闹钟场景用 `notification` / `touch` 更合适

> 官方文档：[Sensor Service Kit](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/sensor-service-kit) · [Input Kit](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/input-kit) · [Pen Kit](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/pen-kit-guide)
