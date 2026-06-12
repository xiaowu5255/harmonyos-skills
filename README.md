# harmonyos-skills

HarmonyOS 6（API 20–24）开发专家技能集。让你的 AI 编码 agent 熟练掌握 ArkTS 语法、ArkUI、系统能力、多媒体、AI、端云一体化与签名发布全流程。

技能本体遵循 **Agent Skills 开放标准**（SKILL.md），采用**三层渐进式架构**避免 context 爆炸，可在 Claude Code、Codex、OpenCode 等所有兼容工具中使用。

当前版本：**0.2.2** — 8 plugin / 47 skill / 6 命令 / 2 hook / 自进化工具链。

## 架构

```
harmony-platform (入口层)     → harmony-index 总索引            [必装]
         │
    ┌────┼────┬────┬────┬────┬────┐
    ▼    ▼    ▼    ▼    ▼    ▼    ▼
 harmony-core        harmony-system       harmony-media  harmony-ecosystem  harmony-release    harmony-graphics  harmony-ai
 应用框架(11 skills)  系统能力(10 skills)  多媒体(5)      应用服务(6)       发布运维(5)         图形(3)            AI(5)
```

详见 [ARCHITECTURE.md](./ARCHITECTURE.md)。

## 技能矩阵

### harmony-platform — 平台入口

| Skill | 定位 |
|-------|------|
| **harmony-index** | 总索引：7 领域路由 + AGC/设计/行业实践 |
| version-guide | API 版本迁移（compatibleSdkVersion、canIUse） |

### harmony-core — 应用框架（11 skills）

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

### harmony-system — 系统能力（10 skills）

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

### harmony-media — 多媒体（5 skills）

| Skill | 核心内容 |
|-------|---------|
| **0-media-index** † | 领域索引 |
| audio-playback ★ | 音频播放/录制、焦点管理、设备路由、MIDI |
| camera-capture ○ | 相机预览/拍照/录像、影随人动追焦 |
| media-processing ○ | 音视频编解码、图片处理、媒体播放 |
| media-system ○ | AVSession 播控/投屏、DRM、扫码 |

### harmony-ecosystem — 应用服务（6 skills）

| Skill | 核心内容 |
|-------|---------|
| **0-ecosystem-index** † | 领域索引 |
| huawei-kits | 账号登录、推送、应用内支付、地图通用接入 |
| cloud-foundation | 端云一体化：云函数/云数据库/云存储/AGC 自检 |
| notification ★ | 通知发布/更新/取消、角标、渠道、跨设备协同 |
| location-map ★ | 高精度定位、地图显示、POI 搜索、路线规划 |
| sharing-social ★ | 系统分享、DeepLink、联系人、日历 |

### harmony-release — 发布运维（5 skills）

| Skill | 核心内容 |
|-------|---------|
| **0-release-index** † | 领域索引 |
| performance-tuning | Profiler 工作流、冷启动/丢帧/内存 |
| testing-harmony | Hypium/UiTest/稳定性/云测兼容性/内测（含 QA 检查清单） |
| signing-and-certificates | 签名四件套心智模型 + 五步排查 |
| release-and-compliance | 上架与隐私合规驳回整改 |

### harmony-graphics — 图形（3 skills）

| Skill | 核心内容 |
|-------|---------|
| **0-graphics-index** † | 领域索引 |
| 2d-graphics ○ | ArkGraphics 2D 绘制/显示 |
| 3d-ar ○ | 3D 渲染、AR Engine、空间感知 |

### harmony-ai — AI 智能（5 skills）

| Skill | 核心内容 |
|-------|---------|
| **0-ai-index** † | 领域索引 |
| ai-vision ○ | 视觉 AI（OCR、图像检测） |
| ai-speech ○ | 语音 AI（识别、合成、字幕） |
| ai-nlp ○ | NLP 自然语言处理 |
| ai-inference ○ | 端侧推理（MindSpore Lite/CANN/NNRt） |

> † = 领域索引（轻量路由，≤300 词）  
> ★ = v0.2.0 新增（P0/P1 深度）  
> ○ = v0.2.0 新增（P2 占位，待补充完整内容）

## 安装

### Claude Code（完整体验）

```bash
# 必装：平台入口 + 应用框架
/plugin install harmony-platform@harmonyos-skills
/plugin install harmony-core@harmonyos-skills

# 按需（取决于你的业务场景）
/plugin install harmony-system@harmonyos-skills        # 网络/安全/存储
/plugin install harmony-media@harmonyos-skills         # 音视频/相机
/plugin install harmony-ecosystem@harmonyos-skills     # 通知/云开发/支付
/plugin install harmony-release@harmonyos-skills       # 测试/性能/上架
/plugin install harmony-graphics@harmonyos-skills      # 2D/3D/AR
/plugin install harmony-ai@harmonyos-skills            # 视觉/语音/NLP
```

### Codex / OpenCode / 其他兼容工具

```bash
git clone https://github.com/<你的用户名>/harmonyos-skills && cd harmonyos-skills
./tools/sync-skills.sh           # 复制全部 47 个 skill 到 ~/.agents/skills
```

## 命令（Claude Code）

| 命令 | 作用 |
|------|------|
| `/harmony-doctor` | 环境与工程健康一键诊断 |
| `/harmony-api-scan` | 扫描高于 compatibleSdkVersion 的 API 调用 |
| `/harmony-sign-check` | 签名全链路一致性排查 |
| `/harmony-cloud-deploy` | 端云工程部署前检查 |
| `/harmony-test-plan` | 定制化测试计划生成 |
| `/harmony-feedback` | 蒸馏回流知识库（错误对照表） |

## 设计原则

技能教**方法与不变量**（先读 build-profile.json5 定版本、先查本地 SDK 声明、先验前置清单、分层定位），不堆易过期的 API 事实——对抗鸿蒙季度级迭代的核心手段。

渐进式加载：索引层（≤300 词轻量路由）→ 领域层（1KB 速查）→ 深度层（方法论 + 排查清单）。平均每次请求加载 ≤5 个 skill / ≤10KB context。

## 自进化机制

- **知识回流**：`/harmony-feedback` 蒸馏真实踩坑到错误对照表
- **SDK diff**：`tools/sdk-diff/diff_api.py` 机器生成 API 变更清单
- **变更监测**：`.github/workflows/weekly-sdk-watch.yml` 每周检测文档更新
- **防退化**：`tools/evals/evals.json` 16 条回归样本（含负样本）

## License

MIT
