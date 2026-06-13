#!/bin/bash
# ============================================================
# harmony-cloud-deploy — 端云一体化部署前检查
# 独立脚本，不依赖 Claude Code
# ============================================================
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ROOT_DIR="${1:-$(pwd)}"

echo "=========================================="
echo "  端云一体化部署前检查"
echo "  目标目录: $ROOT_DIR"
echo "=========================================="

ERRORS=0
WARNINGS=0

# --- 1. agconnect-services.json ---
echo ""
echo "[1/4] 检查 agconnect-services.json..."

AGC_JSON="$ROOT_DIR/entry/src/main/resources/rawfile/agconnect-services.json"
AGC_JSON_ALT="$ROOT_DIR/AppScope/agconnect-services.json"

if [ -f "$AGC_JSON" ]; then
  echo -e "  ${GREEN}[OK]${NC} 找到: $AGC_JSON"
  # 检查内容
  if grep -q 'client' "$AGC_JSON" 2>/dev/null; then
    echo -e "  ${GREEN}[OK]${NC} 文件内容不为空"
  else
    echo -e "  ${YELLOW}[WARN]${NC} 文件内容可能为空或格式异常"
    WARNINGS=$((WARNINGS + 1))
  fi
elif [ -f "$AGC_JSON_ALT" ]; then
  echo -e "  ${GREEN}[OK]${NC} 找到: $AGC_JSON_ALT (AppScope)"
else
  echo -e "  ${RED}[ERR]${NC} agconnect-services.json 不存在！"
  echo "  请在 AGC 控制台下载：项目设置 > 常规 > 下载 agconnect-services.json"
  ERRORS=$((ERRORS + 1))
fi

# --- 2. 云服务 SDK 依赖 ---
echo ""
echo "[2/4] 检查云服务 SDK 依赖..."

OH_PACKAGE="$ROOT_DIR/oh-package.json5"
ENTRY_PACKAGE="$ROOT_DIR/entry/oh-package.json5"

check_cloud_deps() {
  local file="$1"
  if [ -f "$file" ]; then
    echo "  检查 $file..."
    if grep -qE 'cloud|agconnect' "$file" 2>/dev/null; then
      echo -e "  ${GREEN}[OK]${NC} 含云服务依赖"
    else
      echo -e "  ${YELLOW}[WARN]${NC} 未发现云服务依赖声明"
      WARNINGS=$((WARNINGS + 1))
    fi
  fi
}

check_cloud_deps "$OH_PACKAGE"
check_cloud_deps "$ENTRY_PACKAGE"

# --- 3. 云侧工程结构 ---
echo ""
echo "[3/4] 检查云侧工程..."

CLOUD_DIR="$ROOT_DIR/CloudProgram"
if [ -d "$CLOUD_DIR" ]; then
  echo -e "  ${GREEN}[OK]${NC} CloudProgram/ 目录存在"
  
  # 云函数检查
  CF_DIR="$CLOUD_DIR/cloudfunctions"
  if [ -d "$CF_DIR" ]; then
    CF_COUNT=$(ls -d "$CF_DIR"/*/ 2>/dev/null | wc -l || echo 0)
    echo "  云函数数量: $CF_COUNT"
    
    # 检查每个云函数的 function-config.json
    for fn_dir in "$CF_DIR"/*/; do
      if [ -f "$fn_dir/function-config.json" ]; then
        echo -e "  ${GREEN}[OK]${NC} $(basename "$fn_dir"): 有 function-config.json"
      else
        echo -e "  ${YELLOW}[WARN]${NC} $(basename "$fn_dir"): 缺 function-config.json"
        WARNINGS=$((WARNINGS + 1))
      fi
    done
  else
    echo -e "  ${YELLOW}[WARN]${NC} cloudfunctions/ 目录不存在"
    WARNINGS=$((WARNINGS + 1))
  fi
  
  # 云数据库检查
  DB_DIRS=$(find "$CLOUD_DIR" -maxdepth 3 -name "clouddb" -type d 2>/dev/null || echo "")
  if [ -n "$DB_DIRS" ]; then
    echo -e "  ${GREEN}[OK]${NC} 有 clouddb 数据模型目录"
  else
    echo -e "  ${YELLOW}[WARN]${NC} 无 clouddb 目录（如不使用云数据库可忽略）"
  fi
else
  echo -e "  ${YELLOW}[WARN]${NC} CloudProgram/ 目录不存在（不是端云一体化工程）"
  WARNINGS=$((WARNINGS + 1))
fi

# --- 4. 部署顺序建议 ---
echo ""
echo "[4/4] 部署顺序建议..."

if [ $ERRORS -eq 0 ]; then
  echo "  推荐部署顺序:"
  echo "    1. 云数据库对象类型 → AGC 控制台"
  echo "    2. 云函数/云对象 → DevEco 右键 CloudProgram 部署"
  echo "    3. 端侧联调 → 运行应用测试"
  echo "  部署后验证:"
  echo "    - AGC 控制台 > 云函数 > 对应函数 > 测试（直测云函数）"
  echo "    - AGC 控制台 > 云数据库 > 数据管理（确认数据已创建）"
fi

# --- 汇总 ---
echo ""
echo "=========================================="
echo "  检查汇总"
echo "=========================================="
echo -e "${RED}错误: $ERRORS${NC}"
echo -e "${YELLOW}警告: $WARNINGS${NC}"

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
  echo -e "${GREEN}端云一体化工程配置完整！${NC}"
elif [ $ERRORS -eq 0 ]; then
  echo -e "${YELLOW}有 $WARNINGS 个警告，建议处理后再部署。${NC}"
else
  echo -e "${RED}有 $ERRORS 个错误需要修复！${NC}"
  echo "  - 下载 agconnect-services.json"
  echo "  - 补充云函数 function-config.json"
fi
