#!/usr/bin/env bash
# PostToolUse hook:Claude 写入/编辑 .ets 文件后做静态自检,把发现注入为上下文提醒。
# 检查器优先级(从强到弱,命中即用):
#   1. OpenHarmony 官方 ArkTS linter-cli(真编译器诊断)—— 需配置 HARMONY_ARKTS_LINTER
#   2. DevEco codelinter(在 PATH 上时)
#   3. 内置 grep 快检(兜底,提示性质,可能误报)
INPUT=$(cat)
FILE=$(echo "$INPUT" | grep -oE '"file_path"[[:space:]]*:[[:space:]]*"[^"]+"' | head -1 | sed -E 's/.*"([^"]+)"$/\1/')

case "$FILE" in
  *.ets) ;;
  *) exit 0 ;;
esac
[ -f "$FILE" ] || exit 0

# ── 1. 官方 ArkTS linter-cli ──
# HARMONY_ARKTS_LINTER 指向 linter-cli.js 或其所在目录(来自 harmonyos-agent-rules 的 arkts-rules/tools/linter-cli)。
# HARMONY_SDK_PATH(可选)指向 OpenHarmony ETS SDK 根,如 .../sdk/default。
resolve_linter() {
  local p="$HARMONY_ARKTS_LINTER"
  [ -z "$p" ] && return 1
  if [ -d "$p" ]; then
    [ -f "$p/bin/linter-cli.js" ] && { echo "$p/bin/linter-cli.js"; return 0; }
    [ -f "$p/linter-cli.js" ] && { echo "$p/linter-cli.js"; return 0; }
    return 1
  fi
  [ -f "$p" ] && { echo "$p"; return 0; }
  return 1
}

if LINTER=$(resolve_linter) && command -v node >/dev/null 2>&1; then
  ARGS=(--input "$FILE")
  [ -n "${HARMONY_SDK_PATH:-}" ] && ARGS+=(--sdk-path "$HARMONY_SDK_PATH")
  [ -n "${HARMONY_LINTER_CACHE:-}" ] && ARGS+=(--cache-dir "$HARMONY_LINTER_CACHE")
  OUT=$(node "$LINTER" "${ARGS[@]}" 2>&1 | head -40)
  if echo "$OUT" | grep -q 'Lint Check: OK'; then
    : # 通过,静默
  elif [ -n "$OUT" ]; then
    echo "[ets-lint-gate] 官方 ArkTS linter 对 $FILE 的诊断(请评估并修复):"
    echo "$OUT"
  fi
  exit 0
fi

# ── 2. DevEco codelinter ──
if command -v codelinter >/dev/null 2>&1; then
  OUT=$(codelinter "$FILE" 2>&1 | head -30)
  [ -n "$OUT" ] && echo "[ets-lint-gate] codelinter 对 $FILE 的输出(前30行,请评估并修复):" && echo "$OUT"
  exit 0
fi

# ── 3. 兜底:ArkTS 高频违规的快速 grep(非完整检查,提示性质) ──
WARN=""
grep -nE '(^|[^a-zA-Z])var\s' "$FILE" >/dev/null && WARN="$WARN\n- 检测到 var 声明(ArkTS 禁止,改用 let/const)"
grep -nE ':\s*any\b|as\s+any\b' "$FILE" >/dev/null && WARN="$WARN\n- 检测到 any 类型(arkts-no-any-unknown,需显式类型)"
grep -nE ':\s*unknown\b' "$FILE" >/dev/null && WARN="$WARN\n- 检测到 unknown 类型(arkts-no-any-unknown,需显式类型)"
grep -nE '\bdelete\s+[a-zA-Z_]' "$FILE" >/dev/null && WARN="$WARN\n- 检测到 delete 属性操作(对象布局不可变,改用 Map)"
grep -nE '(const|let)\s*\{[^}]*\}\s*=' "$FILE" >/dev/null && WARN="$WARN\n- 疑似解构声明(arkts-no-destruct-decls,禁止,改显式访问)"
grep -nE 'for\s*\([^)]*\bin\b[^)]*\)' "$FILE" >/dev/null && WARN="$WARN\n- 检测到 for..in(ArkTS 禁止,改 for..of/索引)"
if [ -n "$WARN" ]; then
  printf '[ets-lint-gate] %s 存在疑似 ArkTS 违规(grep 快检,可能有误报,请核实修复):%b\n' "$FILE" "$WARN"
  printf '[ets-lint-gate] 提示:配置 HARMONY_ARKTS_LINTER 可启用官方编译器级诊断(见 arkts-syntax/references/arkts-linter-setup.md)。\n'
fi
exit 0
