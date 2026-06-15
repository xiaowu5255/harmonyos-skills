---
name: location-map
description: >-
  鸿蒙定位与地图深度: Location Kit 高精度定位(融合/GNSS/网络)、逆地理编码、
  Map Kit 地图显示/标记/路线。涉及获取位置、显示地图、POI搜索、导航规划时
  使用本技能。
license: MIT
requires: 0-ecosystem-index
kits: ["@kit.LocationKit", "@kit.MapKit"]
metadata:
  target-platform: "HarmonyOS 6.x / API 20-24"
---

## Overview

鸿蒙定位与地图深度: Location Kit 高精度定位(融合/GNSS/网络)、逆地理编码、 Map Kit 地图显示/标记/路线。涉及获取位置、显示地图、POI搜索、导航规划时 使用本技能。

## When to Use

- 涉及 获取位置 时
- 涉及 显示地图 时
- 涉及 POI搜索 时
- 涉及 导航规划 时

# 定位与地图

## 定位模式选型

| 模式 | 精度 | 功耗 | 适用场景 |
|------|------|------|---------|
| 高精度(融合定位) | 米级 | 最高 | 导航、跑步轨迹 |
| 低功耗(网络定位) | 几十米~百米级 | 低 | 天气、附近推荐、签到 |
| 仅设备(GNSS 卫星) | 米级(室外) | 高 | 户外运动、无网络环境 |

**选型原则**：精度需求越高，功耗越大。POI 推荐用低功耗，导航用高精度。
大部分场景不需要持续高精度——"我要当前位置"用单次定位，别开持续监听。

## 持续定位与后台定位

```ts
geoLocationManager.on('locationChange', (location) => { /* 位置更新 */ });
```

持续监听需要：
1. 权限 `ohos.permission.LOCATION`(前台) + `ohos.permission.LOCATION_IN_BACKGROUND`(后台)
2. 后台定位必须配合长时任务 continuousTask(见 background-tasks)
3. 状态栏必须显示定位指示标志(系统自动处理)

**省电铁律**：定位用完立即 `off('locationChange')`——忘记关闭定位监听
是功耗投诉的第一来源。

## 地理围栏(Geofence)

```ts
geoLocationManager.requestGeofence(geofenceRequest, wantAgent);
```

- 围栏半径最小 100m(GNSS 场景)，过大或过小都会影响触发精度
- 围栏触发依赖系统位置服务，**不是精确定时器**——进入/离开通知可能有
  数秒到分钟级的延迟
- 围栏数量有上限(约 100 个/应用)，超出前先清理无效围栏

## 逆地理编码

```ts
geoConvertManager.getAddressesFromLocation(location, (err, addresses) => {
  // addresses[0].locality / subLocality / thoroughfare / ...
});
```

- 依赖网络，无网时返回 GEOCODE_SERVICE_NOT_AVAILABLE
- 结果按精度从粗到细排列，`addresses[0]` 是最详细的地址描述

## Map Kit 集成

### 核心组件

| 组件 | 作用 |
|------|------|
| `MapComponent` | 地图视图容器 |
| `MapController` | 地图操作(CameraPosition 移动、缩放、旋转) |
| `Marker` | 地图标注点 |
| `Polyline` | 折线(路线) |
| `Polygon` | 多边形(区域) |
| `Circle` | 圆形覆盖物(周边范围) |

### CameraPosition 控制

```ts
mapController.setCameraPosition({
  target: { lat: 39.9, lng: 116.4 },
  zoom: 15,
  tilt: 45,       // 俯视角度
  bearing: 0,     // 旋转角度
});
```

**不要在列表滚动中实时更新地图 Center**——高频 `setCameraPosition` 导致
地图引擎卡顿。用 `animateCamera` 替代，或对调用做节流（间隔按实际体验调，约数百毫秒级）。

## POI 搜索与路线规划

- POI 搜索依赖联网，离线不可用(需结合离线地图方案)
- 路线规划返回的 `Route` 包含 steps(分段)、distance(总距离)、
  duration(预估时间)；直接用 `addPolyline` 在地图上绘制
- **路线规划不会自动更新**——用户偏离路线后需重新规划

## 功耗优化清单

1. 用单次定位替代持续监听——获取位置后立即取消注册。
2. 后台定位时必须配合 continuousTask——切后台仍持续定位会被系统强制停止。
3. 地理围栏半径不宜过小(<100m)——太小导致频繁进出触发，耗电严重。
4. 地图不可见时 pause 地图渲染——`mapController.onPause()`。
5. locationChange 回调中不要做重计算——放入 TaskPool(见 arkts-concurrency)。

## 排查清单：“定位不准/地图不显示”

1. 室内场景 GNSS 不可用——自动降级到网络定位，误差几十米是正常的。
2. Map Kit 是否在 AGC 已开通？未开通时 `MapComponent` 显示空白。
3. 后台定位权限是否已声明？仅声明前台权限 + 后台使用 = 切后台定位停止。
4. 定位回调频率异常高——检查 distanceInterval 参数是否设得过小。
