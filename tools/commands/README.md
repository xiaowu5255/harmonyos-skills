# 独立命令脚本

将 6 个 Claude Code 专属 `/harmony-*` 命令的核心逻辑抽象为独立 shell 脚本，可在终端、Codex、OpenCode 等任何环境中直接使用。

## 命令一览

| 脚本 | 对应命令 | 用途 |
|------|---------|------|
| `harmony-doctor.sh` | `/harmony-doctor` | 环境与工程健康一键诊断 |
| `harmony-api-scan.sh` | `/harmony-api-scan` | 超 compatibleSdkVersion 的 API 调用扫描 |
| `harmony-sign-check.sh` | `/harmony-sign-check` | 签名配置全链路排查 |
| `harmony-cloud-deploy.sh` | `/harmony-cloud-deploy` | 端云一体化部署前检查 |
| `harmony-feedback-capture.sh` | `/harmony-feedback` | 捕获踩坑记录（反馈入口） |
| `harmony-test-plan.sh` | `/harmony-test-plan` | 测试计划大纲生成 |

> 注：`/harmony-test-plan` 需要工程结构分析 + 用户交互，独立脚本版本提供检查清单；`feedback-distill.sh`（蒸馏管道）见 `tools/feedback-distill.sh`。

## 使用方式

```bash
# 在终端中直接运行
bash tools/commands/harmony-doctor.sh /path/to/harmony-project

# 或在工程根目录下
cd my-harmony-app
bash ../harmonyos-skills/tools/commands/harmony-sign-check.sh

# 反馈捕获
bash tools/commands/harmony-feedback-capture.sh \
  --skill arkts-syntax \
  --type api-error \
  --detail '编译报错描述'
```

## 跨工具生态

- **Claude Code**: 继续使用 `/harmony-doctor` 等命令（调用对应 skill）
- **Codex / OpenCode**: 安装 harmonyos-skills 后，直接运行 `tools/commands/*.sh`
- **终端 / CI**: 集成到 CI 流水线中做自动化检查
