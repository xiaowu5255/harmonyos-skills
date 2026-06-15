---
name: 3d-ar
description: >-
  鸿蒙3D/AR: 3D渲染(ArkGraphics 3D 的 Scene/Component3D)、AR Engine 空间感知
  (平面检测、命中测试、位姿跟踪、人脸/人体跟踪、光照估计)。涉及 AR 试穿、空间测量、
  虚拟摆放、3D 展示时使用本技能。
license: MIT
requires: 0-graphics-index
kits: ["@kit.ArkGraphics3D", "@kit.AREngine"]
metadata:
  target-platform: "HarmonyOS 6.x / API 20-24"
---

## Overview

鸿蒙3D/AR: 3D渲染(ArkGraphics 3D 的 Scene/Component3D)、AR Engine 空间感知 (平面检测、命中测试、位姿跟踪、人脸/人体跟踪、光照估计)。

## When to Use

- 涉及 AR 试穿 时
- 涉及 空间测量 时
- 涉及 虚拟摆放 时
- 涉及 3D 展示 时

## ⚠️ 常见误区与反模式

| 误区 | 正确做法 | 来源 |
|------|---------|------|
| `import { arEngine } from '@kit.AREngineKit'` | 正确包名是 `@kit.AREngine`(无 Kit 后缀) | AREngine 包名 |
| `let scene = new Scene()` 同步构造 | 官方**没有**同步构造;场景用 `Scene.load()` 异步返回 Promise | ArkGraphics 3D |
| `new ARPlaneTracking()` / `new ARBodyTracking()` | 没有独立能力类;能力由 `ARConfig.type` + `planeFindingMode` 决定 | ARConfig 文档 |
| `scene.loadModel('model.glb')` | `Scene.load()` 接收 glTF/GLB;OBJ/FBX 需自行转换 | glTF 支持 |
| 自定义场景模式默认有相机和手势 | 自定义模式下**无内置相机控制器**;手势与位姿更新需自己写 | Component3D 双模式 |
| 平面检测对纯白墙失败 | 需要环境有纹理特征;纯白墙/暗光/镜面都检测不到 | AR 平面检测前提 |

> **验证方法**:本领域 API 极易记错。**写码前必做**:
> 1. 查本地 SDK `@hms.*.d.ts` / `@ohos.graphics.scene.d.ts` 核对类名与签名
> 2. 调用前用 `arViewController.isARTypeSupported(...)` 判断设备能力
> 3. 不确定的 API 走 `harmony-docs-retriever` 查官方文档

# 3D 与 AR：渲染、空间感知与虚实融合

> ⚠️ 本领域 API 极易记错。**写码前必做**：在本地 SDK `@hms.*.d.ts` / `@ohos.graphics.scene.d.ts`
> 核对类名与签名，或用 harmony-docs-retriever 查官方。下文 API 已对照官方核实，但仍以本地 d.ts 为准。

## 两 Kit 定位与正确包名

| Kit | 导入 | 职责 |
|-----|------|------|
| **ArkGraphics 3D** | `@kit.ArkGraphics3D`（`@ohos.graphics.scene`） | 3D 场景渲染：Scene/Node/相机/光照/材质 |
| **AR Engine** | `@kit.AREngine`（注意**不是** `@kit.AREngineKit`） | 空间感知：位姿、平面、命中测试、人脸/人体、光照估计 |

- AR 侧两大入口：`arViewController.ARViewContext`（管 scene/session/resume/pause）与
  `arEngine.ARSession`（取帧 `getFrame()`、取可跟踪物 `getAllTrackables()`）。
- **协作关系**：AR Engine 给"真实世界在哪"（位姿+平面）→ ArkGraphics 3D 把虚拟物画上去。
- **能力探测**：调用前用 `arViewController.isARTypeSupported(...)` 判断设备是否支持，
  不支持的机型直接降级，别盲调。

## ArkGraphics 3D：场景以 `Scene.load()` 异步获取

官方没有 `new Scene()` / `new Camera()` / `scene.loadModel()` 这类构造写法。
场景通过 **`Scene.load()` 返回 Promise**，UI 侧用 **`Component3D`** 承载：

```typescript
import { Scene } from '@kit.ArkGraphics3D';

// 加载场景（可传 glTF/GLB 资源；具体重载以本地 d.ts 为准）
Scene.load().then((scene: Scene) => {
  // 对 scene 的相机/光照/节点操作，使用 @ohos.graphics.scene 提供的 API
  // 具体类型(SceneNode/SceneResource/相机/光照)签名以本地 d.ts 为准——不要照记忆写
}).catch((err: BusinessError) => {
  console.error(`load scene failed: ${err.code} ${err.message}`);
});
```

UI 承载（ArkUI 组件 `Component3D`）：

```typescript
// Component3D 两种模式：
// - 传 glTF 给 scene 选项 → 自动场景模式，框架托管基础相机/光照/手势(旋转缩放)
// - 传 Scene 对象 → 自定义场景模式，相机/光照/交互全由开发者用 ArkGraphics 3D API 管理
Component3D({ scene: this.sceneResource })
```

