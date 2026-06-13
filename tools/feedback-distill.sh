#!/bin/bash
# ============================================================
# HarmonyOS Skills — 反馈蒸馏管道
# 用途: 每月手动运行, 从 /harmony-feedback 积累的反馈数据
#       交叉比对后更新 affected skills 和 common-errors.md
#
# 用法: bash tools/feedback-distill.sh [--dry-run]
#   --dry-run    仅分析不写文件
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# --- 配置 ---
FEEDBACK_FILE="${ROOT_DIR}/.workbuddy/feedback/feedback-log.jsonl"
COMMON_ERRORS="${ROOT_DIR}/plugins/harmony-core/skills/harmony-debugging/references/common-errors.md"
DRY_RUN=false

for arg in "$@"; do
  case $arg in
    --dry-run) DRY_RUN=true; shift ;;
  esac
done

# --- 检查反馈文件是否存在 ---
if [ ! -f "$FEEDBACK_FILE" ]; then
  echo "[INFO] 无反馈日志文件: $FEEDBACK_FILE"
  echo "[INFO] 跳过蒸馏（无待处理反馈）"
  exit 0
fi

FEED_COUNT=$(wc -l < "$FEEDBACK_FILE")
if [ "$FEED_COUNT" -eq 0 ]; then
  echo "[INFO] 反馈日志为空，跳过蒸馏"
  exit 0
fi

echo "========================================"
echo "  HarmonyOS Skills 反馈蒸馏"
echo "  待处理反馈: $FEED_COUNT 条"
echo "  $(date '+%Y-%m-%d %H:%M')"
echo "========================================"

# --- 分析反馈 ---
# 提取每条反馈的 skill 名称和问题类型
echo ""
echo "[1/3] 分析反馈规律..."

# 简单的反馈分类逻辑 (feedbacks JSONL 的预期格式: {skill, type, detail, date})
if command -v python3 &> /dev/null; then
  SUMMARY=$(python3 - "$FEEDBACK_FILE" << 'PYEOF'
import json, sys, os
from collections import Counter

fb_file = sys.argv[1]
skills = Counter()
types = Counter()
entries = []

with open(fb_file, 'r', encoding='utf-8') as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            entry = json.loads(line)
            entries.append(entry)
            skills[entry.get('skill', 'unknown')] += 1
            types[entry.get('type', 'unknown')] += 1
        except json.JSONDecodeError:
            continue

print(f"  总条目: {len(entries)}")
print("  受影响 Skill:")
for sk, cnt in skills.most_common(10):
    print(f"    - {sk}: {cnt} 条")
print("  问题类型:")
for tp, cnt in types.most_common():
    print(f"    - {tp}: {cnt} 条")

# 输出受影响的 skill 列表供后续处理
print("__SKILLS__")
for sk in skills:
    print(sk)
PYEOF
)
  echo "$SUMMARY"
  AFFECTED_SKILLS=$(echo "$SUMMARY" | sed -n '/^__SKILLS__/,$p' | tail -n +2)
else
  echo "  [WARN] python3 不可用，跳过分类分析"
  AFFECTED_SKILLS=""
fi

# --- 更新 common-errors.md ---
echo ""
echo "[2/3] 蒸馏到 common-errors.md..."

if [ -n "$AFFECTED_SKILLS" ] && [ "$DRY_RUN" = false ]; then
  # 追加蒸馏条目
  TIMESTAMP=$(date '+%Y-%m-%d')
  {
    echo ""
    echo "## ${TIMESTAMP} 反馈蒸馏"
    echo ""
    while IFS= read -r line; do
      [ -z "$line" ] && continue
      echo "- 来自 \`$line\` 的反馈已合并（详见反馈日志）"
    done <<< "$AFFECTED_SKILLS"
    echo ""
  } >> "$COMMON_ERRORS"
  echo "  已追加 $TIMESTAMP 蒸馏条目到 common-errors.md"
elif [ "$DRY_RUN" = true ]; then
  echo "  [DRY-RUN] 将更新以下 skill 的 common-errors:"
  echo "$AFFECTED_SKILLS" | while read -r sk; do
    [ -z "$sk" ] && continue
    echo "    - $sk"
  done
fi

# --- 归档反馈日志 ---
echo ""
echo "[3/3] 归档..."

ARCHIVE_DIR="${ROOT_DIR}/.workbuddy/feedback/archive"
if [ "$DRY_RUN" = false ]; then
  mkdir -p "$ARCHIVE_DIR"
  ARCHIVE_NAME="feedback-$(date '+%Y-%m').jsonl"
  cp "$FEEDBACK_FILE" "${ARCHIVE_DIR}/${ARCHIVE_NAME}"
  # 清空当前反馈日志（已归档）
  > "$FEEDBACK_FILE"
  echo "  已归档到: ${ARCHIVE_DIR}/${ARCHIVE_NAME}"
  echo "  当前反馈日志已清空"
else
  echo "  [DRY-RUN] 将归档到: ${ARCHIVE_DIR}/feedback-$(date '+%Y-%m').jsonl"
fi

echo ""
echo "========================================"
echo "  蒸馏完成"
echo "========================================"
