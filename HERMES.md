# Hermes 消费指南

本指南面向 [Hermes Agent](https://github.com/NousResearch/hermes-agent) 用户，说明如何安装、消费并自动改造本仓库的 HarmonyOS 技能集。

## 1. 兼容性结论

- **可直接加载**：Hermes 已声明兼容 [agentskills.io](https://agentskills.io) 开放标准，且原生解析 `SKILL.md` + YAML frontmatter。
- **存在语义差异**：Hermes 不认识本仓库的 `requires: <skill>` 与 `metadata.target-platform` 字段；它会忽略这些字段，但技能正文 Markdown 指令可被正常消费。
- **最小改造后即可完美适配**：只需在 `SKILL.md` frontmatter 中追加 Hermes 可识别的字段（见第 3 节），即可让 Hermes 自动处理平台 gate、配置注入和 slash 命令发现。

## 2. 安装方式

### 方式 A：一次性 clone 到 Hermes skills 目录

```bash
git clone https://github.com/xiaowu5255/harmonyos-skills.git /tmp/harmonyos-skills
mkdir -p ~/.hermes/skills/harmonyos-skills
cp -R /tmp/harmonyos-skills/plugins/*/skills/* ~/.hermes/skills/harmonyos-skills/
```

启动 Hermes 后执行：

```bash
/skills
```

或显式调用：

```bash
/harmony-index
```

### 方式 B：Hermes 会话内直接指定外部目录

在 `~/.hermes/config.yaml` 中：

```yaml
skills:
  external_dirs:
    - /path/to/harmonyos-skills/plugins/harmony-platform/skills
    - /path/to/harmonyos-skills/plugins/harmony-core/skills
    - /path/to/harmonyos-skills/plugins/harmony-system/skills
    # ... 按需继续添加
```

Hermes 启动时会扫描这些目录下的 `SKILL.md`。

### 方式 C：通过 OpenClaw 迁移桥

如果你同时有 OpenClaw 环境，可先用 Hermes 内置迁移命令导入：

```bash
hermes claw migrate --preset skills-only
```

该命令会把 OpenClaw skills 复制到 `~/.hermes/skills/openclaw-imports/`。

## 3. 让 Hermes 自动改造 skill 的完整提示词

将以下提示词原样发送给 Hermes，它会自动扫描本仓库并生成 Hermes 兼容版 frontmatter。

```text
请把当前工作目录下 harmonyos-skills 仓库里的所有 SKILL.md 改造为 Hermes Agent 可完美消费的格式。

改造规则：
1. 保留原有 name、description、license、requires、metadata.target-platform、kits 等所有字段，不得删除。
2. 在顶层 frontmatter 追加 platforms: [linux, macos, windows]。
3. 在 metadata 下追加 hermes 块，包含：
   - tags: 与本 skill 主题相关的英文标签数组，至少 3 个。
   - related_skills: 将原 requires 字段的值加入此数组；若原 requires 不存在则留空数组。
   - install_notes: 固定字符串 "Clone or symlink this skill into ~/.hermes/skills/ and ensure its related_skills are also present."
4. 如果 skill 需要用户配置 SDK 路径等可配项，额外声明 metadata.hermes.config：
   - key: 配置键名（如 harmonyos.sdk.home）
   - description: 配置用途
   - default: 默认值或空字符串
   - prompt: 向用户提问时的提示文字
5. 在每个 skill 正文最开头（# 标题之后的第一段），追加一段「前置依赖」：
   "本技能依赖以下前置技能，请在遵循本技能指令前先加载它们：" + 列出 related_skills 中的所有 skill 名称，每个前面加 / 以便 Hermes 作为 slash 命令调用。
6. 确保 YAML frontmatter 语法合法，metadata 块保持缩进一致。
7. 改造完成后，输出每个被修改 skill 的 name 以及新增的 hermes 字段摘要；不要输出完整文件内容。

示例转换：

原 frontmatter：
---
name: security-permissions
description: 鸿蒙权限与安全体系...
license: MIT
requires: 0-system-index
metadata:
  target-platform: "HarmonyOS 6.x / API 20-24"
---

改造后：
---
name: security-permissions
description: 鸿蒙权限与安全体系...
license: MIT
requires: 0-system-index
platforms: [linux, macos, windows]
metadata:
  target-platform: "HarmonyOS 6.x / API 20-24"
  hermes:
    tags: [harmonyos, permissions, security, acl, picker]
    related_skills: [0-system-index]
    install_notes: "Clone or symlink this skill into ~/.hermes/skills/ and ensure its related_skills are also present."
---

# 权限与安全

## 前置依赖

本技能依赖以下前置技能，请在遵循本技能指令前先加载它们：
- /0-system-index
```

## 4. 手动最小适配（单个 skill）

如果你不想跑自动改造，手动改一个 skill 只需 30 秒：

1. 打开 `plugins/<plugin>/skills/<skill>/SKILL.md`
2. 在 frontmatter 中插入 `platforms: [linux, macos, windows]`
3. 在 `metadata:` 下追加：

```yaml
  hermes:
    tags: [harmonyos, <domain>, <topic>]
    related_skills: [<requires-value>]
    install_notes: "Clone or symlink this skill into ~/.hermes/skills/ and ensure its related_skills are also present."
```

4. 保存后重启 Hermes 或执行 `/reload-skills`

## 5. 已知限制

| 本仓库特性 | Hermes 行为 | 建议 |
|---|---|---|
| `requires: 0-system-index` | 不自动加载前置 skill | 通过 `related_skills` + 正文「前置依赖」段落提示 Hermes |
| `metadata.target-platform` | 忽略 | 保留给 Claude Code / Codex 使用，不影响 Hermes |
| `kits: [...]` | 忽略 | 保留，不影响 Hermes |
| `license: MIT` | 忽略 | 保留 |
| `commands/` 脚本 | Hermes 不会自动注册为 slash 命令 | 如需使用，手动在 Hermes 中通过 `exec` 调用 `tools/commands/harmony-*.sh` |

## 6. 验证是否成功

在 Hermes 中执行：

```bash
/skills
```

若能看到 `/harmony-index`、`/security-permissions` 等命令，说明加载成功。

尝试调用：

```bash
/harmony-index 我想做一个鸿蒙 Navigation 多页应用
```

## 7. 推荐加载顺序

首次使用建议按以下顺序加载，以复现 Claude Code 下的渐进式体验：

```bash
/harmony-index
/0-core-index
/arkui-patterns
/stage-model
```

后续根据具体任务加载对应深度 skill，例如：

```bash
/security-permissions
/network-requests
/audio-playback
```

## License

MIT
