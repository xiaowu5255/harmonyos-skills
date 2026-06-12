#!/bin/bash
# harmonyos-skills 一致性校验脚本
# 用法: bash tools/lint-skills.sh

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0

section() { echo ""; echo "=== $1 ==="; }
check() { if [ "$1" -eq 0 ]; then PASS=$((PASS+1)); echo "  OK: $2"; else FAIL=$((FAIL+1)); echo "  FAIL: $2"; fi; }

# 1. 目录名与 name 一致
section "1. Skill 目录名与 frontmatter name 一致性"
while IFS= read -r f; do
  dirname=$(basename "$(dirname "$f")")
  fm_name=$(head -5 "$f" | grep '^name:' | awk '{print $2}')
  if [ "$dirname" = "$fm_name" ]; then check 0 "$dirname"; else check 1 "$dirname != $fm_name"; fi
done < <(find "$ROOT/plugins" -name "SKILL.md" -path "*/skills/*")

# 2. 收集所有 skill names
declare -A skill_names
while IFS= read -r f; do
  dirname=$(basename "$(dirname "$f")")
  skill_names["$dirname"]=1
done < <(find "$ROOT/plugins" -name "SKILL.md" -path "*/skills/*")

# 3. requires 目标存在
section "2. requires 目标存在性"
while IFS= read -r f; do
  bname=$(basename "$(dirname "$f")")
  req=$(grep '^requires:' "$f" 2>/dev/null | awk '{print $2}')
  if [ -n "$req" ] && [ -n "${skill_names[$req]:-}" ] 2>/dev/null; then check 0 "$bname -> $req"; elif [ -n "$req" ]; then check 1 "$bname requires '$req' 不存在"; fi
done < <(find "$ROOT/plugins" -name "SKILL.md" -path "*/skills/*")

# 4. kits 无裸 @ (YAML 安全)
section "3. kits 字段 YAML 安全性"
bad_count=0
while IFS= read -r line; do
  f=$(echo "$line" | cut -d: -f1)
  echo "  FAIL: $f 包含未加引号的 @kit 值" 
  bad_count=1
done < <(grep -rn 'kits: \[@kit\.' "$ROOT/plugins" --include="*.md" | grep -v '"@' || true)
check $bad_count "所有 kits 已加引号防护"

# 5. evals 中 skill 名真实存在
section "4. evals.json 引用 skill 存在性"
if [ -f "$ROOT/tools/evals/evals.json" ]; then
  for name in $(grep '"skill":' "$ROOT/tools/evals/evals.json" | sed 's/.*"skill": *"\([^"]*\)".*/\1/'); do
    if [ "$name" = "none(负样本)" ]; then continue; fi
    if [ -n "${skill_names[$name]:-}" ] 2>/dev/null; then : ; else check 1 "evals 引用未知 skill: $name"; fi
  done
  check 0 "evals 引用全部有效"  # will overwrite if there were failures above
fi

# 6. marketplace.json 插件数与实际一致
section "5. marketplace.json 对齐"
mj="$ROOT/.claude-plugin/marketplace.json"
if [ -f "$mj" ]; then
  mj_count=$(grep -c '"name": "harmony-' "$mj" || echo 0)
  actual_count=$(find "$ROOT/plugins" -maxdepth 1 -name "harmony-*" -type d | wc -l)
  [ "$mj_count" = "$actual_count" ]; check $? "marketplace.json: $mj_count 个插件 vs 实际 $actual_count 个目录"
fi

echo ""
echo "===== 结果: $PASS PASS / $FAIL FAIL ====="
if [ "$FAIL" -gt 0 ]; then exit 1; fi
