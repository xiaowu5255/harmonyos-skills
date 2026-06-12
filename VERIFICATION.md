# 官方文档核验记录(VERIFICATION)

> 本文件沉淀技能内容对照华为官方文档的核验结论,配合 ROADMAP「贯穿红线 #2」使用:
> **任何具体 API 名 / 文档 URL / 版本数值必须经核实**。每条含:结论 → 信源 → 核验日期 → 落地状态。
>
> 信源级别约定:
> - **A 级**:developer.huawei.com 官方页(SPA,正文常抓取失败,多用于证实页面存在/标题)
> - **B 级**:gitee.com/openharmony/docs(master 分支 markdown,与华为商用文档同源)
> - **C 级**:逐字转载官方文档的第三方页 / 多源交叉佐证
>
> 全量首轮核验日期:**2026-06-12**。覆盖全部 19 个深度 skill 的事实性声明。

## 一、平台版本基线(全仓库共用)

| 项 | 结论 | 信源 | 日期 |
|---|---|---|---|
| HarmonyOS 6.0.0 = API 20 | ✅ 属实 | C(发布说明转载) | 2026-06-12 |
| 6.0.1=21 / 6.0.2=22 / 6.1.0=23 / **6.1.1=24** | ✅ 属实,API 24 于 2026-05-26 转正 | C(IT之家转引官方设备占比 2026-06-02) | 2026-06-12 |
| 截至 2026-06,API 24 为最新主线;6.1.0(23)+6.1.1(24) 覆盖 ~93% 存量设备 | ✅ | C | 2026-06-12 |

> 结论:全仓库 `target-platform: "HarmonyOS 6.x / API 20-24"` 标注**成立**,无需改。下次 6.2/API 25 发布后更新。

## 二、已修正条目(2026-06-12 落地)

