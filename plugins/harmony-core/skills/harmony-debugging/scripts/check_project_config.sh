#!/usr/bin/env bash
# check_project_config.sh — 鸿蒙工程配置一致性自检
# 用法: ./check_project_config.sh <工程根目录>
# 输出结构化检查结果,供 agent 诊断时作为第一步。只读,不修改任何文件。

set -u
ROOT="${1:-.}"
PASS=0; WARN=0; FAIL=0

ok()   { echo "[PASS] $1"; PASS=$((PASS+1)); }
warn() { echo "[WARN] $1"; WARN=$((WARN+1)); }
fail() { echo "[FAIL] $1"; FAIL=$((FAIL+1)); }

echo "=== HarmonyOS 工程自检: $ROOT ==="

# 1. 关键文件存在性
BP="$ROOT/build-profile.json5"
APP="$ROOT/AppScope/app.json5"
[ -f "$BP" ]  && ok "build-profile.json5 存在" || fail "缺少 build-profile.json5 —— 当前目录可能不是工程根目录"
[ -f "$APP" ] && ok "AppScope/app.json5 存在"  || warn "缺少 AppScope/app.json5"

# 2. SDK 版本声明(json5 容忍注释,用 grep 粗提取)
if [ -f "$BP" ]; then
  COMPAT=$(grep -oE '"compatibleSdkVersion"[^,}]*' "$BP" | head -1)
  TARGET=$(grep -oE '"targetSdkVersion"[^,}]*' "$BP" | head -1)
  [ -n "$COMPAT" ] && echo "[INFO] $COMPAT" || warn "build-profile.json5 中未找到 compatibleSdkVersion"
  [ -n "$TARGET" ] && echo "[INFO] $TARGET"
  # 3. 签名配置
  if grep -q '"signingConfigs"' "$BP"; then
    for f in $(grep -oE '"(certpath|storeFile|profile)"[[:space:]]*:[[:space:]]*"[^"]+"' "$BP" | sed -E 's/.*:\s*"([^"]+)"/\1/'); do
      case "$f" in /*) p="$f";; *) p="$ROOT/$f";; esac
      [ -f "$p" ] && ok "签名材料存在: $f" || fail "签名材料缺失: $f (p12/cer/p7b 路径失效是签名报错最常见根因)"
    done
  else
    warn "未配置 signingConfigs —— debug 构建需在 DevEco 登录账号启用自动签名"
  fi
fi

# 4. bundleName 一致性(app.json5 vs 各模块引用)
if [ -f "$APP" ]; then
  BN=$(grep -oE '"bundleName"[[:space:]]*:[[:space:]]*"[^"]+"' "$APP" | sed -E 's/.*"([^"]+)"$/\1/')
  [ -n "$BN" ] && echo "[INFO] bundleName: $BN" || warn "app.json5 中未找到 bundleName"
fi

# 5. 模块声明 vs 实际目录
if [ -f "$BP" ]; then
  for m in $(grep -oE '"srcPath"[[:space:]]*:[[:space:]]*"[^"]+"' "$BP" | sed -E 's/.*"([^"]+)"$/\1/'); do
    [ -d "$ROOT/${m#./}" ] && ok "模块目录存在: $m" || fail "build-profile.json5 声明的模块目录不存在: $m"
  done
fi

# 6. 端云一体化配置(若是云开发工程)
AGC=$(find "$ROOT" -path "*/resources/rawfile/agconnect-services.json" 2>/dev/null | head -1)
if [ -n "$AGC" ]; then
  ok "检测到端云工程,agconnect-services.json 存在"
  grep -q '"client"' "$AGC" || fail "agconnect-services.json 内容异常(缺少 client 节点),需从 AGC 重新下载"
fi

# 7. 依赖与构建缓存
[ -d "$ROOT/oh_modules" ] || warn "oh_modules 不存在 —— 先执行 ohpm install"
[ -d "$ROOT/.hvigor" ] && echo "[INFO] 存在 .hvigor 缓存(构建行为诡异时可删除重建)"

echo "=== 结果: $PASS pass / $WARN warn / $FAIL fail ==="
[ "$FAIL" -gt 0 ] && exit 1 || exit 0