**三个不变量**：
1. **自定义场景模式下无内置相机控制器**——手势与相机位姿更新得自己写，否则虚拟物不跟手。
2. glTF/GLB 是原生优先格式；OBJ/FBX 需自行转换。
3. 渲染目标分辨率 = 承载组件的物理像素；与 XComponent 协作时注意 surface 尺寸。

## AR Engine：SLAM 与六自由度位姿

AR 的核心是 **SLAM（边移动边建图）**：设备启动 → 特征点提取 → 平面/锚点建立 → 持续位姿跟踪。
**6DOF 位姿**用 `ARPose`（位置 + 朝向）描述，每帧从 `ARFrame` 取，用来更新 3D 相机。

```typescript
import { arEngine } from '@kit.AREngine';
import { arViewController } from '@kit.AREngine';

// 1. ARViewContext 管理 scene 与 session（Stage 模型）
let ctx: arViewController.ARViewContext = new arViewController.ARViewContext();
// ctx.scene 设置 AR 场景；ctx.session 取得 ARSession（失败为 undefined）
let session: arEngine.ARSession | undefined = ctx.session;

// 2. 每帧取 ARFrame（实际帧循环由 ARView 渲染驱动）
let frame: arEngine.ARFrame = session!.getFrame();

// 3. 命中测试：从屏幕像素 (x,y) 投射射线，命中平面/点云
let hits: Array<arEngine.ARHitResult> = frame.hitTest(0, 0);
if (hits.length > 0) {
  let pose: arEngine.ARPose = hits[0].getHitPose(); // 命中点位姿 → 放置虚拟物
}

// 4. 取所有平面（ARTrackableType.PLANE），判断点是否落在平面多边形内
let trackables: Array<arEngine.ARTrackable> =
  session!.getAllTrackables(arEngine.ARTrackableType.PLANE);
if (trackables.length > 0) {
  let plane = trackables[0] as arEngine.ARPlane;
  let p: arEngine.ARPose = plane.getPose();
  plane.isPoseInPolygon(p); // true=在平面边界内
}

// 5. 生命周期：切前后台用 ctx.resume() / ctx.pause()
ctx.resume();
```

## AR 能力通过 `ARConfig` 配置（属性，不是独立类）

官方没有 `ARPlaneTracking` / `ARBodyTracking` / `ARLightEstimate` 这类独立能力类。
能力由 **`ARConfig` 配置对象的属性 + `ARType` 枚举**决定：

| 配置项 | 类型 | 说明 |
|--------|------|------|
| `type` | `ARType` | AR 能力类型（如 FACE / BODY 等，取值以 d.ts 为准） |
| `planeFindingMode` | `ARPlaneFindingMode` | 平面检测模式，默认 HORIZONTAL_AND_VERTICAL |
| `powerMode` | `ARPowerMode` | 功耗模式，默认 NORMAL |
| `focusMode` | `ARFocusMode` | 对焦模式，默认 FIXED |
| `cameraLensFacing` | `ARCameraLensFacing` | 前后摄；FRONT 仅当 type=FACE/BODY 生效（API 23+/6.1.0 起） |
| `maxDetectedBodyNum` | number | type=BODY 时最大检测人体数，默认 1、上限 2（API 23+/6.1.0 起） |
| `maxMapSize` | number | 地图内存上限(MB)，默认 800MB，可设区间见官方；按设备内存设，过大可能异常 |

> 平面检测、人脸跟踪、人体跟踪不是"调某个类"，而是"把 `ARConfig.type` / `planeFindingMode`
> 配对，再从 `ARFrame` / `getAllTrackables` 取结果"。`semanticDenseMode` 自 6.0.0(20) 起、
> 多人脸与前摄相关项自 6.1.0(23) 起——用前确认 `compatibleSdkVersion`。

**平面检测注意**：
- 前提：环境要有纹理特征（纯白墙/纯色无纹理面检测不到）。
- 只检测水平面时把 `planeFindingMode` 设为水平模式，比全向检测开销小。
- 刚启动需要一段时间积累特征点，这期间平面可能为空，别急着创建锚点。

## 排查清单

1. **AR 黑屏** → CAMERA 权限未授；或设备不支持（先 `isARTypeSupported`）；或 `ctx.session` 为 undefined（初始化失败）。
2. **平面检测不到** → 纹理不足（对着白墙/暗光）；移动设备、补光后重试。
3. **虚拟物漂移** → 位姿未每帧更新到 3D 相机；锚点跟踪不稳；环境特征少。
4. **3D 模型不显示但无报错** → 自定义场景模式忘了配光照/相机；或模型路径/glTF 内部引用错误。
5. **包名/类名报 cannot find** → 多半把 `@kit.AREngine` 写成 `@kit.AREngineKit`，或用了
   `new Scene()`/`ARPlaneTracking` 等不存在的写法——回到本地 d.ts 核对。

> 官方文档：[ArkGraphics 3D](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/graphics3d) · [AR Engine](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/arengine-api-arengine)
