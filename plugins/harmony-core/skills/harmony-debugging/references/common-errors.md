# 鸿蒙常见错误对照表(种子版 v0.1.0)

> 格式:错误特征(报错文本的可搜索片段)→ 所属层 → 根因 → 修复步骤 → 适用版本。
> 这是整个插件中唯一随时间单调变好的资产。每个通过 `/harmony-feedback` 回流的
> 真实案例都应归并到这里。**条目中的报错文本必须来自真实输出,禁止凭记忆杜撰错误码。**

## 目录
1. 编译层(ArkTS)
2. 打包层(hvigor)
3. 签名/安装层
4. 运行层
5. 端云/AGC 配置层

---

## 1. 编译层

### 报错含 `arkts-no-any-unknown`
- 根因:代码使用了 any/unknown 类型(常见于 JSON.parse、第三方 JS 库迁移)。
- 修复:定义 interface/class 后做显式类型转换。见 arkts-syntax 技能
  references/ts-to-arkts.md 第 1 节。
- 版本:全版本。

### 报错含 `Property '...' does not exist on type`,且该 API 在官方文档中存在
- 根因:文档对应的 API 版本高于工程 compatibleSdkVersion,或本地 SDK 未更新。
- 修复:① 在 SDK `ets/api/` 目录 grep 该 API 确认本地是否存在;② 存在但版本标注
  更高 → 升级 compatibleSdkVersion(评估设备覆盖代价)或改用旧 API;③ 本地不存在
  → DevEco 中更新 SDK。
- 版本:全版本(API 20→24 期间新增 API 较多,此问题高发)。

## 2. 打包层

### hvigor 任务失败,提示版本/插件不兼容(含 `hvigor` 与 `version` 字样)
- 根因:hvigor-config.json5 中版本与当前 DevEco/SDK 不匹配,常见于工程在不同
  DevEco 版本间迁移。
- 修复:用当前 DevEco 新建同 API 版本的空工程,对照其 hvigor-config.json5 校准版本;
  删除 `.hvigor/`、`build/` 后重建。
- 版本:全版本。

### 增量构建产物异常(改了代码但行为没变 / 资源未更新)
- 根因:hvigor 增量缓存脏状态。
- 修复:Clean Project 或手动删 `build/` 重建;确认修改的文件确实在参与构建的模块内。
- 版本:全版本。

## 3. 签名/安装层

### 安装失败,错误信息含 `signature` 或 `verify` 字样
- 根因:签名证书/Profile 与包不匹配,细分场景见 signing-and-certificates 技能。
- 修复:走该技能的五步排查清单。
- 版本:全版本。

### 安装失败,错误信息含设备/版本兼容字样
- 根因:工程 compatibleSdkVersion 高于目标设备系统的 API 版本。
- 修复:`hdc shell param get const.ohos.apiversion` 查设备 API 版本(以实际命令
  输出为准),下调 compatibleSdkVersion 或换设备/升级设备系统。
- 版本:全版本。

### 真机安装失败但模拟器正常
- 根因(按概率):调试 Profile 未注册该真机 UDID > 受限权限未在 Profile 中授权 >
  设备未开启开发者模式/USB 调试。
- 修复:`hdc shell bm get -udid` 取 UDID → AGC 设备管理中注册 → 重新生成调试
  Profile → 重签名安装。
- 版本:全版本。

## 4. 运行层

### 应用启动白屏,hilog 无 crash
- 根因(按概率):build() 依赖的数据异步未就绪且无兜底 UI > 状态装饰器未触发刷新
  (V1 深层嵌套问题)> 路由/Ability 配置指向了错误的入口页面。
- 修复:① 给异步数据加加载态条件渲染;② 见 arkts-syntax 状态管理章节;
  ③ 检查 module.json5 的 mainElement 与页面路由配置。
- 版本:全版本。

### hilog 中出现 `jscrash`
- 根因:ArkTS 运行时未捕获异常,crash 栈中有具体文件与行号。
- 修复:读 crash 栈定位源码行;高发于空值访问(可选链缺失)与 JSON 结构不符预期。
- 版本:全版本。

## 5. 端云/AGC 配置层

### 端侧调用云函数/云数据库报初始化或配置类错误
- 根因(按概率):`agconnect-services.json` 缺失或与 AGC 项目不匹配 >
  AGC 中对应服务未开通 > 端侧 SDK 依赖版本与 API 版本不兼容。
- 修复:走 cloud-foundation 技能的"工程绑定自检清单"。
- 版本:全版本。

---

## 条目贡献规范

1. 错误特征写"可被 grep 命中的报错片段",不写复述。
2. 根因按概率排序,标注判断依据。
3. 必须有"已验证"的修复步骤;未验证的猜测放 issue,不进本表。
4. 标注首次验证时的 API 版本与 DevEco 版本。
