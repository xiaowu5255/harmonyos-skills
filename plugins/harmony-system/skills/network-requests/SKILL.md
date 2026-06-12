---
name: network-requests
description: >-
  鸿蒙网络请求: HTTP 数据请求、WebSocket 双向连接、Socket 通信、弱网优化、
  网络状态监听、连接管理。涉及调用API、文件上传下载、实时通信时使用本技能。
license: MIT
requires: 0-system-index
kits: ["@kit.NetworkKit", "@kit.NetworkBoostKit"]
metadata:
  target-platform: "HarmonyOS 6.x / API 20-24"
---

# 网络请求与连接管理

## HTTP 请求生命周期(铁律)

```
创建 → 配置 → 请求 → 处理 → 销毁
http.createHttp() → .request(url, options) → .on('headersReceive'/...) → .destroy()
```

**每个 httpRequest 对象用完必须 destroy**——不 destroy 会导致连接泄漏、
端口耗尽，长时间运行的应用必然崩溃。绝对不要复用已 destroy 的实例。

## 请求模式选型

| 需求 | 方案 | 关键点 |
|------|------|--------|
| 标准 REST API | `http.createHttp()` | 关注超时设置、证书配置 |
| 大文件上传/下载 | 同上 + `expectDataType: http.HttpDataType.ARRAY_BUFFER` | 分片策略、断点续传 |
| 双向实时通信 | `webSocket.createWebSocket()` | 心跳保活、自动重连 |
| TCP/UDP 自定义协议 | `socket.constructTCPSocketInstance()` | 绑端口、数据粘包处理 |
| 局域网发现/组播 | `socket.constructUDPSocketInstance()` | 广播地址、端口绑定 |

## WebSocket 心跳与重连(必做模式)

```ts
const ws = webSocket.createWebSocket();
ws.connect(url, (err, ok) => { /* 连接成功开始心跳 */ });
// 心跳定时器 + 超时检测
// 断连后指数退避重连: 1s → 2s → 4s → ... → max 30s
```

- **绝对不要依赖系统 TCP keep-alive**——间隔太长(通常数十分钟),等发现
  断连时用户已经等崩溃
- 心跳间隔建议 30s,超时阈值 3 个心跳周期
- 重连时必须重新创建 WebSocket 实例，不可复用断连的实例

## 网络状态监听

```ts
const netConnection = connection.createNetConnection();
netConnection.register((error) => { /* 不重要 */ });
netConnection.on('netAvailable', callback);   // 有网
netConnection.on('netLost', callback);         // 断网
netConnection.on('netCapabilitiesChange', cb); // 网络能力变化(WiFi→蜂窝)
```

**不要用 `hasDefaultNet` 轮询**——轮询太消耗且不及时，用事件驱动。

## 弱网优化(NetworkBoostKit)

| 场景 | 优化手段 |
|------|---------|
| 请求超时 | 合理设置 connectTimeout/readTimeout,默认太长 |
| 弱网降级 | 图片缩略图、请求合并、本地缓存优先 |
| 网络切换 | WiFi↔蜂窝切换时中断的请求重试(指数退避) |
| 带宽预测 | NetworkBoostKit 提供网络质量评估,按质量动态度量请求 |

## 证书固定(Certificate Pinning)

```ts
httpRequest.request(url, {
  caPath: '/path/to/cert.pem',  // 指定 CA 证书
  clientCert: { /* 双向认证客户端证书 */ }
});
```

- 高安全场景(金融/支付)必须固定证书，防止中间人攻击
- 证书文件放 `entry/src/main/resources/resfile/` 下，打包进 HAP
- **证书过期会导致所有客户端断连**——建立证书轮换与远程更新机制

## 常见错误排查

| 现象 | 原因 | 修复 |
|------|------|------|
| `Connection timed out` | 超时时间太短或服务端不响应 | 检查 connectTimeout/readTimeout 是否设得过小(默认 60s 通常够用) |
| `SSL handshake failed` | 证书不符/过期/自签名未配置 | 检查 caPath 指向的证书与服务端是否匹配 |
| WebSocket 频繁断连 | 缺心跳、网络切换未处理 | 加心跳 + 监听 netCapabilitiesChange 触发重连 |
| `Socket already closed` | 复用了已 destroy 的实例 | 每次请求创建新 httpRequest,用完立即 destroy |
| 请求成功但响应为空 | 未设置 expectDataType | 默认返回 string,二进制下载需设 ARRAY_BUFFER |
