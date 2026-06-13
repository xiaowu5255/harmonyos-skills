#!/bin/bash
# ============================================================
# harmony-doctor — 鸿蒙开发环境与工程健康一键诊断
# 独立脚本，不依赖 Claude Code；Codex/OpenCode/终端均可使用
# ============================================================
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOOLS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ROOT_DIR="${1:-$(pwd)}"

echo "=========================================="
echo "  HarmonyOS 环境诊断"
echo "  目标目录: $ROOT_DIR"
echo "=========================================="

ERRORS=0
WARNINGS=0

# --- 1. 工程根目录定位 ---
echo ""
echo "[1/4] 定位工程根目录..."

find_project_root() {
  local dir="$1"
  while [ "$dir" != "/" ] && [ "$dir" != "." ]; do
    if [ -f "$dir/build-profile.json5" ]; then
      echo "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  # 向下搜索
  local found=$(find "$ROOT_DIR" -maxdepth 3 -name "build-profile.json5" -print -quit 2>/dev/null)
  if [ -n "$found" ]; then
    dirname "$found"
    return 0
  fi
  return 1
}

PROJECT_ROOT=$(find_project_root "$ROOT_DIR" || echo "")

if [ -z "$PROJECT_ROOT" ]; then
  echo -e "${RED}[FAIL]${NC} 未找到 build-profile.json5，当前目录不是鸿蒙工程"
  echo "  请传入工程根目录: bash tools/commands/harmony-doctor.sh /path/to/project"
  echo "  或在工程根目录下运行"
  exit 1
fi

echo -e "${GREEN}[OK]${NC} 工程根目录: $PROJECT_ROOT"
ROOT_DIR="$PROJECT_ROOT"

# --- 2. 工具链检查 ---
echo ""
echo "[2/4] 检查工具链..."

check_tool() {
  local name="$1"
  local cmd="$2"
  if command -v "$cmd" &>/dev/null; then
    local ver=$($cmd 2>&1 | head -1 || echo "unknown")
    echo -e "  ${GREEN}[OK]${NC} $name: $(which "$cmd") — $ver"
  else
    echo -e "  ${YELLOW}[WARN]${NC} $name 未安装或不在 PATH"
    WARNINGS=$((WARNINGS + 1))
  fi
}

check_tool "hdc" "hdc"
check_tool "ohpm" "ohpm"
check_tool "node" "node"
check_tool "java" "java"

# hdc device check
echo ""
echo "  检查已连接设备..."
if command -v hdc &>/dev/null; then
  DEVICES=$(hdc list targets 2>/dev/null || echo "")
  if [ -z "$DEVICES" ]; then
    echo -e "  ${YELLOW}[WARN]${NC} 无设备/模拟器在线"
    WARNINGS=$((WARNINGS + 1))
  else
    echo -e "  ${GREEN}[OK]${NC} 在线设备: $DEVICES"
  fi
fi

# --- 3. SDK 版本比对 ---
echo ""
echo "[3/4] 检查 SDK 版本..."

# 读 build-profile.json5 中的 compatibleSdkVersion
BUILD_PROFILE="$ROOT_DIR/build-profile.json5"
if [ -f "$BUILD_PROFILE" ]; then
  COMP_SDK=$(grep -oP 'compatibleSdkVersion:\s*\K\d+' "$BUILD_PROFILE" | head -1 || echo "N/A")
  TARGET_SDK=$(grep -oP 'targetSdkVersion:\s*\K\d+' "$BUILD_PROFILE" | head -1 || echo "N/A")
  
  echo "  compatibleSdkVersion: $COMP_SDK"
  echo "  targetSdkVersion: $TARGET_SDK"

  # 检查本地已安装 SDK
  SDK_DIRS=(
    "$HOME/Huawei/Sdk"
    "$HOME/Library/Huawei/Sdk"
    "/Applications/DevEco-Studio.app/Contents/tools/sdk"
  )

  for SDK_DIR in "${SDK_DIRS[@]}"; do
    if [ -d "$SDK_DIR" ]; then
      INSTALLED_APIS=$(ls -d "$SDK_DIR"/*/ets 2>/dev/null | grep -oP '\d+(?=/ets)' | sort -n | tr '\n' ' ' || echo "N/A")
      echo "  已安装 API: $INSTALLED_APIS"

      # 检查 compatibleSdkVersion 是否已安装
      if echo "$INSTALLED_APIS" | grep -qw "$COMP_SDK"; then
        echo -e "  ${GREEN}[OK]${NC} compatibleSdkVersion($COMP_SDK) 已安装"
      else
        echo -e "  ${RED}[ERR]${NC} compatibleSdkVersion($COMP_SDK) 未安装！请在 DevEco Studio SDK Manager 中安装"
        ERRORS=$((ERRORS + 1))
      fi
      break
    fi
  done
else
  echo -e "  ${RED}[ERR]${NC} build-profile.json5 不可读"
  ERRORS=$((ERRORS + 1))
fi

# --- 4. 运行工程配置检查脚本 ---
echo ""
echo "[4/4] 运行工程配置检查..."

CHECK_SCRIPT="$TOOLS_DIR/../plugins/harmony-core/skills/harmony-debugging/scripts/check_project_config.sh"
if [ -f "$CHECK_SCRIPT" ]; then
  # 该脚本依赖 .claude 环境，这里做简化分析
  echo "  config 检查脚本存在于: $CHECK_SCRIPT"
  echo "  请手动运行: bash $CHECK_SCRIPT $ROOT_DIR"
else
  echo -e "  ${YELLOW}[WARN]${NC} check_project_config.sh 不存在"
  WARNINGS=$((WARNINGS + 1))
fi

# --- 汇总报告 ---
echo ""
echo "=========================================="
echo "  诊断报告"
echo "=========================================="
echo ""

echo -e "${RED}错误: $ERRORS${NC}"
echo -e "${YELLOW}警告: $WARNINGS${NC}"

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
  echo -e "${GREEN}环境健康！${NC}"
elif [ $ERRORS -eq 0 ]; then
  echo -e "${YELLOW}有 $WARNINGS 个警告，建议处理。${NC}"
else
  echo -e "${RED}有 $ERRORS 个错误需要修复！${NC}"
fi

echo ""
echo "待办事项（按严重度排序）："
if [ $ERRORS -gt 0 ]; then
  echo "  [严重] 安装缺失的 SDK API 版本"
  echo "  [严重] 检查 build-profile.json5 配置"
fi
if [ $WARNINGS -gt 0 ]; then
  echo "  [建议] 安装缺失的 CLI 工具"
  echo "  [建议] 连接设备/启动模拟器"
fi
