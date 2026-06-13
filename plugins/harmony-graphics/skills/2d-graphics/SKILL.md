---
name: 2d-graphics
description: >-
  鸿蒙2D图形: ArkGraphics 2D Canvas绘制、RenderNode自定义渲染、
  DisplaySync同步、离屏渲染与Snapshot。涉及自定义图表、
  手绘板、游戏2D界面、动画引擎时使用本技能。
license: MIT
requires: 0-graphics-index
kits: ["@kit.ArkGraphics2D"]
metadata:
  target-platform: "HarmonyOS 6.x / API 20-24"
---

# 2D 图形绘制：Canvas、RenderNode 与 DisplaySync

## 三条渲染路径

ArkGraphics 2D 提供三层抽象，由浅入深：

| 层级 | API | 适用场景 | 控制粒度 |
|------|-----|---------|---------|
| **声明式 Canvas** | `Canvas(context)` 组件内 | 简单图表、签名板 | 组件级重绘 |
| **RenderNode 自绘制** | 自定义 `FrameNode` + `DrawContext` | 数据可视化、实时仪表盘 | 逐帧控制 |
| **DisplaySync 同步** | `displaySync` 绑定帧回调 | 游戏引擎、物理模拟 | V-Sync 级同步 |

**选型原则**：静态图表用声明式 Canvas；需要频繁更新的实时展示用 RenderNode；需要帧同步的游戏/动效用 DisplaySync。

## 声明式 Canvas：快速上手

```typescript
Canvas(this.context)
  .onReady(() => {
    let ctx = this.context.getContext2D();
    // 坐标系：左上角原点，x右正，y下正
    ctx.beginPath();
    ctx.moveTo(50, 50);
    ctx.lineTo(200, 200);
    ctx.strokeStyle = '#FF0000';
    ctx.lineWidth = 3;
    ctx.stroke();
  })
```

**Canvas 三个不变量**：
1. `onReady` 回调中获取 context2D——此回调在组件测量完成后触发，在此之前 context 为 null
2. 每次绘制完毕需显式调 `invalidate()` 触发重绘，ArkUI 不会自动重绘 Canvas
3. Canvas 尺寸由父容器确定，宽高为 0 时不绘制。确保父布局给足空间

## RenderNode：自定义帧绘制

适合需要精细控制绘制时序的场景——K 线图、实时频谱、粒子效果：

```typescript
class MyRenderNode extends RenderNode {
  draw(context: DrawContext) {
    let canvas = context.canvas;
    // 拿到 Canvas 后与声明式 Canvas API 完全一致
    canvas.drawRect(/* ... */);
    canvas.drawCircle(/* ... */);
  }
}
```

**与声明式 Canvas 的关键差异**：
- `draw()` 由渲染管线主动调用，不用手动 invalidate
- 可通过 `invalidate(rect)` 标记脏区，渲染器只重绘该区域——高性能场景的核心优化手段
- 多个 RenderNode 按 z-order 叠加，下层先画、上层后画

## DisplaySync：V-Sync 级同步

```typescript
import { displaySync } from '@kit.ArkGraphics2D';

let sync = displaySync.create();
sync.setExpectedFrameRateRange({ min: 30, max: 60, expected: 60 });

sync.on('frame', () => {
  // 每帧在此更新绘制状态——如物理引擎 tick、动画插值计算
  myNode.invalidate(); // 标记 RenderNode 需重绘
});
sync.start();
```

**帧率控制决策**：
| 场景 | 帧率 | 理由 |
|------|------|------|
| 静态图表 | 按需 invalidate | 无变化不重绘 |
| 实时数据(1Hz) | 1fps | 数据更新频率低 |
| 仪表盘/频谱 | 15-30fps | 人眼可感知变化即可 |
| 动效/游戏 | 60fps | 流畅必须 |

## 离屏渲染与截图

```typescript
// 离屏 Canvas
let offscreen = new OffscreenCanvas(1080, 1920);
let ctx = offscreen.getContext2D();
// 绘制...
// 导出为 PixelMap
let pixelMap = offscreen.transferToImageBitmap();

// RenderNode 截图：通过 componentSnapshot 模块获取
import { componentSnapshot } from '@kit.ArkUI';
let snapshot = componentSnapshot.get(componentId);
```

**用法**：离屏渲染用于生成分享图片、水印合成——不在屏幕上显示但需要完整的绘制管线。

## 排查清单

1. **Canvas 不显示内容** → 检查宽高：0×0 的 Canvas 不绘制；确认 `onReady` 已触发
2. **绘制内容模糊** → 检查 Canvas 物理像素：用 `vp2px` 转换，Retina 屏需要 2x/3x 分辨率
3. **动画卡顿** → 减少每帧绘制命令数；拆分静态背景和动态前景到两个 RenderNode
4. **多次绘制叠加** → 忘记调 `clearRect(0, 0, w, h)` 导致上一帧残留
5. **文字绘制大小不一致** → 字体加载是异步的，在 `font.loadFont()` 的 then 回调中再绘制

> 官方文档：[ArkGraphics 2D](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkgraphics2d-introduction)
