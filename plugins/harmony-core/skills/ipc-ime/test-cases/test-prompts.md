# 测试提示词 — ipc-ime

> 种子用例,取自仓库级回归集 `tools/evals/evals.json`。可按需补充边界条件 / 错误处理场景。

## 基础功能测试

### 场景 1
**提示词**：鸿蒙多进程架构里,主进程怎么调用子进程的方法?

**预期输出**：触发 ipc-ime;IPC Kit:服务端 RemoteObject stub→客户端 createProxy→sendMessageRequest;跨进程检查+序列化限制(Map/Set需手动)

### 场景 2
**提示词**：用 Canvas 自绘了一个编辑器,怎么在点击编辑区时弹出系统输入法?

**预期输出**：触发 ipc-ime;IME Kit:inputMethod.attach(true)+注册 inputAttribute;监听 insertText/deleteLeft 回调;通过 updateCursor 同步光标位置

### 场景 3
**提示词**：开发一个鸿蒙第三方输入法应用,需要继承哪个 Ability?

**预期输出**：触发 ipc-ime;继承 InputMethodExtensionAbility;module.json5 metadata 设 inputMethodType=INPUT_METHOD;键盘窗口用 startAbility 启动
