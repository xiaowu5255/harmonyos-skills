# harmonyos-skills

HarmonyOS 6（API 20–24）开发专家技能集。让你的 AI 编码 agent 熟练掌握 ArkTS 语法、ArkUI、系统能力、多媒体、AI、端云一体化与签名发布全流程。

技能本体遵循 **Agent Skills 开放标准**（SKILL.md），采用**三层渐进式架构**避免 context 爆炸，可在 Claude Code、Codex、OpenCode 等所有兼容工具中使用。也提供 [Hermes Agent 消费指南](./HERMES.md)。

当前版本：**0.7.3** — 8 plugin / 54 skill / 6 命令 / 2 hook / 全量质量审计 + 自进化工具链 + 信源质量防回潮 + 跨平台结构 + 主动纠错模式泛化 + 性能臆测软化 + Rust 鸿蒙集成。

## 架构

```
harmony-platform (入口层)     → harmony-index 总索引            [必装]
         │
    ┌────┼────┬────┬────┬────┬────┐
    ▼    ▼    ▼    ▼    ▼    ▼    ▼
 harmony-core        harmony-system       harmony-media  harmony-ecosystem  harmony-release    harmony-graphics  harmony-ai
 应用框架(13 skills)  系统能力(12 skills)  多媒体(5)      应用服务(6)       发布运维(6)         图形(3)            AI(5)
```

详见 [ARCHITECTURE.md](./ARCHITECTURE.md)。

## 技能矩阵

### harmony-platform — 平台入口

| Skill | 定位 |
|-------|------|
| **harmony-index** | 总索引：7 领域路由 + AGC/设计/行业实践 |
| version-guide | API 版本迁移（compatibleSdkVersion、canIUse） |
| harmony-docs-retriever ★ | 官方文档检索层：本地锚点表 + site 限定搜索 + web-fetch 取证（不直连搜索接口） |

### harmony-core — 应用框架（13 skills）

| Skill | 核心内容 |
|-------|---------|
| **0-core-index** † | 领域索引 |
| arkts-syntax | ArkTS≠TS 硬约束、状态管理 V1/V2、TS 迁移 |
| arkts-concurrency | TaskPool、Worker、Sendable、并发容器 |
| arkui-patterns | 布局选型、Navigation、列表性能三件套、动画 |
| arkui-window | 窗口创建/管理、悬浮窗、屏幕方向/密度 |
| stage-model | UIAbility 生命周期、Want、module.json5、Context |
| arkweb | Web 容器、JS Bridge、H5 混合开发 |
| hvigor-build | HAP/HAR/HSP 选型、多模块、release 混淆暗坑 |
| harmony-debugging | 六层诊断法、hdc/hilog、错误对照表、自检脚本 |
| atomic-services-and-cards | 元服务约束、卡片生命周期与三条刷新通路 |
| multi-device-adaptation | 断点响应式、折叠屏/PC 形态、一多工程组织 |
| accessibility-i18n ★ | 无障碍属性标注/屏幕朗读、多语言资源/RTL/长辈关怀 |
| ipc-ime ★ | IPC RPC 三步法(Stub/Proxy/远端订阅) + IME Kit 输入法/自绘编辑器集成 |

### harmony-system — 系统能力（12 skills）

| Skill | 核心内容 |
|-------|---------|
| **0-system-index** † | 领域索引 |
| background-tasks | 后台任务类型选型表（"后台默认死"原则） |
| data-storage | 存储选型、RDB 迁移、分布式同步 |
| security-permissions | Picker/安全控件优先决策树、ACL |
| network-requests ★ | HTTP 请求、WebSocket、Socket、弱网优化 |
| crypto-security ★ | 加解密（AES/RSA/SM4）、密钥存储、生物认证 |
| file-system ★ | 沙箱文件读写、URI 转换、文件选择器 |
| connectivity ★ | 蓝牙（BLE）、WiFi、星闪（NearLink）、NFC |
| distributed | 流转/接续、分布式前置五条清单 |
| native-ndk | N-API 线程约束、CMake、C++ 库移植 |
| sensors-input ★ | 加速度/陀螺仪/光线传感器、振动、多模输入(键鼠/手柄)、手写笔 |
| telephony ★ | 拨打电话、短信(验证码自动填充)、SIM管理、网络状态监听 |

### harmony-media — 多媒体（5 skills）

| Skill | 核心内容 |
|-------|---------|
| **0-media-index** † | 领域索引 |
| audio-playback ★ | 音频播放/录制、焦点管理、设备路由、MIDI |
| camera-capture ★ | 相机预览/拍照/录像、CameraPicker vs 会话模型、影随人动追焦 |
| media-processing ★ | 音视频编解码(AVCodec)、图片处理(Image Kit)、封装解封装 |
| media-system ★ | AVSession 播控/投屏、DRM、扫码(Scan Kit) |

### harmony-ecosystem — 应用服务（6 skills）

