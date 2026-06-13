# JsCrash(ArkTS/JS 层闪退)分析

> 适用:faultlogger `jscrash-*.log`,堆栈是 `.ets`/`.ts` 帧 + Error 类型 + message。
> 根因在 ArkTS 业务代码:未捕获异常 / Promise 拒绝 / 空值访问。

## 日志结构

1. **Error 类型 + message**——栈顶的错误描述决定方向:
   - `TypeError: Cannot read property 'x' of undefined/null`:空值/未初始化访问(最常见)。
   - `RangeError`:数组越界、递归爆栈。
   - 业务自定义 Error / 抛出的字符串。
   - 鸿蒙 API 抛出的 `BusinessError`(带 `code` 错误码)——拿错误码去查官方解释。
2. **ArkTS 调用栈**——`.ets` 文件 + 函数 + 行号。Release 需 SourceMap 还原(见下)。
3. **未捕获来源**——是同步抛出、还是 unhandled Promise rejection(异步链路断点)。

## 符号化(SourceMap)

Release 构建后栈帧可能指向混淆/编译后的位置,需用**该次构建产物的 SourceMap**还原到源码
行号。SourceMap 必须与崩溃包同一次构建,版本对不上则行号错位。发布时归档 SourceMap。

## 高频根因模式

| message / 特征 | 根因 | 修复方向 |
|---|---|---|
| `Cannot read property of undefined` | 对象未初始化就访问 / 异步数据未到 | 访问前判空;`?.`/`??`;状态初值给默认 |
| `BusinessError code=xxxxxx` | 调用鸿蒙 API 传参/时序/权限错误 | 拿 code 查官方错误码解释(harmony-docs-retriever) |
| unhandled promise rejection | await 未 try/catch、.then 无 .catch | 异步边界统一 try/catch;全局兜底 |
| `RangeError: Maximum call stack` | 递归无终止 / 状态变更死循环 | 检查 build()/ForEach 内是否原地改状态 |
| JSON.parse 后字段访问崩 | 反序列化结果当成确定结构 | 定义 interface + 逐字段校验(见 ts-to-arkts) |

## ArkTS 专项坑

- **状态变更触发的崩溃**:在 `build()`/`ForEach` 内对状态做原地修改(`this.arr.sort()`)
  会触发重渲染死循环 → 栈溢出。参考 `arkts-syntax` 的 build() 限制。
- **V1 深层观察失效不是崩溃**,但"改了不刷新"后强行手动访问可能引发空值崩溃。
- **跨线程数据**:TaskPool/Worker 回来的数据当成本地强类型对象直接用,可能因 undefined 崩。

## 定位流程

1. 读 Error 类型 + message → 空值 / 越界 / BusinessError / 异步。
2. SourceMap 还原栈 → 定位 `.ets` 源码行。
3. 是 BusinessError → 取 code 查官方错误码;是 TypeError → 回溯哪个值为空。
4. 区分同步 vs Promise rejection,确认 try/catch 边界缺口。
5. 加全局未捕获兜底(`errorManager` 注册回调)收敛偶现,但**兜底不替代修根因**。
