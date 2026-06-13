# 测试提示词 — arkts-syntax

> 种子用例,取自仓库级回归集 `tools/evals/evals.json`。可按需补充边界条件 / 错误处理场景。

## 基础功能测试

### 场景 1
**提示词**：我把一段 TypeScript 工具类复制进鸿蒙工程的 .ets 文件,编译报了一堆 arkts-no-any-unknown 和属性初始化错误,帮我改成能编译通过的写法

**预期输出**：触发 arkts-syntax;读取/询问 compatibleSdkVersion;按 ts-to-arkts 参考逐条改写;不使用 any

### 场景 2
**提示词**：鸿蒙页面里我修改了列表项对象的一个嵌套属性,数据变了但界面不刷新

**预期输出**：触发 arkts-syntax;识别为 V1 状态管理深层观察问题;给出 @Observed/@ObjectLink 或 V2 方案
