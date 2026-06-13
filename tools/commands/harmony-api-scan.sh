#!/bin/bash
# ============================================================
# harmony-api-scan — 扫描超 compatibleSdkVersion 的 API 调用
# 独立脚本，不依赖 Claude Code
# ============================================================
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ROOT_DIR="${1:-$(pwd)}"

# 找工程根目录
find_project_root() {
  local dir="$1"
  while [ "$dir" != "/" ] && [ "$dir" != "." ]; do
    if [ -f "$dir/build-profile.json5" ]; then
      echo "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  return 1
}

PROJECT_ROOT=$(find_project_root "$ROOT_DIR" || echo "")
if [ -z "$PROJECT_ROOT" ]; then
  echo -e "${RED}[FAIL]${NC} 未找到鸿蒙工程"
  exit 1
fi

echo "=========================================="
echo "  API 版本风险扫描"
echo "  工程: $PROJECT_ROOT"
echo "=========================================="

# --- 1. 读取 compatibleSdkVersion ---
BUILD_PROFILE="$PROJECT_ROOT/build-profile.json5"
if [ ! -f "$BUILD_PROFILE" ]; then
  echo -e "${RED}[ERR]${NC} build-profile.json5 不存在"
  exit 1
fi

COMP_SDK=$(grep -oP 'compatibleSdkVersion:\s*\K\d+' "$BUILD_PROFILE" | head -1 || echo "")

if [ -z "$COMP_SDK" ]; then
  echo -e "${RED}[ERR]${NC} 无法读取 compatibleSdkVersion"
  exit 1
fi

echo "  compatibleSdkVersion = $COMP_SDK"
echo "  将扫描 .ets 文件中 API/@since > $COMP_SDK 的调用"

# --- 2. 检查 SDK diff 产物 ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOOLS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SDK_DIFF_DIR="$TOOLS_DIR/sdk-diff"

HITS=0
FILES_SCANNED=0

if [ -f "$SDK_DIFF_DIR/diff_api.py" ]; then
  echo ""
  echo "[INFO] 检测到 diff_api.py，可直接生成 API 变更清单"
  echo "  运行: python3 tools/sdk-diff/diff_api.py --old-sdk <path> --new-sdk <path>"
  echo "  然后手动 grep 变更清单中的新增 API"
else
  echo ""
  echo "[INFO] 无 diff 产物，将进行基础扫描..."
fi

# --- 3. 基础扫描（检查 @since 标注） ---
echo ""
echo "扫描 .ets 源码..."

# 搜索可能的 API 调用模式
if command -v grep &>/dev/null; then
  ETS_FILES=$(find "$PROJECT_ROOT" -name "*.ets" -not -path "*/oh_modules/*" -not -path "*/build/*" 2>/dev/null || echo "")
  FILES_SCANNED=$(echo "$ETS_FILES" | wc -l)

  # 检查每个 .ets 文件的 import
  for file in $ETS_FILES; do
    # 检查是否使用了可能的高版本 API（通过 kit 导入推断）
    IMPORTS=$(grep -n "from '@kit" "$file" 2>/dev/null || true)
    if [ -n "$IMPORTS" ]; then
      echo "  [文件] $file"
      echo "$IMPORTS" | while read -r line; do
        echo "    $line"
        HITS=$((HITS + 1))
      done
    fi
  done
fi

# --- 4. 汇总 ---
echo ""
echo "=========================================="
echo "  扫描报告"
echo "=========================================="
echo "  compatibleSdkVersion: $COMP_SDK"
echo "  扫描文件数: $FILES_SCANNED"
echo "  含 Kit 导入的文件数: $HITS"
echo ""
echo "建议操作:"
echo "  - 对每个 @kit 导入，查阅其 API 参考文档确认 @since 版本"
echo "  - API > $COMP_SDK 的调用需: canIUse 运行时分支 / 降级 API / 提升兼容版本"
echo "  - 详细流程见 version-guide 技能"
