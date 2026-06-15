---
name: accessibility-i18n
description: >-
  鸿蒙无障碍与本地化: Accessibility Kit 无障碍属性标注、屏幕朗读适配、
  长辈关怀模式、Localization Kit 多语言资源组织与格式化。涉及上架合规、
  国际化、适老化时使用本技能。
license: MIT
requires: 0-core-index
kits: ["@kit.AccessibilityKit", "@kit.LocalizationKit"]
metadata:
  target-platform: "HarmonyOS 6.x / API 20-24"
---

## Overview

鸿蒙无障碍与本地化: Accessibility Kit 无障碍属性标注、屏幕朗读适配、 长辈关怀模式、Localization Kit 多语言资源组织与格式化。

## When to Use

- 涉及 上架合规 时
- 涉及 国际化 时
- 涉及 适老化 时

# 无障碍与本地化：上架合规双支柱

## 上架驳回高频原因

HarmonyOS 应用市场的两道隐形门槛——**无障碍不合规**和**国际化缺失**，在 v0.2.0 审计中被列为最高优先级盲区。这两个问题不涉及业务逻辑，但上架审核一票否决。

| Kit | 审核关注点 | 不通过的典型表现 |
|-----|----------|---------------|
| Accessibility Kit | 所有可交互元素有 contentDescription | 按钮只有图标无文字描述 |
| Accessibility Kit | 色彩对比度满足 WCAG AA | 灰色文字在浅色背景上不可读 |
| Localization Kit | 资源文件有英文(en_US)版本 | 硬编码中文文本 |
| Localization Kit | 日期/数字/货币按区域格式化 | 用 `toString()` 而非 `Intl` |

## Accessibility Kit：三要素通道

无障碍的核心不是"加个描述"，而是让**线性朗读引擎**能按逻辑顺序依次访问每个交互元素。

### 1. 可访问性属性标注

```typescript
// ❌ 错误：屏幕朗读跳过
Button() { Image($r('app.media.play_icon')).width(24).height(24) }
  .onClick(() => { /* play */ })

// ✅ 正确：标注语义
Button() { Image($r('app.media.play_icon')).width(24).height(24) }
  .accessibilityText($r('app.string.play_button'))
  .accessibilityLevel('yes')              // 参与无障碍遍历
  .onClick(() => { /* play */ })
```

**关键属性**：
| 属性 | 作用 | 默认值 |
|------|------|--------|
| `accessibilityText` | 朗读内容 | 组件文本内容 |
| `accessibilityLevel` | `'yes'` 参与遍历 / `'no'` 跳过 / `'auto'` 系统判断 | `'auto'` |
| `accessibilityGroup` | 设为 `true` 将子元素合并为一个朗读组 | `false` |
| `accessibilityDescription` | 补充说明（与 text 不同的详细描述） | 空 |

**决策原则**：装饰性元素(分割线、背景图)设 `accessibilityLevel('no')`；每组语义关联元素(图标+标题+副标题)用 `accessibilityGroup(true)` 合并，避免逐个朗读。

### 2. 焦点顺序控制

无障碍引擎按 **DOM 绘制顺序** 遍历，但视觉顺序可能与 DOM 顺序不一致（如绝对定位、z-order 叠加）：

```typescript
Column() {
  // 使用 accessibilityGroup 将卡片内元素分组
  Row().accessibilityGroup(true) // 作为一个朗读单元
}
.accessibilityLevel('yes')
```

### 3. 长辈关怀模式

系统设置中开启"长辈关怀"后，应用需响应更大字体和更高对比度。**不变量**：应用不可写死字号或颜色，必须用资源引用：

```typescript
// ❌ 上架驳回
Text('标题').fontSize(14).fontColor('#999999')

// ✅ 通过
Text($r('app.string.title'))
  .fontSize($r('app.float.text_size_title'))
  .fontColor($r('app.color.text_secondary'))
```

`resource/` 目录按设备类型和显示模式组织 `float.json` / `color.json`，系统自动选取匹配值。

## Localization Kit：多语言组织三文件

```
entry/src/main/resources/
  ├── base/element/string.json       # 默认语言(中文)
  ├── en_US/element/string.json      # 英文
  ├── ja_JP/element/string.json      # 日语
  └── ar/element/string.json         # 阿拉伯语(RTL)
```

**不变量**：`base/` 是回退——缺失语言时会用 `base` 的字符串，因此 `base` 必须有所有 key。

### 格式化三件套

| 类型 | 用 `Intl` | 示例 |
|------|----------|------|
| 数字 | `Intl.NumberFormat('zh-CN').format(1234567)` | `1,234,567` |
| 日期 | `Intl.DateTimeFormat('en-US').format(new Date())` | `June 12, 2026` |
| 金额 | 必须带 `style: 'currency', currency: 'CNY'` | `¥1,234.00` |

**常见坑**：用 `new Date().toLocaleDateString()` 获取本地化日期——这在不同设备上行为不一致，必须用 `Intl.DateTimeFormat` 显式指定 locale。

### RTL 布局适配

阿拉伯语/希伯来语从右到左(RTL)阅读：
```typescript
// 使用 direction 属性自动翻转布局
Column()
  .direction(Direction.Auto)  // Auto 根据系统语言自动切换 LTR/RTL
```

**注意**：`Direction.Auto` 仅影响布局方向，不影响文本排列。文本内容本身由 Intl 控制，图标不自动镜像——箭头类图标需同时准备 `arrow_right.png` 和 `arrow_left_rtl.png`。

## 上架自检清单

### 无障碍（8 项，至少过 6 项）
- [ ] 所有可点击元素有 `accessibilityText`
- [ ] 装饰性元素设 `accessibilityLevel('no')`
- [ ] 信息密度大的卡片用 `accessibilityGroup`
- [ ] 无明显色差低于 WCAG AA 阈值（3:1）
- [ ] 字号引用 `$r('app.float.xxx')` 而非硬编码
- [ ] 颜色引用 `$r('app.color.xxx')` 而非硬编码
- [ ] 打开屏幕朗读服务走了一遍核心流程（设置→辅助功能→屏幕朗读）
- [ ] 长辈关怀模式下字体放大后无截断

### 本地化（5 项）
- [ ] 所有用户可见文本用 `$r('app.string.xxx')`，无硬编码
- [ ] `base/` 至少覆盖全部 key（作为回退）
- [ ] 日期/货币用 `Intl` 格式化，不用 `toString()`
- [ ] RTL 语言页面布局用 `Direction.Auto`
- [ ] 图标资源不含语言相关文字（用 SVG 或通用图标）

## 排查清单

1. **屏幕朗读跳过我的按钮** → 按钮内只有 Image 无 Text；加 `accessibilityText`
2. **长文本被截断** → 长辈模式字体放大到 40sp 以上；使用 `textOverflow({ overflow: TextOverflow.Ellipsis })` 兜底
3. **切换语言后部分文字不变** → 某处用了硬编码字符串而非 `$r()`；全局搜索 `fontSize(` / `fontColor(` 等可疑硬编码
4. **RTL 模式下箭头反了** → `Direction.Auto` 不镜像图片；需准备两张图标或使用 `mirror` 属性
5. **Intl 格式化不生效** → 确认 `locale` 字符串写对（`zh-CN` 不是 `zh_CN`）

> 官方文档：[Accessibility Kit](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/accessibility-kit) · [Localization Kit](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/localization-kit)