| Skill | 核心内容 |
|-------|---------|
| **0-ecosystem-index** † | 领域索引 |
| huawei-kits | 账号登录、推送、应用内支付、地图通用接入 |
| cloud-foundation | 端云一体化：云函数/云数据库/云存储/AGC 自检 |
| notification ★ | 通知发布/更新/取消、角标、渠道、跨设备协同 |
| location-map ★ | 高精度定位、地图显示、POI 搜索、路线规划 |
| sharing-social ★ | 系统分享、DeepLink、联系人、日历 |

### harmony-release — 发布运维（6 skills）

| Skill | 核心内容 |
|-------|---------|
| **0-release-index** † | 领域索引 |
| performance-tuning | Profiler 工作流、冷启动/丢帧/内存 |
| testing-harmony | Hypium/UiTest/稳定性/云测兼容性/内测（含 QA 检查清单） |
| signing-and-certificates | 签名四件套心智模型 + 五步排查 |
| release-and-compliance | 上架与隐私合规驳回整改 |
| crash-diagnostics ★ | 故障日志分型：CppCrash/JsCrash/AppFreeze/内存泄漏定位（faultlog/rawheap/heapsnapshot） |

### harmony-graphics — 图形（3 skills）

| Skill | 核心内容 |
|-------|---------|
| **0-graphics-index** † | 领域索引 |
| 2d-graphics ★ | ArkGraphics 2D Canvas/RenderNode/DisplaySync 三层渲染 |
| 3d-ar ★ | 3D 渲染(ArkGraphics 3D)、AR Engine 空间感知与虚实融合 |

### harmony-ai — AI 智能（5 skills）

| Skill | 核心内容 |
|-------|---------|
| **0-ai-index** † | 领域索引 |
| ai-vision ★ | Core Vision Kit 人脸/文字/物体检测 + Vision Kit 文档/超分 |
| ai-speech ★ | Core Speech Kit 语音识别/合成 + Speech Kit 唤醒/声纹 |
| ai-nlp ★ | Natural Language Kit 分词/实体抽取/文本向量化 |
| ai-inference ★ | MindSpore Lite 端侧推理/训练、NPU 加速、模型量化 |

> † = 领域索引（轻量路由，≤300 词，随所属 plugin 自动安装）  
> ★ = 方法论驱动的深度 skill（600–1200 词）；其余为基础深度 skill  
> 每个深度 skill 目录含 `SKILL.md`，多数另带 `references/`（长尾详情）、`scripts/`（可执行检查）、`test-cases/test-prompts.md`（触发样例）

---

## 安装

### 方式一：Claude Code 添加本市场并安装插件（推荐）

#### 1. 添加市场源

在 Claude Code 会话中执行：

```
/marketplace add harmonyos-skills https://github.com/xiaowu5255/harmonyos-skills
```

或手动编辑 `~/.claude/claude.json`，在 `marketplaceSources` 中添加：

```json
{
  "marketplaceSources": [
    {
      "name": "harmonyos-skills",
      "source": "https://github.com/xiaowu5255/harmonyos-skills"
    }
  ]
}
```

#### 2. 安装插件

在 Claude Code 会话中执行 `/plugin` 命令：

```
# 必装：平台入口（含官方文档检索）+ 应用框架
/plugin install harmony-platform@harmonyos-skills
/plugin install harmony-core@harmonyos-skills
```

#### 3. 按需加装

| 你要做的事 | 加装 plugin |
|-----------|------------|
| 写页面/状态管理/布局/动画、改 .ets 报错 | （已含于 harmony-core） |
| 网络请求、权限、加密、文件、存储、蓝牙、传感器、电话短信 | `harmony-system@harmonyos-skills` |
| 音频、相机、音视频编解码、播控投屏、扫码 | `harmony-media@harmonyos-skills` |
| 账号登录、推送、支付、通知、地图定位、分享、端云一体化 | `harmony-ecosystem@harmonyos-skills` |
| 2D 绘制、3D 渲染、AR | `harmony-graphics@harmonyos-skills` |
| 视觉/语音/NLP AI、端侧推理 | `harmony-ai@harmonyos-skills` |
| 性能优化、测试、签名、上架合规、**崩溃/卡死/内存泄漏诊断** | `harmony-release@harmonyos-skills` |

安装完成后,在任意 Claude Code 工程中说"帮我写一个鸿蒙 Navigation 多页应用"或"鸿蒙 HTTP 请求一直超时怎么排查"即可自动触发对应技能。

### 方式二：本地目录安装

适用于本地开发、离线环境或自定义修改：

```bash
git clone https://github.com/xiaowu5255/harmonyos-skills

# 在 Claude Code 中
/plugin install harmony-platform /path/to/harmonyos-skills/plugins/harmony-platform
/plugin install harmony-core /path/to/harmonyos-skills/plugins/harmony-core
# ... 按需安装其余 plugin
```

### 方式三：直接文件夹替换

适合非 Claude Code 工具（Codex / OpenCode 等）：

```bash
git clone https://github.com/xiaowu5255/harmonyos-skills && cd harmonyos-skills
./tools/sync-skills.sh           # 复制全部 53 个 skill 到 ~/.agents/skills
./tools/sync-skills.sh --link    # 或软链接（修改仓库即生效）
```

### 方式四：独立命令脚本

