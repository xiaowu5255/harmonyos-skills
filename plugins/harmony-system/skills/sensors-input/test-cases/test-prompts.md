# 测试提示词 — sensors-input

> 种子用例,取自仓库级回归集 `tools/evals/evals.json`。可按需补充边界条件 / 错误处理场景。

## 基础功能测试

### 场景 1
**提示词**：做一个摇一摇功能,手机晃动时触发随机换一换,鸿蒙怎么实现?

**预期输出**：触发 sensors-input;给传感器订阅加速度计(sensor.on ACCELEROMETER);interval 单位纳秒(20ms=20000000ns);摇动检测用合加速度 >15 阈值

### 场景 2
**提示词**：鸿蒙平板配合手写笔做手写笔记,笔画怎么拿到压感和倾角?

**预期输出**：触发 sensors-input;Pen Kit pen.startHandwriting→on('stroke') 获取 {pressure,tiltX,tiltY};一笔成形 enablePrediction:true 减延迟

### 场景 3
**提示词**：鸿蒙应用要在 PC 模式下支持键盘快捷键 Ctrl+S 保存,怎么拦截按键?

**预期输出**：触发 sensors-input;Input Kit inputDevice.on('keyDown') 监听;检查 isCtrlKeyPressed + keyCode
