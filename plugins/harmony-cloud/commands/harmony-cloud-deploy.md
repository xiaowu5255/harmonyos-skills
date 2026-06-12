---
description: 端云一体化工程部署前检查与部署引导
---

对当前端云一体化工程执行部署前检查并引导部署:

1. 按 cloud-foundation 技能的"工程绑定自检清单"逐项检查:
   agconnect-services.json 存在性与内容、bundleName 与 AGC 应用一致性、
   oh-package.json5 中云服务 SDK 依赖。
2. 检查云侧工程(CloudProgram/)结构:云函数目录与 function-config.json、
   clouddb 对象类型定义是否完整;指出空目录或缺配置的函数。
3. 输出部署顺序建议(先云数据库对象类型 → 云函数/云对象 → 端侧联调),
   并提醒部署后在 AGC 控制台对应服务页验证资源生效、用控制台直测云函数
   做二分定位。
4. 汇总为检查报告,异常项给出修复步骤。只读检查,不执行部署操作本身
   (部署在 DevEco 内右键执行)。
