---
name: connectivity
description: >-
  鸿蒙短距通信: Connectivity Kit(蓝牙/WiFi)、NearLink Kit(星闪)、NFC。
  涉及蓝牙设备配对联调、WiFi 直连、一碰传时使用本技能。
license: MIT
requires: 0-system-index
kits: [@kit.ConnectivityKit, @kit.NearLinkKit]
metadata:
  target-platform: "HarmonyOS 6.x / API 20-24"
---

# 短距通信：蓝牙 / WiFi / 星闪 / NFC

## 通信方式选型

| 场景 | 方案 | 带宽 | 距离 | 配对要求 |
|------|------|------|------|---------|
| 外设连接(耳机/手表/手环) | BLE 蓝牙 | ~1-2 Mbps | ~100m | 需配对 |
| 音频流、大文件推送 | BR/EDR 经典蓝牙 | ~2.1 Mbps | ~10m | 需配对 |
| 局域网高速传输 | WiFi P2P(WiFi Direct) | 数百 Mbps | ~50m | 无需AP |
| 超短距超高带宽 | 星闪 NearLink | 最高 12 Mbps(BLE 的 6 倍) | ~10m | 需配对 |
| 一碰/标签/支付 | NFC | ~424 Kbps | <4cm | 无需配对 |

## 蓝牙 BLE 扫描、连接、读写(核心流程)

```
扫描 → 发现设备 → 连接 GATT → 发现服务 → 读写特征值 → 使能通知 → 断连时释放资源
```

### 关键约束

| 步骤 | 约束 |
|------|------|
| 扫描 | 需要 `ohos.permission.ACCESS_BLUETOOTH` + **位置权限**(Android 转鸿蒙必踩的坑——BLE 扫描需要位置权限用于 Beacon 检测) |
| 连接 | 超时默认 10s,慢速设备(如某些传感器)可能不够,按需调整 |
| GATT 读写 | MTU 默认 23 字节,大数据先协商更大 MTU(`requestMtu`) |
| 通知使能 | 必须先写 CCCD 描述符(0x2902)使能通知,再读特征值——顺序反了收不到数据 |
| 资源释放 | 断开设备后关闭 GATT Client——不关会泄漏 BLE 连接资源,影响后续连接 |

## WiFi 状态监听与切换

```ts
wifiManager.on('wifiStateChange', (status) => {
  // 0: inactive, 1: active, 2: activating, 3: deactivating
});
wifiManager.on('wifiConnectionChange', (info) => { /* SSID/BSSID 变化 */ });
```

- **不要轮询 WiFi 状态**——用事件监听
- WiFi P2P 连接无需路由器,适合文件快传、投屏场景
- 弱网场景切换 WiFi↔蜂窝由系统自动管理,应用只需监听 `netCapabilitiesChange`(见 network-requests)

## 星闪 NearLink(近距离高速传输)

星闪是华为自研短距无线技术，在超短距(10m 内)场景下带宽和功耗优于蓝牙：

| 对比维度 | BLE | NearLink |
|---------|-----|----------|
| 峰值带宽 | ~2 Mbps | ~12 Mbps |
| 连接时延 | ~20ms | ~1ms |
| 并发连接数 | ~7 | ~256 |

适用场景：无线投屏、高清音频传输、车载互联、工业传感器采集。
集成方式与 BLE 类似：扫描 → 连接 → 发现服务 → 数据交互。

## NFC 标签读写

```ts
const nfcController = nfcTag.getNfcATag(tagInfo);
nfcController.connectTag().then(() => {
  nfcController.transmit(data).then(resp => { /* 标签返回数据 */ });
});
```

- 支持 NDEF 标准格式标签读写
- 前台调度模式：应用在前台时优先处理 NFC 发现事件
- **NFC 不需要蓝牙/位置权限**——但需要设备支持且 NFC 开关已打开

## 权限清单

| 功能 | 必需权限 |
|------|---------|
| BLE 扫描/连接 | `ohos.permission.ACCESS_BLUETOOTH` |
| BLE 管理(开关蓝牙) | `ohos.permission.MANAGE_BLUETOOTH` |
| BLE 扫描(位置依赖) | `ohos.permission.APPROXIMATELY_LOCATION`(API 20+) |
| WiFi 状态读取 | `ohos.permission.GET_WIFI_INFO` |
| WiFi P2P | `ohos.permission.GET_WIFI_PEERS_MAC` + `ohos.permission.GET_WIFI_LOCAL_MAC` |
| NFC | `ohos.permission.NFC_TAG` |

## 调试方法

- BLE: 用 nRF Connect 等标准 BLE 调试工具验证外设是否正常——先排除
  外设端问题再怀疑鸿蒙端代码
- WiFi P2P: hilog 搜 "WifiP2p" 关键词定位握手失败原因
- NFC: 用另一台 NFC 手机/空白标签验证，确保不是标签损坏
- 星闪: 目前需华为认证的星闪设备配合调试

## 排查清单：“蓝牙连不上/收不到数据”

1. 位置权限是否已授予？(BLE 扫描的隐藏前提)
2. CCCD 描述符(0x2902)是否已写 0x01 使能通知？
3. MTU 是否过小导致长数据被截断？
4. 上一次连接断开后 GATT Client 是否已关闭？（泄漏导致无法重连）
5. 外设是否进入深度休眠？尝试手动唤醒外设后重新扫描。
