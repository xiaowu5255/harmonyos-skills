---
name: cloud-foundation
description: >-
  HarmonyOS 端云一体化开发(Cloud Foundation Kit):云函数、云数据库、云存储、
  认证服务、AGC 工程绑定与云侧部署。凡是涉及在 DevEco Studio 中创建云开发工程、
  调用 AGC 云服务、配置 agconnect-services.json、编写云函数/云对象、设计云数据库
  对象类型,或排查"端侧调云侧失败"类问题时,务必使用本技能——端云链路的报错
  绝大多数源于 AGC 配置而非代码,不懂绑定流程会在错误的地方排查。
license: MIT
requires: 0-ecosystem-index
metadata:
  target-platform: "HarmonyOS 6.x / API 20-24 + AGC"
---

# 端云一体化开发(Cloud Foundation Kit)

## 核心模型

端云一体化 = 在 DevEco Studio 中用一套工具、一种语言(端侧 ArkTS、云侧 TS)
同时开发端侧应用与云侧 Serverless 服务,云侧一键部署到 AGC。底座是
Cloud Foundation Kit,常用云服务:认证服务、云函数、云数据库、云存储、云缓存。

## 不可跳过的前置链路(顺序错误 = 后面全错)

1. **先在 AGC 平台创建项目和"端云一体化"应用**(developer.huawei.com 的 AGC 控制台)。
   这一步必须先做——IDE 创建工程时要与 AGC 应用绑定,游离应用无法使用云服务。
2. DevEco 中用云开发模板(如 [CloudDev]Empty Ability)创建工程,登录华为账号,
   关联第 1 步创建的 AGC 应用,选择数据处理位置。
3. 工程创建成功后,DevEco 自动完成:开通认证/云函数/云数据库/云存储等服务、
   端侧集成 AGC SDK(`entry/src/main/resources/rawfile/agconnect-services.json`
   配置文件 + `oh-package.json5` 中的云服务 SDK 依赖)。

**工程绑定自检清单**(端云类报错先过一遍):
- [ ] agconnect-services.json 存在且来自当前 AGC 应用(换过 AGC 项目要重新下载)
- [ ] AGC 控制台中目标服务已开通(免费额度内也需显式开通)
- [ ] 端侧 SDK 依赖版本与工程 API 版本兼容
- [ ] bundleName 与 AGC 应用包名完全一致

## 云侧工程结构与开发

```
CloudProgram/
├── cloudfunctions/        # 云函数,每个函数一个目录(含 function-config.json)
└── clouddb/               # 云数据库:对象类型定义 + 数据条目 + 导出的配置
```

- **云函数 vs 云对象**:云函数是单一入口的 handler;云对象是把一组方法封装为类,
  端侧像调本地对象一样调用。多方法的业务优先用云对象,减少样板代码。
- **云数据库**:先在 DevEco 中定义对象类型(ObjectType,含字段、主键、索引、
  **角色权限**),添加数据条目,然后部署到 AGC。权限模型按角色
  (Everyone/已认证用户/数据创建者/管理员)配置增删改查,**忘配权限是端侧
  查询返回空或被拒的头号根因**。
- **部署**:云侧代码在 IDE 内对目录右键 Deploy,或整体一键部署。部署后到 AGC
  控制台对应服务页验证资源已生效。

## 端侧调用模式

- 调用前确保已初始化 AGC 上下文(模板工程已处理;手工集成的工程检查初始化时机
  是否早于首次调用)。
- 云函数调用是异步的,所有调用包 try-catch 并打印错误码 + message,
  AGC 的错误信息里通常带可定位的原因。
- 认证服务:初始化只需读取 rawfile 中的 `agconnect-services.json` 调 initialize()
  (凭据字段已含在该官方下发的 JSON 内,由 SDK 内部使用);登录组件只传认证方式
  (modes)与回调即可。**不要在端侧代码里手写 apiKey/clientSecret**——clientSecret
  属服务端密钥,放端侧是凭据泄露。

## 排错路径(端侧调云侧失败)

按概率顺序:
1. 过一遍上面的"工程绑定自检清单"(harmony-debugging 的
   check_project_config.sh 脚本第 6 项会自动检查 agconnect-services.json)。
2. AGC 控制台直接测试云函数(控制台有在线测试入口)——**云侧直测成功而端侧失败,
   问题必在端侧配置或网络;云侧直测也失败,问题在云函数代码或部署**。
   这一刀能把排查范围砍掉一半,永远先做。
3. 检查设备网络与 AGC 数据处理位置(出海应用注意站点选择)。
4. 看端侧抓到的错误码,对照 AGC 文档错误码表;解决后用 /harmony-feedback 回流。

## 成本与额度提醒

云函数/云数据库/云存储均有免费额度,超出计费。给用户写定时触发器、高频轮询
之类的代码时,主动提醒额度影响。

## 版本与查证纪律

AGC 服务与 SDK 的演进独立于 HarmonyOS API 版本,变化更频繁。涉及具体 SDK 接口
签名时,以工程 oh_modules 中实际安装的 SDK 声明文件为准;控制台操作路径若与
本技能描述不符,以 AGC 当前界面为准并提示用户反馈差异。
