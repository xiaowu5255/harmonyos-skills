---
name: arkweb
description: >-
  鸿蒙 Web 容器开发: ArkWeb 组件、H5 混合开发、JS Bridge 通信、Cookie 管理、
  WebView 调试。涉及加载网页、JS 与 ArkTS 互调、Web 性能优化时使用本技能。
license: MIT
requires: 0-core-index
kits: ["@kit.ArkWeb"]
metadata:
  target-platform: "HarmonyOS 6.x / API 20-24"
---

## Overview

鸿蒙 Web 容器开发: ArkWeb 组件、H5 混合开发、JS Bridge 通信、Cookie 管理、 WebView 调试。

## When to Use

- 涉及 加载网页 时
- 涉及 JS 时
- 涉及 ArkTS 互调 时
- 涉及 Web 性能优化 时

# ArkWeb：Web 容器与混合开发

## 加载控制生命周期

Web 组件提供了完整的请求拦截链，理解执行顺序是排查加载问题的前提：

```
onInterceptRequest → onLoadIntercept → onPageBegin → onPageEnd → onPageVisible
```

| 回调 | 作用 | 典型用法 |
|------|------|---------|
| `onInterceptRequest` | 拦截资源请求，可返回自定义响应 | 离线缓存注入、本地资源替换、请求重定向 |
| `onLoadIntercept` | 拦截页面导航(URL 跳转) | URL 白名单校验、DeepLink 拦截、外链跳转控制 |
| `onPageBegin/End` | 页面加载起止 | 加载进度条、性能埋点 |
| `onPageVisible` | 页面渲染完成 | 页面可见后的操作，避免过早操作 DOM |

## JavaScript Proxy：JS Bridge 核心机制

```ts
// ArkTS 侧注册对象给 JS 调用
this.webController.registerJavaScriptProxy(jsObj, 'nativeBridge', ['method1', 'method2']);

// JS 侧调用: window.nativeBridge.method1(params)
```

- 必须在 `onControllerAttached` 之后、页面加载前注册；加载后注册无效
- 注册的方法名列表必须与 ArkTS 对象的方法完全匹配，写漏一个方法名 = JS 侧 silent undefined
- JS Bridge 数据传输有限制：复杂对象走 JSON.stringify，大量数据用 ArrayBuffer

## Cookie 同步策略

| 场景 | 方案 |
|------|------|
| ArkTS 登录后 Web 需要 cookie | 用 `web_webview.WebCookieManager` 写入 |
| Web 内登录后 ArkTS 需要 cookie | JS Bridge 回传 + ArkTS 存储 |
| WebView 间 cookie 隔离 | 不同 `WebCookieManager` 实例绑定不同 Web 组件 |

**陷阱**：系统 Web 内核运行在独立进程，cookie 写入为异步操作——
`setCookie` 后立即 navigate 可能出现 cookie 未生效。正确做法：
写入 → 监听回调 → 再导航。

## Web 调试模式

```ts
webview.WebviewController.setWebDebuggingAccess(true);
```

开启后可用 DevEco 内置 DevTools 或 PC Chrome 的 `chrome://inspect` 调试
Web 内容。**发布包务必关闭此开关**——否则为安全漏洞。

## 同层渲染混合方案

通过 `EmbeddedComponent` 实现 ArkUI 原生组件嵌入 Web 页面指定位置——
适用于 H5 性能不足的场景(地图、视频播放器、富文本编辑器)。
约束：
- 需要在 Web 侧通过 JS 传递嵌入位置坐标给 ArkTS 侧
- 嵌入组件的 z-order 由 Web 层控制，可能遮盖 H5 交互元素

## 安全策略

| 策略 | 配置 | 说明 |
|------|------|------|
| 混合内容阻止 | 默认阻止 HTTPS 页面加载 HTTP 资源 | 确需放行用 `mixedMode` 参数，但需评估风险 |
| 文件域访问 | 默认禁止 file:// 协议 | 仅在调试或内部工具场景放行 |
| JavaScript 开关 | 默认开启 | 纯静态内容可关闭以减少攻击面 |

## 排查清单：“Web 加载异常/JS Bridge 不通”

1. 检查 `onInterceptRequest` 是否有 return——返回非 null 时后续加载链被截断。
2. JS Bridge 方法名列表是否包含全部暴露方法？遗漏的方法 JS 侧调用无报错。
3. Cookie 写入后是否等待回调再导航？
4. 网页 HTTPS 但内嵌 HTTP 图片——被混合内容策略拦截，看 hilog 含 "Mixed Content" 的日志。
5. 调试模式是否已开启？未开启时 console.log 和 DevTools 均不可用。
