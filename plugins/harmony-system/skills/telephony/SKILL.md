---
name: telephony
description: >-
  鸿蒙蜂窝通信: Telephony Kit 拨打电话、短信收发(含验证码自动填充)、
  网络状态监听、SIM卡管理。涉及通话界面、验证码、网络诊断时使用本技能。
license: MIT
requires: 0-system-index
kits: ["@kit.TelephonyKit"]
metadata:
  target-platform: "HarmonyOS 6.x / API 20-24"
---

# 蜂窝通信：通话、短信与 SIM 管理

## Telephony Kit 能力地图

```
Telephony Kit
  ├── 拨打电话(call)    → 拉起系统拨号 / 应用内拨号
  ├── 短信服务(sms)     → 发送短信 / 读取短信(验证码自动填充)
  ├── 网络状态(network) → 信号强度 / 网络类型(5G/4G/WiFi)
  └── SIM管理(sim)      → 卡槽信息 / ICCID / 运营商
```

## 拨打电话：两条路径

| 路径 | API | 权限 | 适用 |
|------|-----|------|------|
| 拉起系统拨号 | `startAbility` → `ohos.want.action.dial` | 无需 | 普通拨号 |
| 应用内拨号 | `telephony.call.makeCall()` | `ohos.permission.PLACE_CALL` | VoIP、呼叫中心 |

```typescript
// 路径1：拉起系统拨号盘——推荐做法
import { common, Want } from '@kit.AbilityKit';
let want: Want = {
  action: 'ohos.want.action.dial',
  uri: 'tel:10086'
};
context.startAbility(want);

// 路径2：应用内直接拨号（需 PLACE_CALL 权限 + 系统签名）
import { call } from '@kit.TelephonyKit';
call.makeCall('10086');
```

**不变量**：`ohos.want.action.dial` 只拉起拨号盘不直接呼出——用户必须点"拨打"按钮。这是 Google/华为共同的安全策略，防止恶意静默拨号。

## 短信服务

```typescript
import { sms } from '@kit.TelephonyKit';

// 发送短信——需要 ohos.permission.SEND_MESSAGES
sms.sendMessage({
  slotId: 0,                       // SIM 卡槽
  destinationHost: '10086',
  content: 'CXLL',                 // 内容
  sendCallback: (err, result) => {
    if (err) { /* 发送失败 */ }
  }
});

// 读取短信——用于验证码自动填充
// 需要 ohos.permission.READ_MESSAGES
sms.getAllMessages({}, (err, messages) => {
  // messages 中筛选验证码
});
```

**验证码自动填充最佳实践**：
1. 注册 `ohos.permission.READ_MESSAGES`
2. 监听短信数据库变化 `sms.on('smsChange')`
3. 正则匹配：`/(\d{4,8})/` 提取数字序列
4. 填入输入框 + 标记已读
5. 上架时声明短信用途——不声明会被驳回

## 网络状态监听

```typescript
import { radio } from '@kit.TelephonyKit';

// 获取当前网络类型
let networkState = radio.getNetworkState();
// networkState.radioTech: '5G'/'4G'/'3G'/'2G'/'WIFI'/'UNKNOWN'

// 监听网络变化
radio.on('networkStateChange', (state) => {
  if (state.radioTech === 'WIFI') { /* 切到WiFi，降速策略 */ }
  if (state.signalStrength < -100) { /* 信号弱，提示用户 */ }
});
```

## SIM 管理

```typescript
import { sim } from '@kit.TelephonyKit';

// 获取 SIM 卡信息
let simInfo = sim.getSimInfo(0);  // 卡槽0
// simInfo.iccId / simInfo.operatorName / simInfo.countryCode
// simInfo.isActive: SIM 是否激活
// simInfo.simState: READY / LOCKED / ABSENT

// 监听 SIM 热插拔
sim.on('simStateChange', (data) => {
  if (data.state === 'SIM_ABSENT') { /* 用户拔卡，注销登录 */ }
});
```

## 权限清单

| 操作 | 权限 | 级别 |
|------|------|------|
| 拨打电话 | `ohos.permission.PLACE_CALL` | system_basic |
| 读取短信 | `ohos.permission.READ_MESSAGES` | user_granted |
| 发送短信 | `ohos.permission.SEND_MESSAGES` | system_basic |
| 读取 SIM 信息 | 无需 | N/A |
| 读取网络状态 | 无需 | N/A |
| 通话状态监听 | `ohos.permission.READ_CALL_LOG` | user_granted |

## 排查清单

1. **makeCall 不生效** → `PLACE_CALL` 是 system_basic 权限，非系统应用无法获取；改用 `ohos.want.action.dial` 拉起拨号盘
2. **发送短信失败** → `SEND_MESSAGES` 也是 system_basic；第三方应用应走运营商 API 或服务端下发
3. **验证码无法自动填充** → `READ_MESSAGES` 授权弹窗用户拒绝率高；在首次进 App 时用 `requestPermissionsFromUser` 并解释用途
4. **双卡设备只读到卡 1** → `getSimInfo(slotId)` 用 `sim.getMaxSimCount()` 获取总槽位数遍历
5. **getNetworkState 返回 UNKNOWN** → 设备无蜂窝模块（平板 WiFi 版、模拟器）；真机上才会返回实际网络类型

> 官方文档：[Telephony Kit](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/telephony-kit)
