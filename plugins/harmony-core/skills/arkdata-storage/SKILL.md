---
name: arkdata-storage
description: >-
  鸿蒙数据持久化与管理(ArkData):Preferences 轻量存储、RelationalStore
  关系型数据库、统一数据通路 UDMF、分布式数据同步、加密与数据分级。凡是涉及
  存配置/存结构化数据/数据库设计与迁移/跨应用数据传递/数据同步,或读写数据
  类 bug 时使用本技能。
license: MIT
metadata:
  target-platform: "HarmonyOS 6.x / API 20-24"
---

# 数据持久化与管理

## 存储选型

| 数据形态 | 方案 | 不要用它做的事 |
|---|---|---|
| KV 配置、开关、小状态 | Preferences | 存大对象/列表(全量加载,会拖慢) |
| 结构化、可查询、量大 | RelationalStore(SQLite) | 当 KV 用(杀鸡用牛刀) |
| 文件/媒体 | 沙箱文件 + 媒体库接口 | 自造路径访问公共目录 |
| 跨应用拖拽/分享/剪贴板 | UDMF 统一数据 | 自定义私有格式硬传 |
| 多端同步 | 分布式 KV / RDB 同步 / 分布式数据对象 | 见 distributed-collaboration 前置清单 |
| 云端 | CloudDB(见 cloud-foundation) | |

## Preferences 要点

- 实例按 name 获取,进程内单例化封装,避免到处 getPreferences。
- 写后 flush 才落盘;批量写合并后一次 flush。
- 不要存敏感明文,加密需求走带加密选项的存储或密钥库。

## RelationalStore 要点

- 建库时显式指定 securityLevel(数据分级,S1-S4)与是否 encrypt;
  **分级一旦定了升级要做数据迁移,建库前想清楚**。
- 查询用谓词(RdbPredicates)而非手拼 SQL 字符串(注入与转义问题);
  确需原生 SQL 用参数化接口。
- 所有读写是异步的,串行依赖用 await 链;事务接口包裹多写操作。
- **版本迁移**:自己维护 schema version 表 + 升级脚本;鸿蒙不会替你做
  自动迁移,无脑改表结构会让老用户升级后崩溃。

## 数据类 bug 排查

- "存了但读出来是旧值":Preferences 忘 flush / 多实例不同 name / 异步时序。
- "数据库报错打不开":加密参数与建库时不一致 / securityLevel 与设备锁屏
  状态约束冲突 / 沙箱路径误用。
- "跨端不同步":先过 distributed-collaboration 的五条前置清单。
- 调试时可 `hdc file recv` 拉沙箱内 db 文件本地用 SQLite 工具查看
  (debug 包,且注意加密库拉下来也看不了——这反而可验证加密生效)。

## 设计纪律

数据访问统一收口到 Repository 层(单独 HAR/目录),UI 不直接碰存储 API
——鸿蒙存储 API 在版本间偶有演进,收口后迁移只改一处。
