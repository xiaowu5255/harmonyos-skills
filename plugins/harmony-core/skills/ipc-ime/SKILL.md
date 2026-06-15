---
name: ipc-ime
description: >-
  鸿蒙跨进程通信与输入法: IPC Kit 进程间通信(RPC/远端订阅)、
  IME Kit 输入法开发与自绘编辑器集成。涉及多进程架构、
  输入法扩展时使用本技能。注:本地化(Localization)已归入 accessibility-i18n。
license: MIT
requires: 0-core-index
kits: ["@kit.IPCKit", "@kit.IMEKit"]
metadata:
  target-platform: "HarmonyOS 6.x / API 20-24"
---

## Overview

鸿蒙跨进程通信与输入法: IPC Kit 进程间通信(RPC/远端订阅)、 IME Kit 输入法开发与自绘编辑器集成。

## When to Use

- 涉及 多进程架构 时
- 涉及 输入法扩展 时

# 进程通信与输入法：IPC、RPC 与 IME

## 两 Kit 定位

| Kit | 职责 | 谁用 |
|-----|------|------|
| **IPC Kit** | 跨进程方法调用(RPC)、远端对象订阅 | 需要多进程架构的应用 |
| **IME Kit** | 开发输入法应用、自绘编辑器集成输入法 | 输入法厂商、自绘编辑器 |

> 注：原 ROADMAP 规划的 Localization Kit 已独立为 `accessibility-i18n` 技能的一部分。

## IPC Kit：RPC 三步法

HarmonyOS 的 IPC 基于**远端对象代理**模式——客户端持有服务端对象的本地代理，调用方法时由系统自动序列化/反序列化并路由到目标进程。

```
进程 A (Client)                进程 B (Server)
  │                              │
  ├─ connectService() ─────────►│ 注册远端对象(stub)
  │                              │
  ├─ proxy.method(args) ───────►│ stub.onRemoteMessageRequest()
  │  ◄──────────────────────────│ 返回结果
```

### 1. 服务端：创建 Stub 并注册

```typescript
import { rpc } from '@kit.IPCKit';

class MyServiceStub extends rpc.RemoteObject {
  onRemoteMessageRequest(code: number, data: rpc.MessageSequence,
                         reply: rpc.MessageSequence, option: rpc.MessageOption): boolean {
    if (code === 1) {
      let name = data.readString();
      reply.writeString(`Hello ${name}`);
      return true;
    }
    return false;
  }
}

// 在 ServiceExtensionAbility 中注册
let stub = new MyServiceStub('MyService');
```

### 2. 客户端：连接并调用

```typescript
import { rpc } from '@kit.IPCKit';

let proxy = rpc.RemoteObject.createProxy('MyService');
let data = rpc.MessageSequence.create();
let reply = rpc.MessageSequence.create();
data.writeString('HarmonyOS');
proxy.sendMessageRequest(1, data, reply, new rpc.MessageOption());
console.info(reply.readString()); // "Hello HarmonyOS"
```

### 3. 远端状态订阅

```typescript
// 服务端发布状态
stub.registerStateObserver((state) => { /* 状态变更通知客户端 */ });

// 客户端订阅
proxy.on('stateChange', (newState) => { /* 响应服务端状态变更 */ });
```

**不变量**：
1. IPC 只能是两个不同进程之间的通信——同进程内用 RPC 会报 `INVALID_ARGUMENT`
2. 序列化类型受限：`string`/`number`/`boolean`/`ArrayBuffer` 及 Plain Object——Map/Set/自定义类必须手动序列化
3. 协程异步：`sendMessageRequest` 可设 `MessageOption.ASYNC` 异步调用（不等待回复），适合日志上报等 fire-and-forget

## IME Kit：输入法开发

IME Kit 的核心不是"用输入法"而是"**写一个输入法**"——以及让自绘编辑器（Canvas/WebView 渲染的编辑框）对接系统输入法。

### 输入法应用骨架

```typescript
import { inputMethod } from '@kit.IMEKit';

// InputMethodExtensionAbility：输入法的 Service 载体
export default class MyInputMethod extends inputMethod.InputMethodExtensionAbility {
  onCreate(): void {
    // 创建键盘 UI
    this.context.startAbility(/* 键盘窗口 */);
  }

  onCommand(type: inputMethod.CommandType, value: object): void {
    if (type === inputMethod.CommandType.INSERT_TEXT) {
      // 向编辑框插入文字
      this.insertText(value as string);
    }
  }
}
```

### 自绘编辑框对接输入法

你的 App 用 Canvas / RenderNode 画了一个编辑框 → 系统输入法不知道这是一个编辑框：

```typescript
import { inputMethod } from '@kit.IMEKit';

let controller = inputMethod.getController();

// 1. 注册为输入框
controller.attach(true, {
  inputAttribute: {
    textInputType: inputMethod.TextInputType.TEXT,
    enterKeyType: inputMethod.EnterKeyType.SEARCH
  }
});

// 2. 接收输入回调
controller.on('insertText', (text: string) => { /* Canvas 绘制文字 */ });
controller.on('deleteLeft', () => { /* 删除光标前 */ });

// 3. 光标更新
controller.on('updateCursor', (cursor: inputMethod.CursorInfo) => {
  // 告知输入法光标位置 → 滑动选字候选栏出现在正确位置
  controller.updateCursor(cursor);
});
```

## 排查清单

1. **RPC 调不通** → 检查两端确实是不同进程；用 `getRunningProcesses()` 验证；同一进程内通信应使用 EventHub / emitter / AppStorage 等机制，而非试图"本地 RPC"
2. **sendMessageRequest 超时** → 默认同步模式 30s 超时；大数据用 `ASYNC` 异步模式避免阻塞
3. **自绘编辑框不弹键盘** → 确认 `inputMethod.attach(true)` 已调；检查 InputMethodExtension 在 module.json5 已注册
4. **IME Extension 无法收到 onCommand** → `InputMethodExtensionAbility` 的 metadata 中 `inputMethodType` 必须设为 `INPUT_METHOD`
5. **传递复杂对象报错** → 序列化限制：Map/Set/循环引用对象需先转 JSON 或用 ArrayBuffer 手动序列化

> 官方文档：[IPC Kit](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ipc-kit) · [IME Kit](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ime-kit)
