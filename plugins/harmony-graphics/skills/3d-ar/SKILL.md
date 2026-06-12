---
name: 3d-ar
description: >-
  鸿蒙3D/AR: 3D渲染(ArkGraphics 3D)、AR Engine空间感知、
  动作跟踪、光照估计、平面检测。涉及AR试穿、空间测量、
  虚拟摆放、3D展示时使用本技能。
license: MIT
requires: 0-graphics-index
kits: ["@kit.ArkGraphics3D", "@kit.AREngineKit"]
metadata:
  target-platform: "HarmonyOS 6.x / API 20-24"
---

# 3D 与 AR：渲染、空间感知与虚实融合

## 两 Kit 定位

| Kit | 职责 | 输出 |
|-----|------|------|
| **ArkGraphics 3D** | 3D 场景渲染（模型加载、光照、材质、相机） | 渲染帧 |
| **AR Engine Kit** | 空间感知（SLAM、平面检测、动作跟踪、光照估计） | 位姿数据 + 空间锚点 |

**协作关系**：AR Engine 提供"真实世界在哪儿"→ ArkGraphics 3D 负责"虚拟物体画在哪儿"。

## ArkGraphics 3D：场景构建五要素

```typescript
import { Scene, Camera, Light, Model, Material } from '@kit.ArkGraphics3D';

// 1. 场景容器
let scene = new Scene();
scene.setBackgroundColor({ r: 0.1, g: 0.1, b: 0.1, a: 1.0 });

// 2. 相机——必须且唯一
let camera = new Camera();
camera.setPosition(0, 2, 5);    // 如人眼高 2m，距物体 5m
camera.lookAt(0, 0, 0);         // 看向场景中心
scene.setCamera(camera);

// 3. 光照——默认纯黑，不加灯看不见
let light = new Light({ type: 'directional' });
light.setDirection(-0.5, -1, -0.5);
light.setIntensity(1.0);
scene.addLight(light);

// 4. 模型加载
let model = scene.loadModel('/path/to/model.glb'); // 支持 glTF/GLB
model.setPosition(0, 0, 0);

// 5. 材质
let material = new Material();
material.setBaseColor({ r: 1, g: 0, b: 0, a: 1 });
model.setMaterial(material);
```

**三个不变量**：
1. 不加 Light 的场景 = 全黑画面——DirectionalLight 是 3D 的"必须配置项"
2. glTF/GLB 是推荐格式（`@kit.ArkGraphics3D` 原生优先支持），OBJ/FBX 需自行转换
3. Scene 绑定的 Surface 来自 XComponent，分辨率 = XComponent 的物理像素

## AR Engine：SLAM 核心概念

AR 的核心是 **SLAM(同步定位与建图)**——设备边移动边建立环境地图：

```
设备启动 → 特征点提取 → 平面检测 → 建立世界坐标系 → 创建锚点(Anchor)
```

**六自由度位姿(6DOF Pose)**：AR Engine 每帧输出设备的 `position(x,y,z)` + `rotation(四元数)`。虚拟内容渲染时必须用这个位姿更新 Camera，否则不跟手。

## AR Engine 核心能力

| 能力 | 接口 | 用途 |
|------|------|------|
| 平面检测 | `ARPlaneTracking` | 识别桌面/地面，虚拟物品摆放 |
| 动作跟踪 | `ARBodyTracking` | 识别人体骨架，AR 试穿/动作捕捉 |
| 人脸跟踪 | `ARFaceTracking` | AR 眼镜/表情捕捉 |
| 光照估计 | `ARLightEstimate` | 虚拟物体打光匹配真实环境 |
| 命中测试 | `ARHitTest` | 点击屏幕确定空间中的对应位置 |

**平面检测调优**：
- 检测前提：环境有足够纹理特征（白墙/纯色桌面无法检测）
- `setPlaneFindingMode(ENABLE_HORIZONTAL)`：只检测水平面（桌面/地面）比全向检测快 2x
- 首次检测需 1-3 秒特征点积累，这期间不要创建锚点

## AR 应用骨架代码

```typescript
// 1. 启动 AR Session
let arSession = await arEngine.createSession();
arSession.addTrackMode('plane');    // 平面检测模式
await arSession.start();

// 2. 每帧更新
arSession.on('update', (frame: ARFrame) => {
  // frame.cameraPose → 更新 ArkGraphics 3D Camera
  camera.setFromPose(frame.cameraPose);
  
  // frame.planes → 检测到的平面列表
  if (frame.planes.length > 0 && !anchorCreated) {
    let plane = frame.planes[0]; // 取第一个平面
    anchor = plane.createAnchor(plane.centerPose);
    anchorCreated = true;
  }
  scene.render(); // 渲染 3D 场景
});

// 3. XComponent → Surface 绑定
xComponent.getXComponentSurfaceId(); // 给 ArkGraphics 3D 绑定渲染目标
```

## 排查清单

1. **AR 显示黑屏** → Camera 权限未授予（AR Session 需要 CAMERA）；检查 XComponent surfaceId 绑定
2. **平面不出现** → 纹理不足（对着白墙/纯暗环境）；移动设备，确保光线充足
3. **虚拟物体漂移** → 平面检测不稳定：创建锚点后持续追踪，用 `plane.updateMode = 'FIXED'` 固定
4. **3D 模型不显示但无报错** → 最常见是忘了加 Light；其次是模型路径错误（glTF 内部路径引用问题）
5. **渲染帧率低** → 模型面数过高（>50k 三角面慎用）、纹理过大（>2048×2048）；用 `LOD` 自适应降低精度

> 官方文档：[ArkGraphics 3D](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkgraphics3D-introduction) · [AR Engine](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arengine-overview)
