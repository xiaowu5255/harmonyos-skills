# 测试提示词 — telephony

> 种子用例,取自仓库级回归集 `tools/evals/evals.json`。可按需补充边界条件 / 错误处理场景。

## 基础功能测试

### 场景 1
**提示词**：鸿蒙 App 里做一个一键拨打客服电话的功能,怎么实现?

**预期输出**：触发 telephony;推荐 ohos.want.action.dial 拉起拨号盘(免权限);应用内 makeCall 需要 PLACE_CALL(system_basic 权限不可得)

### 场景 2
**提示词**：鸿蒙应用收到短信验证码后自动填充到输入框,怎么做?

**预期输出**：触发 telephony;监听 sms.on('smsChange')→正则提取→填入输入框;需要 READ_MESSAGES 权限且上架声明用途

### 场景 3
**提示词**：鸿蒙 App 怎么检测当前是 WiFi 还是 5G 网络?信号弱要提醒用户切换

**预期输出**：触发 telephony;radio.getNetworkState()→radioTech 字段判断;signalStrength<-100 视为弱信号
