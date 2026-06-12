---
name: testing-harmony
description: >-
  鸿蒙应用 QA 测试全维度:Hypium 单元测试、UI 自动化(UiTest/Driver)、稳定性
  测试、兼容性与云测(DevEco Testing/华为云测)、性能与功耗专项、内测分发、
  测试计划制定。凡是涉及写测试用例、搭测试工程、CI 跑测试、制定测试计划/
  QA 方案、上架前测试验证、组织内测时,务必使用本技能。
license: MIT
requires: 0-release-index
metadata:
  target-platform: "HarmonyOS 6.x / API 20-24"
---

# 鸿蒙 QA 测试全维度

## QA 全景图(制定测试方案先看这张表)

| 维度 | 验证什么 | 工具/手段 | 详见 |
|---|---|---|---|
| 功能-单元 | 函数/类逻辑 | Hypium(@ohos/hypium) | 本文 §单元测试 |
| 功能-UI | 界面与交互 | UiTest Driver | 本文 §UI 自动化 |
| 功能-集成 | 模块协同 | Hypium 设备测试 + 桩 | 本文 §单元测试 |
| 性能 | 启动/帧率/内存/CPU | DevEco Profiler、SmartPerf | performance-tuning 技能 |
| 稳定性 | 长时间/随机操作不崩 | 压力遍历、长稳挂测 | 本文 §稳定性 |
| 兼容性 | 多设备/多系统版本 | 真机矩阵 + 云测 | 本文 §兼容性与云测 |
| 功耗 | 前后台耗电 | 系统功耗分析/云测专项 | 本文 §专项 |
| 安全合规 | 权限最小化/数据加密 | 人工核查 + 工具扫描 | security-and-permissions、release-and-compliance |
| 真实用户 | Beta 反馈 | AGC 邀请测试/内测分发 | 本文 §内测 |

注意框架澄清:ArkTS/Stage 模型下单元测试框架是 **Hypium**;网上资料提到的
JUnit/@ohos.unittest 属旧 Java 时代鸿蒙,**不适用于当前工程**,看到此类
资料直接忽略。

## 测试工程结构

```
entry/src/
├── test/        # 本地测试(纯逻辑,宿主机跑,快)
└── ohosTest/    # 设备测试(真机/模拟器,可用系统 API、UI 测试)
```
两目录并列,不是嵌套。选型:不依赖系统 API 的纯函数 → test/;涉及系统
能力、组件、页面 → ohosTest/。逻辑与 UI 剥离越干净,快测试占比越高。

## 单元测试(Hypium)

```typescript
import { describe, it, expect, beforeAll, afterEach } from '@ohos/hypium';

export default function calcTest() {
  describe('CalcTest', () => {
    beforeAll(() => { /* 初始化 */ });
    it('add_returns_sum', 0, () => {
      expect(add(1, 2)).assertEqual(3);
    });
  });
}
```
- 用例须在测试入口(List.test.ets / TestRunner 体系)注册才会执行
  ——"用例写了不跑"先查注册。
- 断言用 expect 族(assertEqual/assertTrue/assertContain 等);异步用例
  返回 Promise,避免假绿(没等结果就通过)。
- 集成测试 = 设备测试 + 对外部依赖打桩(网络层注入 mock 实现),验证
  模块间数据传递,不连真实后端。

## UI 自动化(UiTest)

- Driver/On:`Driver.create()` → `findComponent(ON.text('登录'))` →
  click/inputText → 断言目标元素出现。
- 控件定位优先稳定属性(id/text),少用坐标;给关键控件设 id 是为测试
  服务,评审时提醒补。
- 等待用 Driver 显式等待接口,不要 sleep 固定时长(慢且 flaky)。

## 稳定性测试

- **随机压力遍历**(Monkey 类):对应用注入随机点击/滑动/按键序列,跑数
  小时验证不崩溃、不 ANR、内存不持续上涨。可用 DevEco Testing 的稳定性
  测试能力或云测稳定性专项;自动遍历也可用 UiTest 写加权随机脚本兜底。
- **长稳挂测**:核心场景(如播放/导航)持续运行数小时,配合 hilog 与
  内存快照监控(转 performance-tuning 的泄漏排查)。
- 稳定性问题的产出是 crash/ANR 日志,按 harmony-debugging 的运行层
  方法归因;修复后该场景进回归集。

## 兼容性与云测

- **本地矩阵**:按"窗口断点 × 系统 API 版本"组真机矩阵(直板/折叠/平板,
  compatibleSdkVersion 下限设备必须有一台),过 multi-device-adaptation
  的验收清单。
- **云测平台**:华为提供云端真机测试服务(DevEco Testing / AGC 侧云测试,
  以当期控制台实际入口为准),可并行在大量真实设备上跑兼容性/稳定性/
  性能专项,适合发布前大规模验证——本地矩阵保日常,云测保发布。
- 兼容性问题高发点:布局写死尺寸(转一多技能)、高版本 API 裸调用
  (跑 /harmony-api-scan)、字体缩放与深色模式未适配。

## 性能与功耗专项

- 性能测试的方法论与工具(Profiler 工作流、启动/帧率/内存指标)统一在
  performance-tuning 技能,测试计划中引用其指标作为通过标准(如冷启动
  时长阈值),不要拍脑袋定数。
- 功耗:验证后台任务类型合规(转 background-tasks——类型不符 = 异常
  耗电主因)、定位/传感器及时释放;整机功耗对比用云测功耗专项或设备
  电池统计,先记基线再对比版本差。

## 内测分发

发布前通过 AGC 的测试分发能力(邀请测试/开放式测试,入口以当期 AGC
控制台为准)发 Beta 给真实用户:配置测试群组 → 上传测试版本 → 链接/
邀请安装 → 收集反馈与崩溃。注意 Beta 包同样走签名与版本号递增规则
(versionCode 不回退,见 release-and-compliance)。

## QA 流程方法论(帮用户制定测试计划时用)

1. **早期介入**:单测与开发同步写,不等提测。
2. **自动化优先**:回归、遍历类重复测试上 Hypium/UiTest 脚本进 CI。
3. **金字塔配比**:大量单测 > 关键路径 UI 冒烟(登录/支付/主流程,
   少而精)> 全量 UI 回归(按发布节奏跑)。
4. **专项与探索结合**:计划内测试完成后做探索性测试(非常规操作序列)。
5. **发布前**:云测大规模兼容验证 → 内测收集真实反馈 → 全量缺陷闭环。
6. **报告与追踪**:缺陷记录必含复现步骤 + hilog 片段 + 设备/版本信息;
   解决的典型问题用 /harmony-feedback 回流错误对照表。

制定具体测试计划用 /harmony-test-plan 命令;逐维度检查清单见
references/qa-checklist.md(发布前过一遍)。

## CI 集成

命令行经 hvigor 测试任务跑测试(设备测试需可连真机/模拟器的 runner);
签名用调试证书(见 signing-and-certificates CI 节);flaky 用例单独标记
隔离,不许长期混在主流水线。
