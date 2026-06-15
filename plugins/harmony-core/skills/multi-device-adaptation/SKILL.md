---
name: multi-device-adaptation
description: >-
  一次开发多端部署(一多):断点系统与响应式布局、GridRow/GridCol 栅格、
  折叠屏/平板/PC 自由窗口适配、多目标设备工程组织。凡是涉及适配平板/折叠屏/
  2in1(PC 形态)、横竖屏、窗口尺寸变化导致 UI 错乱,或设计稿要求多端一致时
  使用本技能。HarmonyOS 6 周期新设备形态(含 PC 形态)持续增加,一多是必修课。
license: MIT
requires: 0-core-index
metadata:
  target-platform: "HarmonyOS 6.x / API 20-24"
---

## Overview

一次开发多端部署(一多):断点系统与响应式布局、GridRow/GridCol 栅格、 折叠屏/平板/PC 自由窗口适配、多目标设备工程组织。HarmonyOS 6 周期新设备形态(含 PC 形态)持续增加,一多是必修课。

## When to Use

- 涉及 适配平板 时
- 涉及 折叠屏 时
- 涉及 2in1(PC 形态) 时
- 涉及 横竖屏 时
- 涉及 窗口尺寸变化导致 UI 错乱 时
- 涉及 或设计稿要求多端一致 时

# 一次开发多端部署(一多)

## 设计哲学:按窗口断点设计,不按设备设计

不要写"如果是平板就……"——同一台折叠屏展开/折叠、PC 自由窗口拖拽,设备没变
窗口在变。一切以**窗口尺寸断点**为准:

| 断点 | 窗口宽度(vp) | 典型形态 |
|---|---|---|
| xs | [0, 320) | 超小窗口(如极窄分屏) |
| sm | [320, 600) | 直板手机竖屏 |
| md | [600, 840) | 折叠屏展开/手机横屏 |
| lg | [840, +∞) | 平板/PC 窗口 |

以上为 GridRow 默认四档官方阈值;可在 `GridRow.breakpoints` 自定义启用 xl/xxl 适配 PC 大窗。
监听方式:窗口对象的尺寸/断点变化事件,或 GridRow 的 onBreakpointChange,把当前断点存入
状态驱动布局。

## 响应式工具箱(按改造成本从低到高)

1. **自适应能力**:拉伸(flexGrow/flexShrink)、均分、占比(layoutWeight)、
   缩放——不改结构,优先用。
2. **栅格**:GridRow/GridCol,按断点配 span(如 `{ sm: 12, md: 6, lg: 4 }`),
   表单与卡片流的标准解法。
3. **断点条件渲染**:同一数据,sm 单列 / lg 双栏(典型:Navigation 自动
   单栏↔分栏)。
4. **页面级重排**:侧边栏 SideBarContainer、平行视界(系统侧多窗口交互;基础能力早已
   支持,API 23/HarmonyOS 6.1.0 起新增应用自主控制分栏/双页启动等能力)。

## 折叠屏与 PC 形态要点

- 折叠屏:悬停/三态适配优先用官方组件 **FolderStack**(悬停态堆叠,upperItems 指定
  上半屏自动避折痕)、**FoldSplitContainer**(声明式适配展开/悬停/折叠三态);手动避让用
  `getCurrentFoldCreaseRegion` 取折痕区。避免在折痕区放关键操作。
- PC/2in1:窗口可任意拖拽 → 必须能在断点间平滑过渡;鼠标 hover 态、右键菜单、
  键盘快捷键按需补;不要锁死竖屏(orientation 配置检查)。

## 工程组织(多端差异大时)

```
common/   # HAR:逻辑、数据、通用组件(绝大部分代码应在这)
features/ # 各功能模块,内部做响应式
products/ # 各设备形态入口(差异实在抹不平时才分)
```
能用响应式解决就不要分 product——分裂入口是最后手段。

## 验收清单

提测前在 DevEco 多设备预览器(或真机)过:sm/md/lg 三档 + 横竖屏 + 折叠屏
展开过程拖动 + PC 窗口连续缩放,无截断、无重叠、无写死宽度溢出即合格。
写死 px/固定宽度是适配 bug 的第一来源,代码评审时重点抓。