| # | Skill | 原内容 | 问题 | 修正 | 信源 |
|---|---|---|---|---|---|
| 1 | harmony-debugging / signing-and-certificates / harmony-sign-check | `hdc shell bm get -udid` | 单横线写法已失效,照抄即失败 | 改为 `--udid`(或 `-u`),共 5 处 | B(bm-tool.md) + A(AGC 注册调试设备) |
| 2 | hvigor-build / release-and-compliance | "release 默认开启代码混淆" | 过时:DevEco 5.0.3.600 起新建工程默认**关闭** | 改为"先确认是否开启;发布包应显式 enable: true",补 nameCache.json 路径 | C(逐字转载 DevEco User Guide) + B(source-obfuscation.md) |
| 3 | arkts-syntax/references/ts-to-arkts.md §3 | 规则名 `arkts-strict-property-initialization` | 编造,官方无此规则名 | 改为"强制 TS 严格检查 strictPropertyInitialization,错误码 10605999" | B(typescript-to-arkts-migration-guide.md) |
| 4 | arkts-syntax + ts-to-arkts.md §5 | 解构"部分受限(视编译器版本)" | 弱化失实:解构为**错误级禁止** | 给出 arkts-no-destruct-assignment/-decls/-params/-spread + 错误码,对象展开禁止 | B(同上) |
| 5 | arkts-syntax 第零条 | SDK 路径 `.../sdk/<版本>/openharmony/ets/api/` | 过时:当前为 `sdk/default/`,且分 openharmony + hms | 改为 `<DevEco>/sdk/default/openharmony|hms/ets/api/`,注 @kit 聚合与 macOS 路径 | C(多源教程 + 腾讯 MSDK 接入文档) |
| 6 | arkts-syntax V2 节 | 缺 @Once/@Monitor/@Computed;"V1/V2 不可混用";@Param 只读表述粗 | 不完整/过时 | 补 @Once/@Monitor/@Computed/!!/makeObserved;注 API 19+ 可部分混用;厘清 @Param 只读=不可整体重新赋值 | B(arkts-new-*.md 系列) |
| 7 | arkts-syntax build() / @Builder | @Builder 按引用传参"用对象字面量保持响应式" | 不完整 | 补:默认按值不刷新;按引用仅**单参数+直接对象字面量**生效;API 20+ UIUtils.makeBinding();禁 switch;build 内 sort 死循环坑 | B(arkts-builder.md) |
| 8 | arkui-patterns | @Styles/@Extend 列为纯样式复用首选 | 过时:官方声明两者**不再演进、不支持 export** | 改为优先 AttributeModifier | A(arkts-user-defined-extension-attributemodifier) |
| 9 | arkui-patterns | "列表性能三件套" | 不完整 | 升级为四件套,补**组件冻结 freezeWhenInactive** + reuseId + 懒加载组件白名单 | B(LazyForEach 文档) |
| 10 | arkui-patterns | "优先 promptAction / @CustomDialog" | 过时:@CustomDialog 退役 | 改为 UIContext.getPromptAction().openCustomDialog + ComponentContent | A(自定义弹窗文档) |
| 11 | arkui-patterns | Flex "频繁换行性能不如";嵌套"约10层";"pop 携带结果" | 阈值无依据/术语不准 | Flex 改"二次布局开销";嵌套改官方"不超过 5 层";回传改 onPop 回调 + 系统路由表 | C(UI 组件性能优化最佳实践) + B(Navigation 文档) |
| 12 | multi-device-adaptation | 断点"以官方为准"回避数值;xs="手表";平行视界"API23+ 可获取状态";折叠屏仅 SideBarContainer | 阈值缺失/xs 失实/术语含糊/漏组件 | 补 xs[0,320)/sm[320,600)/md[600,840)/lg[840,+∞) + xl/xxl;xs 改"超小窗口";平行视界精确化;补 FolderStack/FoldSplitContainer/getCurrentFoldCreaseRegion | B(GridRow 文档) + A(平行视界页) |
| 13 | stage-model | 生命周期漏 onNewWant/onWindowStageWillDestroy;无"拉起其他应用收紧" | 不完整/过时 | 补两回调 + onNewWant 与 launchType 关联;新增"拉起其他应用(API 12+)"节(openLink/App Linking/startAbilityByType) | B(UIAbility 生命周期 + app-startup-overview.md) |
| 14 | background-tasks | "API 21+ 并行多个**同类型**长时任务;低版本一个类型一个" | 措辞失实 | 改为"API 21+ 单 UIAbility 最多 10 个(类型可同可不同);API 20- 仅 1 个";reminderAgent→reminderAgentManager;补 bgMode 枚举 + efficiencyResources | B(continuous-task.md) |
| 15 | distributed | "API 23+ 增强自定义组件跨 Ability 迁移" | **疑似杜撰**,官方迁移文档无此表述且概念不准 | 删除,改为 restoreId+restoreWindowStage 通用表述;补 MISMATCH/wantParam<100KB/碰一碰/服务互通 | B(hop-cross-device-migration.md) |
| 16 | performance-tuning | "taskpool/Worker 两者都不共享内存,序列化传递" | 过时:漏 @Sendable 例外 | 改为默认序列化(16MB 上限)+ @Sendable 可共享引用,交叉引用 arkts-concurrency | B(taskpool-introduction.md) |
| 17 | version-guide | "两个版本号 compatible/target" | 不完整:漏 compileSdkVersion | 扩为三号并厘清各自语义 | A(ide-hvigor-build-profile) + C |
| 18 | data-storage | "自己维护 schema version 表;鸿蒙不自动迁移" | 不精确 | 对齐官方 store.version(=SQLite user_version)机制 | B(js-apis-data-relationalstore) + C |
| 19 | huawei-kits | "证书指纹";Push "token 会变化:监听刷新" | 术语旧/机制错 | 改"公钥指纹"(非 Android SHA256);Push 无 onNewToken,改冷启动 getToken 比对 | C(Account 报错 1001500001 + Push FAQ) |
| 20 | cloud-foundation | 认证服务"需传入 apiKey 与 clientSecret" | 误导/凭据泄露风险 | 改为读 agconnect-services.json 调 initialize();禁端侧手写 clientSecret | C(auth-component 实例) |
| 21 | signing-and-certificates | signingConfigs 字段不全;路径少 Project;证书有效期"以年计" | 不完整 | 补 signAlg(SHA256withECDSA)/type;路径加 Project;补调试1年/发布3年(上限3)/设备100台 | A(ide-signing) + A(AGC 帮助中心) |
| 22 | atomic-services-and-cards | 包体"以官方为准";生命周期仅四个;form_config 无单位;call 权限模糊 | 不完整 | 补单包2MB/总10MB;补 onChangeFormVisibility 等;updateDuration=30min 倍数;call 需 KEEP_BACKGROUND_RUNNING;补实况窗辨析 | B(卡片生命周期/配置/call 事件文档) |
| 23 | 全仓库交叉引用 | huawei-ecosystem-kits / security-and-permissions / distributed-collaboration / arkdata-storage / api-version-migration | 重构后旧 skill 名残留(8 处) | 全部更新为现名 | 内部一致性 |

