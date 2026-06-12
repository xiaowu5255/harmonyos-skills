---
name: notification
description: >-
  鸿蒙通知系统: Notification Kit 发布/更新/取消通知、通知授权、角标管理、
  通知渠道、跨设备协同通知。涉及推送、状态栏消息、桌面角标时使用本技能。
license: MIT
requires: 0-ecosystem-index
kits: [@kit.NotificationKit]
metadata:
  target-platform: "HarmonyOS 6.x / API 20-24"
---

# 通知系统

## 通知发布流程(严格顺序)

```
检查授权状态 → 未授权则请求授权 → 创建通知渠道(slot) → 构建通知请求 → 发布
```

跳过授权直接发——静默失败，用户看不到任何通知。跳过渠道创建——通知
可能按默认渠道归类，失去分类管理能力。

## 授权检查与请求

```ts
notificationManager.isNotificationEnabled().then(enabled => {
  if (!enabled) {
    notificationManager.requestEnableNotification().then(() => { /* 重新发布 */ });
  }
});
```

- 用户拒绝后 `requestEnableNotification` 不会再弹窗——必须引导用户
  手动到系统设置开启，或通过 `openNotificationSettings` 跳转设置页
- 在需要通知的功能入口处检查，而非 App 启动时——减少无意义的授权弹窗

## 通知渠道(NotificationSlot)分类管理

| 渠道类型 | 典型场景 | 行为差异 |
|---------|---------|---------|
| `SOCIAL_COMMUNICATION` | 聊天消息、好友请求 | 最高优先级，默认弹出横幅 |
| `SERVICE_REMINDER` | 订单状态、物流更新 | 中等优先级，静默显示 |
| `CONTENT_INFO` | 新闻推荐、内容更新 | 低优先级，可被用户归类到折叠区 |
| `CUSTOMER_SERVICE` | 客服消息 | 需用户主动订阅 |
| `OTHER` | 不归类的通知 | 默认渠道，建议避免 |

渠道创建后属性(名称/描述/重要性)可被用户修改——创建时设好默认值，
后续用 `getNotificationSlot` 检查当前状态。

## 通知模板

| 类型 | 适用场景 | 关键参数 |
|------|---------|---------|
| 基础文本 | 消息、提醒 | title + text + briefText(锁屏摘要) |
| 长文本 | 邮件预览、详细消息 | `NotificationLongTextContent` |
| 图片通知 | 图文消息 | `NotificationPictureContent` + 大图 URL |
| 进度条 | 下载、上传进度 | `NotificationProgressContent` + 进度值 |
| 媒体播放 | 音乐控制 | `NotificationMediaContent`(含播放/暂停/上一首/下一首等 ActionButton) |

## 角标(Badge)

```ts
notificationManager.setBadgeNumber(badgeNumber);
```

- 角标数字与通知挂钩——清除通知时角标自动递减
- 角标独立于通知：清除所有通知不等于角标归零，需显式调用 `setBadgeNumber(0)`
- 桌面图标角标由系统桌面渲染，应用无法自定义角标样式

## 通知点击跳转 Want

```ts
const wantAgentInfo = {
  wants: [{ bundleName: 'com.example.app', abilityName: 'MainAbility' }],
  actionType: wantAgent.OperationType.START_ABILITY,
  requestCode: 0,
};
notificationRequest.wantAgent = await wantAgent.getWantAgent(wantAgentInfo);
```

点击通知跳转目标页面时，通过 Want 中 parameters 传递上下文
(如聊天会话 ID、消息 ID)，在目标 Ability 的 `onCreate/onNewWant` 中解析。

## Push Kit 与本地通知选型

| 对比维度 | Push Kit(远程推送) | 本地通知 |
|---------|-------------------|---------|
| 来源 | 云端 Push 服务 | 应用本地触发 |
| 应用活着才能发 | 否(系统代发) | 是(需前台/长时任务) |
| 实时性 | 受长连接质量影响 | 即时 |
| 使用场景 | 远程消息、运营推送 | 下载完成、闹钟、本地提醒 |

**不要用本地通知模拟远程推送**——应用被冻结后本地通知不执行。

## 跨设备通知同步

用户登录同一华为账号的多设备间可自动同步通知：
- 需在 AGC 开通通知同步服务
- 通知渠道 type 设为 `SOCIAL_COMMUNICATION` 的会自动同步
- 同步的通知在任意设备上被清除后，其他设备同步清除

## 常见错误

| 错误 | 后果 | 修复 |
|------|------|------|
| 未检查授权直接发通知 | 通知静默丢弃 | 发布前 `isNotificationEnabled` |
| 每次发通知都创建新渠道 | 渠道膨胀、用户管理混乱 | 渠道只创建一次(幂等检查) |
| 通知 ID 重复 | 后发通知覆盖前一个 | 每个通知用唯一 requestCode/ID |
| 角标数只增不减 | 角标残留 | 清除通知后同步调 `setBadgeNumber` |
