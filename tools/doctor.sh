#!/usr/bin/env bash
# harmonyos-skills 工程健康一键诊断
# 用法: bash tools/doctor.sh [工程根目录]
# 输出: 标准化诊断报告(可读 + JSON 两段)
# 不修改任何文件;只读诊断。

set -u
ROOT="${1:-.}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CHECK_SH="$SCRIPT_DIR/../plugins/harmony-core/skills/harmony-debugging/scripts/check_project_config.sh"

PASS=0; WARN=0; FAIL=0

ok()   { echo "[PASS] $1"; PASS=$((PASS+1)); }
warn() { echo "[WARN] $1"; WARN=$((WARN+1)); }
fail() { echo "[FAIL] $1"; FAIL=$((FAIL+1)); }

echo "=========================================="
echo "  HarmonyOS 工程诊断: $ROOT"
echo "=========================================="
echo ""

# ── 1. 工程配置一致性 ──
echo "=== [1/4] 工程配置一致性 ==="
if [ -f "$CHECK_SH" ]; then
  bash "$CHECK_SH" "$ROOT" || true
else
  fail "check_project_config.sh 不存在: $CHECK_SH"
fi
echo ""

# ── 2. 工具链可用性 ──
echo "=== [2/4] 工具链可用性 ==="
check_tool() {
  local name="$1" cmd="$2" required="$3"
  if command -v "$cmd" >/dev/null 2>&1; then
    local ver
    ver=$("$cmd" --version 2>&1 | head -1 || echo "?")
    ok "$name 已安装: $ver"
  else
    if [ "$required" = "required" ]; then
      fail "$name 未安装 ($cmd 不在 PATH)"
    else
      warn "$name 未安装 ($cmd 不在 PATH)"
    fi
  fi
}

check_tool "DevEco CLI / hdc"    "hdc"    "optional"
check_tool "ohpm"                "ohpm"   "optional"
check_tool "Node.js"             "node"   "optional"
check_tool "hvigorw"             "hvigorw" "optional"
check_tool "Rust toolchain"      "rustc"  "optional"
check_tool "cargo"               "cargo"  "optional"
echo ""

# ── 3. 设备/模拟器在线 ──
echo "=== [3/4] 设备/模拟器在线 ==="
if command -v hdc >/dev/null 2>&1; then
  targets=$(hdc list targets 2>&1 || true)
  if [ -n "$targets" ] && ! echo "$targets" | grep -qi "empty\|error"; then
    dev_count=$(echo "$targets" | grep -c "^[0-9a-fA-F]" || echo 0)
    if [ "$dev_count" -gt 0 ]; then
      ok "hdc 列出 $dev_count 个设备/模拟器在线"
      echo "$targets" | sed 's/^/    /'
    else
      warn "hdc 列出 0 个设备/模拟器(可能需要 hdc start 或打开模拟器)"
    fi
  else
    warn "hdc list targets 返回空或错误(检查 hdc 服务是否启动)"
  fi
else
  warn "hdc 未安装,跳过设备检查"
fi
echo ""

# ── 4. SDK 版本核对 ──
echo "=== [4/4] build-profile.json5 SDK 版本 ==="
BP="$ROOT/build-profile.json5"
if [ -f "$BP" ]; then
  compatible=$(grep -E 'compatibleSdkVersion' "$BP" | head -1 | grep -oE '[0-9]+' | head -1)
  target=$(grep -E 'targetSdkVersion' "$BP" | head -1 | grep -oE '[0-9]+' | head -1)
  echo "  compatibleSdkVersion: ${compatible:-未找到}"
  echo "  targetSdkVersion:     ${target:-未找到}"
  if [ -n "$compatible" ]; then
    ok "build-profile.json5 SDK 版本已读取"
  else
    warn "无法解析 compatibleSdkVersion(文件格式可能非标准)"
  fi
else
  warn "build-profile.json5 不存在(可能非鸿蒙工程根目录)"
fi
echo ""

# ── 汇总 ──
echo "=========================================="
echo "  诊断汇总: ${PASS} PASS / ${WARN} WARN / ${FAIL} FAIL"
echo "=========================================="

# 退出码:FAIL>0 返回 1(供 CI 拦截用)
[ "$FAIL" -eq 0 ] || exit 1