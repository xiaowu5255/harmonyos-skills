---
name: distributed
description: >-
  鸿蒙分布式能力:跨设备流转(接续/迁移)、多端协同、分布式数据对象与分布式
  数据同步、跨设备组网发现。凡是涉及"流转""接续""跨设备""多端协同""分布式"
  需求,或跨设备功能联调不通时使用本技能。分布式 API 的前置条件(同账号/
  同网络/权限)不满足时代码全对也跑不通,先验前置再查代码。
license: MIT
requires: 0-system-index
metadata:
  target-platform: "HarmonyOS 6.x / API 20-24"
---

# 分布式与跨设备协同

## 概念地图(术语先对齐)

- **流转**:统称,分两种——**接续**(任务在 A 设备暂停、B 设备继续,A 退出)
  和**协同**(多设备同时参与,如手机当平板的摄像头)。
- 底座:分布式软总线(发现/组网/传输,系统自动管理)。
- 数据层:分布式数据对象(内存对象跨端同步)、分布式 KV/RDB 同步(见
  arkdata-storage)、跨设备文件访问。

## 跑通任何分布式功能的前置清单(违反任一条 = 必失败)

1. 两台设备登录**同一华为账号**。
2. 同一局域网(或蓝牙近场,视能力而定)且均开启 Wi-Fi/蓝牙。
3. 双端都安装了**同 bundleName 同签名**的应用。
4. 声明并动态申请 `ohos.permission.DISTRIBUTED_DATASYNC` 权限(双端)。
5. 系统侧"多设备协同"开关开启。

联调不通时,先逐条验证这五项再看代码——这能消灭 80% 的"分布式 bug"。

## 接续(任务迁移)实现骨架

发起端 UIAbility:
- module.json5 中该 Ability 配置 `continuable: true`。
- 实现 `onContinue(wantParam)`:把状态写入 wantParam,返回 AGREE/REJECT。

接收端(同应用):
- 在 onCreate / onNewWant 中判断 launchReason 为接续,从 want.parameters
  恢复状态并恢复 UI。

注意:onContinue 中只放可序列化的轻量状态;大文件走分布式文件或先落盘。
API 23+ 增强了自定义组件跨 Ability 迁移能力,使用前确认 compatibleSdkVersion。

## 分布式数据对象(轻量状态同步)

适合小型、低频的协同状态(如共享白板的笔画元数据):创建分布式数据对象 →
双端 setSessionId 相同会话 → 监听 change 事件更新 UI。
不适合大数据/高频流(用分布式文件或自建传输)。

## 设备发现与目标选择

用设备管理接口(distributedDeviceManager)获取可信设备列表供用户选择目标
设备;不要硬编码 deviceId(每台设备、每次组网都可能不同)。

## 调试要点

- 分布式问题日志在双端都要抓(hilog 各看各的)。
- 模拟器对分布式支持有限,**分布式功能必须真机×2 验证**。
- 失败回调中的错误码要打印并查表,大多直接指向前置清单中某一条。
