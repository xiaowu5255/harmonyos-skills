---
name: sharing-social
description: >-
  鸿蒙社交与分享: Share Kit 系统分享、App Linking Kit DeepLink 跳转、
  Contacts Kit 联系人读写、Calendar Kit 日历/日程。涉及分享内容到其他应用、
  DeepLink配置、读取通讯录时使用本技能。
license: MIT
requires: 0-ecosystem-index
kits: ["@kit.ShareKit", "@kit.AppLinkingKit", "@kit.ContactsKit", "@kit.CalendarKit"]
metadata:
  target-platform: "HarmonyOS 6.x / API 20-24"
---

# 社交与分享

## Share Kit：系统分享

### 分享模式选型

| 模式 | 适用场景 | 特点 |
|------|---------|------|
| 系统分享面板 | 分享文本/图片/链接到任意应用 | 用户自选目标 App,无需集成第三方 SDK |
| 应用内指定分享 | 微信好友、朋友圈等特定渠道 | 需目标 App 支持 URL Scheme 或系统分享接口 |
| 文件分享 | 大文件、文档 | 通过 `systemShare.sendData` + 文件 URI |

```ts
const shareData = new systemShare.ShareData({
  title: '分享标题',
  text: '分享文本内容',
  uri: fileUri, // 可选:文件 URI
});
const controller = new systemShare.ShareController(shareData);
controller.show(context); // 拉起系统分享面板
```

- 分享面板仅支持文本/图片/文件——复杂富文本需先序列化为支持的格式
- 目标应用是否接收成功**应用中无法获取结果**——系统分享面板关闭后无回调

## App Linking：DeepLink 跳转

### DeepLink vs Universal Link 选型

| 类型 | 格式 | 触发条件 | 跨平台 |
|------|------|---------|--------|
| DeepLink(Scheme) | `appschema://path` | 目标 App 已安装 | 仅鸿蒙(与 Android Scheme 不通用) |
| Universal Link(Android App Link 等价物) | `https://domain/path` | App 已安装或未安装(跳转落地页) | 跨平台(与 Android App Links 共用域名) |

### 延迟链接(Deferred Link)配置

用户未安装 App 时点击链接：
1. AGC 后台创建 DeepLink → 配置落地页(H5) → 绑定 App 下载
2. App 首次启动时通过 `appLinking.getDeferredLink()` 获取携带的参数
3. 参数通常用于"邀请码""推荐人 ID"等场景

```ts
appLinking.getDeferredLink().then(link => {
  // 解析 link 中的参数,跳转对应页面
});
```

### Universal Link 验证

- 域名根目录放置 `assetlinks.json`(鸿蒙格式,类似 Android 的
  `.well-known/assetlinks.json`)
- AGC 中需完成域名验证——未验证的 Universal Link 不触发 App 打开
- Scheme 和 Universal Link 都配时，系统优先用 Universal Link

## Contacts Kit：联系人管理

### 权限模型

| 操作 | 权限 |
|------|------|
| 读取联系人 | `ohos.permission.READ_CONTACTS`(user_grant) |
| 写入联系人 | `ohos.permission.WRITE_CONTACTS`(user_grant) |
| 仅读自己(系统联系人界面) | 无需权限(Picker 选择) |

```ts
// 通过系统 Picker 选择联系人——免权限方案
const picker = new contact.ContactPicker();
picker.selectContact().then(contact => { /* 联系人信息 */ });
```

- **优先用 ContactPicker**——大部分场景(选收件人、选联系人分享)不需要
  读取全部通讯录权限
- 全量读取通讯录用 `contact.queryContacts()`,需 READ_CONTACTS 权限

### 增删改查要点

- 联系人 ID(rawContactId)是联系人记录的唯一标识，**不要用姓名当 key**
  ——同名人查找会混乱
- 写操作是异步的，批量写入用 Promise.all 配合 await 保序
- 删除前先确认 rawContactId 对应记录仍然存在——被其他应用删除后写操作会失败

## Calendar Kit：日历与日程

```ts
calendarManager.createEvent({
  type: calendar.EventType.NORMAL,
  title: '会议标题',
  startDate: startTime,
  endDate: endTime,
  reminderMinutes: [15], // 提前 15 分钟提醒
});
```

- 日历权限：读写均需 `ohos.permission.READ_CALENDAR` + `ohos.permission.WRITE_CALENDAR`
- 日程提醒由系统日历应用发出，应用无需运行状态——与 reminderAgent(后台任务)互补
- 重复日程(reminders)的 RRULE 格式与 iCalendar(RFC 5545)兼容

## 排查清单：“分享失败/DeepLink 不跳转”

1. Share: 检查 `ShareData` 中 uri 指向的文件是否存在且可读。
2. DeepLink: 检查 module.json5 中 `skills` 是否配置了对应 URL Scheme/host:
   ```json
   { "actions": ["ohos.want.action.viewData"],
     "uris": [{ "scheme": "myapp", "host": "page" }] }
   ```
3. Universal Link: AGC 域名验证是否通过？assetlinks.json 是否可公网访问？
4. Contacts: 用 ContactPicker 替代全量权限——审核更易通过。
5. Calendar: 创建日程时 startDate 不能晚于 endDate——否则创建失败无报错。
