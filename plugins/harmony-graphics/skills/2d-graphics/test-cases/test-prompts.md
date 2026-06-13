# 测试提示词 — 2d-graphics

> 种子用例,取自仓库级回归集 `tools/evals/evals.json`。可按需补充边界条件 / 错误处理场景。

## 基础功能测试

### 场景 1
**提示词**：鸿蒙里做一个实时股票 K 线图,数据每秒更新,用 Canvas 组件画都卡了,怎么办?

**预期输出**：触发 2d-graphics;推荐 RenderNode 自绘制+DisplaySync 帧同步方案;给出 markContentDirty 脏区优化

### 场景 2
**提示词**：用 Canvas 画了一个签名板,导出的图很模糊,为什么?

**预期输出**：触发 2d-graphics;检查 Canvas 物理像素(vp2px),Retina 屏需 2x/3x;给出 OffscreenCanvas 高分辨率导出方案
