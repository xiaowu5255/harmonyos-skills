#!/bin/bash
# ============================================================
# harmony-sign-check — 签名配置全链路一键排查
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
  local found=$(find "$ROOT_DIR" -maxdepth 3 -name "build-profile.json5" -print -quit 2>/dev/null)
  if [ -n "$found" ]; then
    dirname "$found"
    return 0
  fi
  return 1
}

PROJECT_ROOT=$(find_project_root "$ROOT_DIR" || echo "")
if [ -z "$PROJECT_ROOT" ]; then
  echo -e "${RED}[FAIL]${NC} 未找到鸿蒙工程"
  exit 1
fi

echo "=========================================="
echo "  签名配置全链路排查"
echo "  工程: $PROJECT_ROOT"
echo "=========================================="

ERRORS=0
WARNINGS=0

# --- 1. 签名材料存在性 ---
echo ""
echo "[1/4] 签名材料存在性检查..."

APP_JSON="$PROJECT_ROOT/AppScope/app.json5"
BUILD_PROFILE="$PROJECT_ROOT/build-profile.json5"

# bundleName
if [ -f "$APP_JSON" ]; then
  BUNDLE=$(grep -oP 'bundleName:\s*"\K[^"]+' "$APP_JSON" || echo "")
  if [ -n "$BUNDLE" ]; then
    echo -e "  ${GREEN}[OK]${NC} bundleName: $BUNDLE"
  else
    echo -e "  ${RED}[ERR]${NC} AppScope/app.json5 中未找到 bundleName"
    ERRORS=$((ERRORS + 1))
  fi
else
  echo -e "  ${RED}[ERR]${NC} AppScope/app.json5 不存在"
  ERRORS=$((ERRORS + 1))
fi

# signingConfigs in build-profile.json5
if [ -f "$BUILD_PROFILE" ]; then
  echo "  检查 signingConfigs..."
  
  # 检查是否有签名配置
  if grep -q 'signingConfigs' "$BUILD_PROFILE"; then
    echo -e "  ${GREEN}[OK]${NC} build-profile.json5 包含 signingConfigs"
    
    # 检查 storeFile 路径
    STORE_FILES=$(grep -oP 'storeFile:\s*"\K[^"]+' "$BUILD_PROFILE" || echo "")
    if [ -n "$STORE_FILES" ]; then
      for sf in $STORE_FILES; do
        if [ -f "$PROJECT_ROOT/$sf" ]; then
          echo -e "  ${GREEN}[OK]${NC} storeFile: $sf (存在)"
        else
          echo -e "  ${RED}[ERR]${NC} storeFile: $sf (文件不存在！)"
          ERRORS=$((ERRORS + 1))
        fi
      done
    fi
  else
    echo -e "  ${YELLOW}[WARN]${NC} build-profile.json5 中未配置 signingConfigs (调试签名模式)"
    WARNINGS=$((WARNINGS + 1))
  fi
fi

# --- 2. 一致性核对 ---
echo ""
echo "[2/4] 一致性核对..."
echo "  提示: 请在 AGC 控制台 > 我的项目 > 对应应用 中核对:"
echo "    - Profile 绑定的包名是否与 $BUNDLE 一致"
echo "    - 证书指纹是否匹配本地 p12"
echo "    - 设备列表中是否含当前测试机 UDID"
echo "  需要手动完成（无法自动化验证证书内容）"

# --- 3. UDID 检查 ---
echo ""
echo "[3/4] 设备 UDID 检查..."
if command -v hdc &>/dev/null; then
  DEVICES=$(hdc list targets 2>/dev/null || echo "")
  if [ -n "$DEVICES" ]; then
    for dev in $DEVICES; do
      UDID=$(hdc -t "$dev" shell bm get --udid 2>/dev/null || echo "获取失败")
      echo "  设备 $dev → UDID: $UDID"
    done
  else
    echo -e "  ${YELLOW}[WARN]${NC} 无设备在线，跳过 UDID 检查"
    WARNINGS=$((WARNINGS + 1))
  fi
else
  echo -e "  ${YELLOW}[WARN]${NC} hdc 不可用，跳过 UDID 检查"
  WARNINGS=$((WARNINGS + 1))
fi

# --- 4. 汇总 ---
echo ""
echo "[4/4] 五步排查清单..."
echo "  详见 signing-and-certificates 技能正文"

echo ""
echo "=========================================="
echo "  排查汇总"
echo "=========================================="
echo -e "${RED}错误: $ERRORS${NC}"
echo -e "${YELLOW}警告: $WARNINGS${NC}"

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
  echo -e "${GREEN}签名配置自检通过！${NC}"
else
  echo ""
  echo "下一步操作建议:"
  echo "  1. 补充缺失的 .p12 / .cer / .p7b 文件"
  echo "  2. 登录 AGC 控制台核对 Profile 绑定信息"
  echo "  3. 核对设备 UDID 是否在 Profile 设备列表中"
  echo "  4. 确认调试/发布证书类型匹配当前构建模式"
fi
