#!/usr/bin/env bash
# sync-skills.sh — 把本仓库所有 skill 同步到其他 Agent 工具的标准路径
# 用法:
#   ./tools/sync-skills.sh           # 同步到 ~/.agents/skills (Codex / OpenCode 等均可发现)
#   ./tools/sync-skills.sh --link    # 用软链接代替复制(本仓库 git pull 即全工具生效)
#   ./tools/sync-skills.sh --target <dir>   # 自定义目标目录
#
# 路径说明(Agent Skills 开放标准):
#   - OpenCode 会自动读取 ~/.claude/skills 与 ~/.agents/skills,装了 Claude Code 插件即可复用
#   - Codex 等工具可发现 ~/.agents/skills,或在其配置中按路径登记 SKILL.md
set -euo pipefail
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="$HOME/.agents/skills"
MODE="copy"

while [ $# -gt 0 ]; do
  case "$1" in
    --link) MODE="link"; shift ;;
    --target) TARGET="$2"; shift 2 ;;
    *) echo "未知参数: $1"; exit 1 ;;
  esac
done

mkdir -p "$TARGET"
COUNT=0
for skill_md in "$REPO_DIR"/plugins/*/skills/*/SKILL.md; do
  src_dir="$(dirname "$skill_md")"
  name="$(basename "$src_dir")"
  # 目录名加 harmony- 前缀防止与其他技能集冲突(notification/file-system 等过于通用);
  # skill 实际名称仍以 frontmatter 的 name 字段为准,不受目录名影响
  case "$name" in harmony-*) dst_name="$name";; *) dst_name="harmony-$name";; esac
  dst="$TARGET/$dst_name"
  rm -rf "$dst"
  if [ "$MODE" = "link" ]; then
    ln -s "$src_dir" "$dst"
  else
    cp -r "$src_dir" "$dst"
  fi
  echo "[$MODE] $name -> $dst"
  COUNT=$((COUNT+1))
done
echo "完成:$COUNT 个 skill 已同步到 $TARGET"
echo "提示:Codex 用户修改 ~/.codex/config.toml 后需重启;OpenCode 自动发现无需配置。"