## 三、核验通过(无需修改)的关键项

- **ArkTS 硬约束**:arkts-no-any-unknown / -no-delete / -no-var / -no-structural-typing / -no-private-identifiers 等规则名真实(B)。
- **状态管理 V1**:@State 一层观察、@Observed+@ObjectLink 嵌套观察描述准确(B)。
- **hvigor**:HAP/HAR/HSP 选型、build-profile 结构、assembleHap/assembleApp 命令、oh-package-lock.json5 锁文件名准确(A)。
- **NDK**:工程结构、libace_napi.z.so、napi_threadsafe_function、napi_ref、abiFilters(arm64-v8a/x86_64)、hilog/log.h 准确(B);建议补链接 libhilog_ndk.z.so。
- **权限**:PhotoViewPicker(photoAccessHelper 版本未被取代)、SaveButton/LocationButton/PasteButton、system_grant/user_grant、ACL allowed-acls、APPROXIMATELY_LOCATION 依赖、INTERNET 必须声明 均准确(B/C)。
- **测试**:Hypium(@ohos/hypium)、test/ vs ohosTest/、UiTest(Driver/ON,@kit.TestKit)、DevEco Testing/云测/邀请测试 均准确(B/A)。
- **发布**:versionCode 递增、App Pack(.app,≤2GB)、隐私合规四要点 均符合现行审核(A)。
- **端云**:Cloud Foundation Kit 名称、[CloudDev]Empty Ability 模板、agconnect-services.json 路径、云数据库四角色权限、CloudProgram 结构 均准确(A/C);AGC Serverless **未发现停服公告**,定位无需改写。
- **分布式**:流转=接续+协同、软总线、前置五条、continuable/onContinue(AGREE/REJECT)/LaunchReason.CONTINUATION、setSessionId、distributedDeviceManager 均准确(B)。
- **数据**:Preferences flush、RelationalStore securityLevel S1-S4/encrypt/RdbPredicates/事务、UDMF 均准确(B)。
- **性能**:Profiler 模板 Time/Frame/Allocation/Snapshot/Launch(另有 CPU)、HiTraceMeter startTrace/finishTrace 均准确(B/C)。

## 四、待后续版本处理的遗漏(非纠错,属覆盖扩展)

详见 ROADMAP「Phase 4 / 后续」。高价值候选:
- **热更新与动态化边界**(并入 release-and-compliance):禁止动态下发可执行代码、HQF 走审核通道、合规出路(ArkWeb/卡片/服务端驱动 UI)。
- **元服务发布独立流程**(并入 release-and-compliance):"我的元服务"入口、免责函、备案差异。
- **商业化 Kit**:Payment / Store / Ads(并入 huawei-kits);与 IAP 的边界。
- **AI 类 Kit**:Intents / Core Speech / Core Vision(harmony-ai 已部分覆盖,补 Intents)。

## 五、核验方法学说明

- developer.huawei.com 为 SPA,WebFetch 直取正文常失败;核验以 B 级(OpenHarmony 同源 markdown)为主力,A 级证实页面存在,C 级交叉佐证。
- 如需将任一条提升至 A 级官方原文确认,在能正常渲染官方 SPA 的环境复抓对应页面。
- 复核工具:`tools/sdk-diff/diff_api.py`(SDK 间 API diff)、`tools/sdk-diff/skill_map.json`(Kit→skill 影响面)。