如果只需要环境诊断 / 签名检查等工具，直接用独立脚本，无需安装任何 plugin：

```bash
git clone https://github.com/xiaowu5255/harmonyos-skills && cd harmonyos-skills

# 环境健康诊断
bash tools/commands/harmony-doctor.sh /path/to/harmony-project

# 签名全链路排查
bash tools/commands/harmony-sign-check.sh /path/to/harmony-project

# 端云部署前检查
bash tools/commands/harmony-cloud-deploy.sh /path/to/harmony-project

# API 版本扫描
bash tools/commands/harmony-api-scan.sh /path/to/harmony-project
```

详见 [tools/commands/README.md](./tools/commands/README.md)。

---

## 命令

| 命令 | 位置 | 作用 | 跨工具 |
|------|------|------|:--:|
| `/harmony-doctor` | Claude Code / 独立脚本 | 环境与工程健康一键诊断 | ✅ |
| `/harmony-api-scan` | Claude Code / 独立脚本 | 扫描高于 compatibleSdkVersion 的 API 调用 | ✅ |
| `/harmony-sign-check` | Claude Code / 独立脚本 | 签名全链路一致性排查 | ✅ |
| `/harmony-cloud-deploy` | Claude Code / 独立脚本 | 端云工程部署前检查 | ✅ |
| `/harmony-test-plan` | Claude Code / 独立脚本 | 定制化测试计划生成 | ✅ |
| `/harmony-feedback` | Claude Code / 独立脚本 | 蒸馏回流知识库（错误对照表） | ✅ |

> Claude Code 下使用 `/harmony-*` 命令；Codex / OpenCode / 终端下运行 `tools/commands/harmony-*.sh` 独立脚本。核心逻辑已抽象，一套实现跨工具流转。

---

## 示例项目

`examples/` 目录包含 8 个典型场景的可运行示例：

| 示例 | 对应 Skill | 场景 |
|------|-----------|------|
| [navigation-app](./examples/navigation-app/) | arkui-patterns / stage-model | Navigation 多页应用 + UIAbility 生命周期 |
| [media-player](./examples/media-player/) | audio-playback / media-system | 音频播放 + 锁屏播控（AVSession） |
| [background-download](./examples/background-download/) | background-tasks | 后台长时任务下载 |
| [cloud-function](./examples/cloud-function/) | cloud-foundation | 端云一体化：云函数调用 |
| [service-card](./examples/service-card/) | atomic-services-and-cards | 元服务卡片：FormExtensionAbility |
| [ble-scanner](./examples/ble-scanner/) | connectivity | BLE 蓝牙设备扫描 |
| [multi-device-layout](./examples/multi-device-layout/) | multi-device-adaptation | 折叠屏/平板响应式布局 |
| [photo-picker](./examples/photo-picker/) | security-permissions / file-system | PhotoViewPicker 免权限选图 |

详见 [examples/README.md](./examples/README.md)。

---

## 设计原则

技能教**方法与不变量**（先读 build-profile.json5 定版本、先查本地 SDK 声明、先验前置清单、分层定位），不堆易过期的 API 事实——对抗鸿蒙季度级迭代的核心手段。

渐进式加载：索引层（≤300 词轻量路由）→ 领域层（1KB 速查）→ 深度层（方法论 + 排查清单）。平均每次请求加载 ≤5 个 skill / ≤10KB context。

## 自进化机制

- **知识回流**：`/harmony-feedback` 捕获踩坑 → `tools/feedback-distill.sh` 月度蒸馏到错误对照表
- **SDK diff**：`tools/sdk-diff/diff_api.py` 机器生成 API 变更清单 → 自动标记受影响 skill
- **变更监测**：`.github/workflows/weekly-sdk-watch.yml` 每周检测文档更新
- **防退化**：`tools/evals/evals.json` 114 条回归样本（50 条含质量断言：26 machine + 24 semantic，11 条负样本）；`tools/lint-skills.sh` 14 项一致性 + 内容质量检查（CI 强制）
- **内容审查**：`tools/validate-frontmatter.py` 按 Claude Skills 规范审查 name/description 质量
- **季度审计**：`tools/quarterly-audit-checklist.md` 标准化审计流程 + 判定标准（首次 2026-09）
- **官方文档巡检**：`harmony-docs-retriever/scripts/check-doc-urls.sh` 检查锚点 URL 有效性

## 质量保证

- ✅ **全量审计**：45 个深度 skill 逐条 API 正确性审查（AUDIT_REPORT v3.0，2026-06-13）
- ✅ **14 项一致性检查**：`tools/lint-skills.sh` 覆盖 frontmatter 检查、路由表验证、references 引用完整性、JSON 解析、内容质量审查、9 高优 skill evals 覆盖软提示、9 高优 skill 主动纠错覆盖率软提示
- ✅ **114 条回归样本**：50 条含输出正确性断言（quality_assertion，26 machine 可机检 + 24 semantic 待人工），11 条负样本
- ✅ **CI 强制**：push / PR 自动跑 lint，阻断引用断裂、JSON 非法、frontmatter 不合格

## License

MIT
