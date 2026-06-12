#!/usr/bin/env bash
# PostToolUse hook:Claude 写入/编辑 .ets 文件后做快速静态自检。
# 有 codelinter 时用官方检查;没有时做基础模式检查,把发现注入为上下文提醒。
INPUT=$(cat)
FILE=$(echo "$INPUT" | grep -oE '"file_path"[[:space:]]*:[[:space:]]*"[^"]+"' | head -1 | sed -E 's/.*"([^"]+)"$/\1/')

case "$FILE" in
  *.ets) ;;
  *) exit 0 ;;
esac
[ -f "$FILE" ] || exit 0

if command -v codelinter >/dev/null 2>&1; then
  OUT=$(codelinter "$FILE" 2>&1 | head -30)
  [ -n "$OUT" ] && echo "[ets-lint-gate] codelinter 对 $FILE 的输出(前30行,请评估并修复):" && echo "$OUT"
  exit 0
fi

# 兜底:ArkTS 高频违规的快速 grep(非完整检查,提示性质)
WARN=""
grep -nE '(^|[^a-zA-Z])var\s' "$FILE" >/dev/null && WARN="$WARN\n- 检测到 var 声明(ArkTS 禁止,改用 let/const)"
grep -nE ':\s*any\b|as\s+any\b' "$FILE" >/dev/null && WARN="$WARN\n- 检测到 any 类型(arkts-no-any-unknown,需显式类型)"
grep -nE '\bdelete\s+[a-zA-Z_]' "$FILE" >/dev/null && WARN="$WARN\n- 检测到 delete 属性操作(对象布局不可变,改用 Map)"
if [ -n "$WARN" ]; then
  printf '[ets-lint-gate] %s 存在疑似 ArkTS 违规(grep 快检,可能有误报,请核实修复):%b\n' "$FILE" "$WARN"
fi
exit 0
