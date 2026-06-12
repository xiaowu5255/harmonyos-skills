---
name: harmony-debugging
description: >-
  HarmonyOS 6 (API 20-24) 构建与运行时问题诊断方法论。凡是遇到 hvigor 构建失败、
  HAP 安装失败、应用闪退/白屏、hilog 日志分析、hdc 连接真机或模拟器问题、
  ohpm 依赖报错、模拟器与真机行为不一致等情况,务必先使用本技能——即使报错信息
  看起来是普通的 JS/TS 错误,鸿蒙工程的根因往往在配置文件和签名链路而非代码本身。
license: MIT
requires: 0-core-index
metadata:
  target-platform: "HarmonyOS 6.x / API 20-24"
---

# 鸿蒙构建与运行时调试方法论

## 诊断总纲:先定位层,再看码

鸿蒙报错的第一步永远是判断问题处于哪一层,因为不同层的排查路径完全不同:

```
① 依赖层(ohpm)→ ② 编译层(ArkTS 编译器)→ ③ 打包层(hvigor)
→ ④ 签名层 → ⑤ 安装层(设备端 bm)→ ⑥ 运行层(crash/hilog)
```

判断依据:报错出现在哪个命令/阶段。`ohpm install` 失败是①;编译输出含 `arkts-`
规则名是②;`hvigor` 任务名(如 assembleHap)失败是③;提示 signature/profile
相关是④;`install failed` 是⑤;应用启动后才出问题是⑥。

**强制动作**:开始任何诊断前,先运行 `scripts/check_project_config.sh <工程根目录>`,
它会输出 SDK 版本、签名配置状态、关键配置文件一致性检查结果。很多"代码问题"
会在这一步直接现形。

## 各层排查路径

### ① 依赖层
- `oh-package.json5` 中依赖版本是否与 compatibleSdkVersion 匹配。
- 删除 `oh_modules/` 与锁文件后重新 `ohpm install` 是合法的第一招。
- 公司内网注册表问题:检查 `.ohpmrc` 的 registry 配置。

### ② 编译层(ArkTS)
- 报错含 `arkts-` 规则名 → 转 arkts-syntax 技能的迁移参考逐条改写。
- 报错指向类型不匹配 → 先确认是否在用本地 SDK 之外的 API:
  对报错 API 名在 SDK 的 `ets/api/` 目录 grep,确认它在当前 API 版本是否存在、签名是否一致。

### ③ 打包层(hvigor)
- hvigor 版本与 DevEco/SDK 版本强耦合。检查 `hvigor/hvigor-config.json5` 中的版本
  与工程模板生成时的版本是否被手动改过。
- 清缓存重建:删除工程下 `build/`、`.hvigor/` 后重新构建,排除增量构建脏状态。
- 多模块工程:检查 `build-profile.json5` 的 modules 列表与实际目录是否一致。

### ④ 签名层
- 任何包含 signature / profile / certificate 字样的错误 → 直接转
  signing-and-certificates 技能(harmony-release 插件),那里有全链路排查清单。
- 快速自检:debug 构建优先用 DevEco 的自动签名(登录华为账号),排除手工配置错误。

### ⑤ 安装层
常用命令(在用户机器上执行或指导用户执行):
```bash
hdc list targets                 # 确认设备已连接
hdc shell bm get --udid          # 获取设备 UDID(旧写法 -udid 已失效,用 --udid 或 -u)
hdc install <path/to/hap>        # 命令行安装,错误信息比 IDE 更直接
hdc shell bm dump -n <bundleName>  # 查看已安装包信息
```
安装失败三大根因,按概率排查:签名 Profile 未包含该设备 UDID >
compatibleSdkVersion 高于设备系统版本 > bundleName 冲突/已存在不兼容版本(先卸载再装)。

### ⑥ 运行层
```bash
hdc shell hilog | grep <bundleName 或自定义 TAG>   # 实时日志
hdc shell hilog -r                                  # 清空后复现,降噪
```
- 代码中用 `hilog` 模块打日志时,domain 和 tag 要固定,方便过滤。
- 闪退先抓 crash 日志:hilog 中搜 `cppcrash` / `jscrash` / 应用进程名。
  faultlog 也可通过 DevEco 的 FaultLog 面板获取。
- **白屏不报错**:大概率是 build() 中数据未就绪或状态装饰器未触发刷新,
  转 arkts-syntax 技能的状态管理章节。
- **模拟器正常、真机异常**:优先怀疑权限(module.json5 是否声明 + 是否需要动态申请)
  和签名 Profile 的受限开放权限。

## 错误对照表

`references/common-errors.md` 维护"错误特征 → 根因 → 修复步骤"对照表。
**遇到具体报错文本时先去查表**;查不到的,按上面分层方法论排查,并提示用户
解决后可用 `/harmony-feedback` 把案例回流进对照表。

## 输出纪律

- 诊断结论必须给出依据(哪条日志、哪个配置字段),不允许"可能是环境问题"这类空话。
- 一次只改一个变量:每个修复步骤后让用户重新构建验证,不要一次性给五个改动。
- 修复后,主动总结根因链条(表象 → 直接原因 → 根本原因),便于用户沉淀。
