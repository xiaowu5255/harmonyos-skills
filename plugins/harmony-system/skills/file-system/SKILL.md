---
name: file-system
description: >-
  鸿蒙文件管理: Core File Kit 沙箱文件读写、应用文件目录结构、用户文件访问、
  文件 URI 转路径。涉及读写文件、缓存管理、文件选择器时使用本技能。
license: MIT
requires: 0-system-index
kits: ["@kit.CoreFileKit", "@kit.FileManagerServiceKit"]
metadata:
  target-platform: "HarmonyOS 6.x / API 20-24"
---

## Overview

鸿蒙文件管理: Core File Kit 沙箱文件读写、应用文件目录结构、用户文件访问、 文件 URI 转路径。

## When to Use

- 涉及 读写文件 时
- 涉及 缓存管理 时
- 涉及 文件选择器 时

# 文件管理

## 沙箱目录结构(先理解这几个目录)

每个应用有自己独立的沙箱，路径通过 `Context` 获取——绝不能硬编码路径。

| 目录 | 获取方式 | 语义 | 清除时机 |
|------|---------|------|---------|
| `files/` | `context.filesDir` | 持久数据(文档、数据库、用户生成内容) | 卸载时或用户手动清理 |
| `data/` | `context.dataDir` | 应用私有数据 | 卸载时 |
| `cache/` | `context.cacheDir` | 缓存——随时可能被系统清理 | 系统空间不足时 |
| `temp/` | `context.tempDir` | 临时文件——应用退出后可能清空 | 应用进程退出时 |
| `preferences/` | `context.preferencesDir` | Preferences 持久化文件所在 | 卸载时 |

**关键纪律**：应用卸载时 `files/` 和 `data/` 下的所有内容会被删除——
需要持久保留的文件走备份/云存储，别依赖沙箱。

## 文件读写 API

```ts
import fs from '@ohos.file.fs';

// 打开文件
const file = fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
// 写入
fs.writeSync(file.fd, 'content');
// 读取
const buf = new ArrayBuffer(1024);
fs.readSync(file.fd, buf);
// 关闭(必须)
fs.closeSync(file);
```

- 用 `Sync` 版本避免回调地狱；大文件(>10MB)用 `read/write` 的异步版
- **打开文件后忘记 close 是内存泄漏和文件锁故障的第一来源**
- 批量小写合并——不要循环内每次写 1 字节

## 流式操作

```ts
const stream = fs.createStreamSync(filePath, 'r+');
stream.writeSync('data');
stream.closeSync();
```

流式更适合：追加日志、序列化大对象、管道式处理。流内部有缓冲区，
write 后未 close 可能导致尾部数据不完整。

## 文件 URI 与路径互转

| 来源 | 格式 | 转换 |
|------|------|------|
| FilePicker 返回 | `file://docs/storage/Users/...` URI | `fileUri.getPathFromUri(uri)` → 沙箱路径 |
| 应用内部 | `/data/storage/el2/base/haps/entry/files/...` 绝对路径 | 无需转换 |
| 其他应用分享 | URI | 先 `fileFs.open(uri)` 获取 fd 再操作,不转换路径 |

**URI 不是文件路径**——`file://` 开头的字符串不能直接传给 `fs.open`，
必须先通过 `fileUri.getPathFromUri()` 转换或直接用 `fs.open(uri)`。

## FilePicker / DocumentViewPicker(免权限选文件)

```ts
const picker = new picker.DocumentViewPicker();
picker.select({ maxSelectNumber: 1 }).then(uris => {
  const path = fileUri.getPathFromUri(uris[0]);
  // 现在可以读写该文件
});
```

- 用户通过 Picker 选择的文件，应用获得临时读写权限——不需要申请
  `ohos.permission.READ_MEDIA` 等存储权限
- Picker 返回的权限在应用进程存活期间有效，重启后需重新选取

## 大文件处理

策略分档为经验参考（阈值按设备内存与实测调整，非硬性规定）：

| 文件大小 | 策略 |
|---------|------|
| 小文件 | 一次性读写 sync |
| 中等文件 | 异步分块读写（每块数 MB 量级） |
| 大文件 | 流式 + 后台任务(长时任务 continuousTask) |

## 存储空间监控

```ts
fs.statvfs(path, (err, stat) => {
  console.log(`可用: ${stat.bfree * stat.bsize}`);
});
```

在写入前检查可用空间，不足时提示用户而非静默失败写入不完整文件。

## 排查清单：“文件读写失败/找不到”

1. 路径是 URI 还是绝对路径？URI 必须先转换。
2. 文件在 `cache/` 下？可能已被系统清理——cache 语义是不保证持久。
3. fd 泄漏：整个应用周期中打开过但未关闭的文件累计到系统 fd 上限就会
   拒绝后续所有 open。hilog 搜 "EMFILE" 或 "Too many open files"。
4. 用 Picker 选的文件在应用重启后无法访问——Picker 权限进程级有效。
