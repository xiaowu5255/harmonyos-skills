#!/usr/bin/env bash
# 对单个 .ets 文件做 ArkTS 静态检查,返回真实编译器诊断(配置了官方 linter 时)。
# 用法: bash arkts-lint.sh <file.ets>
# 环境变量:
#   HARMONY_ARKTS_LINTER  指向 OpenHarmony linter-cli(linter-cli.js 或其目录)。
#                         来源:harmonyos-agent-rules 仓库 arkts-rules/tools/linter-cli。
#   HARMONY_SDK_PATH      可选,OpenHarmony ETS SDK 根(如 .../sdk/default)。
#   HARMONY_LINTER_CACHE  可选,checker 缓存目录。
# 退出码: 0=通过/无法检查; 1=发现诊断或文件无效。
set -uo pipefail

FILE="${1:-}"
if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
  echo "用法: bash arkts-lint.sh <file.ets>"; exit 1
fi
case "$FILE" in *.ets|*.ts) ;; *) echo "仅支持 .ets/.ts: $FILE"; exit 1;; esac

# 解析官方 linter 路径
LINTER=""
if [ -n "${HARMONY_ARKTS_LINTER:-}" ]; then
  if [ -d "$HARMONY_ARKTS_LINTER" ]; then
    [ -f "$HARMONY_ARKTS_LINTER/bin/linter-cli.js" ] && LINTER="$HARMONY_ARKTS_LINTER/bin/linter-cli.js"
    [ -z "$LINTER" ] && [ -f "$HARMONY_ARKTS_LINTER/linter-cli.js" ] && LINTER="$HARMONY_ARKTS_LINTER/linter-cli.js"
  elif [ -f "$HARMONY_ARKTS_LINTER" ]; then
    LINTER="$HARMONY_ARKTS_LINTER"
  fi
fi

if [ -n "$LINTER" ] && command -v node >/dev/null 2>&1; then
  ARGS=(--input "$FILE")
  [ -n "${HARMONY_SDK_PATH:-}" ] && ARGS+=(--sdk-path "$HARMONY_SDK_PATH")
  [ -n "${HARMONY_LINTER_CACHE:-}" ] && ARGS+=(--cache-dir "$HARMONY_LINTER_CACHE")
  echo "== 官方 ArkTS linter: $LINTER =="
  OUT=$(node "$LINTER" "${ARGS[@]}" 2>&1)
  echo "$OUT"
  echo "$OUT" | grep -q 'Lint Check: OK' && exit 0 || exit 1
fi

# 回退到 codelinter
if command -v codelinter >/dev/null 2>&1; then
  echo "== DevEco codelinter =="
  codelinter "$FILE"; exit $?
fi

echo "未配置官方 ArkTS linter,也未找到 codelinter。"
echo "请参考 references/arkts-linter-setup.md 安装,或在 DevEco 中运行 CodeLinter。"
exit 0
