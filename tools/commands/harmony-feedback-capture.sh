#!/bin/bash
# ============================================================
# harmony-feedback-capture — 捕获并格式化鸿蒙开发踩坑记录
# 作为 /harmony-feedback 命令的独立脚本版本
# 蒸馏管道主流程见 tools/feedback-distill.sh
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
FEEDBACK_FILE="$ROOT_DIR/.workbuddy/feedback/feedback-log.jsonl"

mkdir -p "$(dirname "$FEEDBACK_FILE")"

SHOW_HELP=false
SKILL=""
TYPE=""
DETAIL=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --skill) SKILL="$2"; shift 2 ;;
    --type)  TYPE="$2"; shift 2 ;;
    --detail) DETAIL="$2"; shift 2 ;;
    --help|-h) SHOW_HELP=true; shift ;;
    *) echo "未知参数: $1"; shift ;;
  esac
done

if $SHOW_HELP || [ -z "$DETAIL" ]; then
  echo "用法: harmony-feedback-capture.sh --skill <skill名> --type <类型> --detail '<描述>'"
  echo ""
  echo "参数:"
  echo "  --skill   出问题的 skill 名称 (如 arkts-syntax)"
  echo "  --type    问题类型 (api-error / doc-error / crash / build / runtime)"
  echo "  --detail  报错原文片段或描述"
  echo ""
  echo "类型枚举:"
  echo "  api-error   API 使用错误（方法签名、参数类型等）"
  echo "  doc-error    文档错误或误导"
  echo "  build       编译/构建问题"
  echo "  runtime     运行时问题"
  echo "  crash       闪退/崩溃"
  echo "  performance 性能问题"
  echo ""
  echo "示例:"
  echo "  bash tools/commands/harmony-feedback-capture.sh \\"
  echo "    --skill arkts-syntax --type api-error \\"
  echo "    --detail 'obj?.prop ?? defaultValue 语法编译报 arkts-no-optional-chaining'"
  exit 0
fi

# 写入 feedback 日志
ENTRY=$(cat <<EOF
{"skill":"$SKILL","type":"$TYPE","detail":"$DETAIL","date":"$(date -Iseconds)"}
EOF
)

echo "$ENTRY" >> "$FEEDBACK_FILE"
echo "反馈已记录:"
echo "  Skill: $SKILL"
echo "  类型: $TYPE"
echo "  时间: $(date '+%Y-%m-%d %H:%M')"
echo ""
echo "每月运行 tools/feedback-distill.sh 蒸馏到 common-errors.md"
