#!/bin/bash
# harmonyos-skills 一致性校验脚本
# 用法: bash tools/lint-skills.sh
# 检查项:
#   1. skill 目录名与 frontmatter name 一致
#   2. requires 目标存在
#   3. kits 字段无裸 @(YAML 合法性)
#   4. evals.json 引用的 skill 存在
#   5. marketplace.json 与 plugins/ 目录一致
#   6. plugin.json 的 skills 清单与目录双向一致
#   7. SKILL.md 正文引用的 references/、scripts/ 相对路径存在
#   8. 索引 skill 路由表指向的技能存在
#   9. JSON 文件可被严格解析
#  10. 尺寸约束(索引 ≤4KB,深度 ≤12KB)
#  11. frontmatter 内容质量(name 字符集/description what+when,CRITICAL 拦截)
#  12. 深度 skill test-cases 覆盖(软提示,不拦截)
#  13. 高优 skill quality_assertion 覆盖(软提示,不拦截)
#  14. 高优 skill 主动纠错覆盖率(软提示,不拦截)

set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0

section() { echo ""; echo "=== $1 ==="; }
check() { if [ "$1" -eq 0 ]; then PASS=$((PASS+1)); echo "  OK: $2"; else FAIL=$((FAIL+1)); echo "  FAIL: $2"; fi; }

# 收集所有 skill 名(目录名为准)
declare -A skill_names
while IFS= read -r f; do
  skill_names["$(basename "$(dirname "$f")")"]=1
done < <(find "$ROOT/plugins" -name "SKILL.md" -path "*/skills/*")

# ── 1. 目录名与 frontmatter name 一致 ──
section "1. Skill 目录名与 frontmatter name 一致性"
mismatch=0
while IFS= read -r f; do
  dirname=$(basename "$(dirname "$f")")
  fm_name=$(head -5 "$f" | grep '^name:' | awk '{print $2}')
  if [ "$dirname" != "$fm_name" ]; then check 1 "$dirname != $fm_name"; mismatch=1; fi
done < <(find "$ROOT/plugins" -name "SKILL.md" -path "*/skills/*")
[ "$mismatch" -eq 0 ] && check 0 "全部 ${#skill_names[@]} 个 skill 目录名与 name 一致"

# ── 2. requires 目标存在 ──
section "2. requires 目标存在性"
bad=0
while IFS= read -r f; do
  bname=$(basename "$(dirname "$f")")
  req=$(grep '^requires:' "$f" 2>/dev/null | awk '{print $2}')
  if [ -n "$req" ] && [ -z "${skill_names[$req]:-}" ]; then check 1 "$bname requires '$req' 不存在"; bad=1; fi
done < <(find "$ROOT/plugins" -name "SKILL.md" -path "*/skills/*")
[ "$bad" -eq 0 ] && check 0 "全部 requires 目标有效"

# ── 3. kits 无裸 @(YAML 合法性) ──
section "3. kits 字段 YAML 安全性"
bad=0
while IFS= read -r line; do
  echo "  FAIL: ${line%%:*} 包含未加引号的 @kit 值"; bad=1
done < <(grep -rn 'kits: \[@kit\.' "$ROOT/plugins" --include="*.md" | grep -v '"@' || true)
check $bad "所有 kits 已加引号防护"

# ── 4. evals 引用 skill 存在 ──
section "4. evals.json 引用 skill 存在性"
bad=0
if [ -f "$ROOT/tools/evals/evals.json" ]; then
  while IFS= read -r name; do
    case "$name" in none*|harmony-index) continue;; esac
    if [ -z "${skill_names[$name]:-}" ]; then check 1 "evals 引用未知 skill: $name"; bad=1; fi
  done < <(grep '"skill":' "$ROOT/tools/evals/evals.json" | sed 's/.*"skill": *"\([^"]*\)".*/\1/')
  [ "$bad" -eq 0 ] && check 0 "evals 引用全部有效"
fi

# ── 5. marketplace.json 与目录一致 ──
section "5. marketplace.json 对齐"
mj="$ROOT/.claude-plugin/marketplace.json"
if [ -f "$mj" ]; then
  bad=0
  for src in $(grep -oE '"source": *"\./plugins/[^"]+"' "$mj" | sed 's/.*"\.\///;s/"//'); do
    [ -d "$ROOT/$src" ] || { check 1 "marketplace source 不存在: $src"; bad=1; }
  done
  mj_count=$(grep -c '"source":' "$mj" || echo 0)
  actual_count=$(find "$ROOT/plugins" -maxdepth 1 -name "harmony-*" -type d | wc -l)
  if [ "$mj_count" != "$actual_count" ]; then check 1 "marketplace $mj_count 个插件 vs 实际 $actual_count 个目录"; bad=1; fi
  [ "$bad" -eq 0 ] && check 0 "marketplace.json 与 plugins/ 目录一致($mj_count 个)"
fi

# ── 6. plugin.json skills 清单与目录双向一致 ──
section "6. plugin.json skills 清单一致性"
bad=0
for pj in "$ROOT"/plugins/*/.claude-plugin/plugin.json; do
  pdir="$(dirname "$(dirname "$pj")")"
  pname="$(basename "$pdir")"
  # 清单 → 目录
  for s in $(grep -oE '"skills": *\[[^]]*\]' "$pj" | grep -oE '"[a-z0-9-]+"' | tr -d '"' | grep -v '^skills$'); do
    [ -d "$pdir/skills/$s" ] || { check 1 "$pname/plugin.json 声明的 skill 目录不存在: $s"; bad=1; }
  done
  # 目录 → 清单
  for d in "$pdir"/skills/*/; do
    s="$(basename "$d")"
    grep -q "\"$s\"" "$pj" || { check 1 "$pname/skills/$s 未在 plugin.json 中声明"; bad=1; }
  done
done
[ "$bad" -eq 0 ] && check 0 "全部 plugin.json 清单与目录双向一致"

# ── 7. SKILL.md 引用的相对路径存在 ──
section "7. SKILL.md 引用路径存在性"
bad=0
while IFS= read -r f; do
  sdir="$(dirname "$f")"
  bname="$(basename "$sdir")"
  while IFS= read -r ref; do
    [ -f "$sdir/$ref" ] || { check 1 "$bname 引用的文件不存在: $ref"; bad=1; }
  done < <(grep -oE '\`?(references|scripts)/[A-Za-z0-9_.-]+\`?' "$f" | tr -d '\`' | sort -u)
done < <(find "$ROOT/plugins" -name "SKILL.md" -path "*/skills/*")
[ "$bad" -eq 0 ] && check 0 "全部 SKILL.md 引用路径有效"

# ── 8. 索引路由表目标存在 ──
section "8. 索引 skill 路由表目标存在性"
bad=0
while IFS= read -r f; do
  bname="$(basename "$(dirname "$f")")"
  # 提取正文反引号内的候选 skill 名(全小写连字符、不含点/斜杠/@)
  while IFS= read -r tok; do
    case "$tok" in *.*|*/*|@*) continue;; esac
    echo "$tok" | grep -qE '^(0-)?[a-z][a-z0-9]*(-[a-z0-9]+)+$' || continue
    if [ -z "${skill_names[$tok]:-}" ]; then check 1 "$bname 路由表指向未知技能: $tok"; bad=1; fi
  done < <(sed '1,/^---$/d' "$f" | sed '1,/^---$/d' | grep -oE '\`[^\`]+\`' | tr -d '\`' | sort -u)
done < <(find "$ROOT/plugins" -path "*skills*" -name "SKILL.md" | grep -E '(harmony-index|0-[a-z]+-index)')
[ "$bad" -eq 0 ] && check 0 "全部索引路由表目标有效"

# ── 9. JSON 可解析 ──
section "9. JSON 严格解析"
bad=0
PY=""
for cand in python python3 py; do
  if command -v "$cand" >/dev/null 2>&1 && "$cand" -c "import json" >/dev/null 2>&1; then PY="$cand"; break; fi
done
if [ -n "$PY" ]; then
  for j in "$mj" "$ROOT"/plugins/*/.claude-plugin/plugin.json "$ROOT/tools/evals/evals.json"; do
    "$PY" -c "import json,sys;json.load(open(sys.argv[1],encoding='utf-8'))" "$j" 2>/dev/null \
      || { check 1 "JSON 解析失败: ${j#$ROOT/}"; bad=1; }
  done
  [ "$bad" -eq 0 ] && check 0 "全部 JSON 可严格解析"
else
  echo "  SKIP: 无 python,跳过 JSON 解析检查"
fi

# ── 10. 尺寸约束 ──
section "10. 尺寸约束(索引 ≤4KB,深度 ≤12KB)"
bad=0
while IFS= read -r f; do
  bname="$(basename "$(dirname "$f")")"
  size=$(wc -c < "$f")
  case "$bname" in
    harmony-index|0-*-index) limit=4096;;
    *) limit=12288;;
  esac
  [ "$size" -le "$limit" ] || { check 1 "$bname 超出尺寸约束: ${size}B > ${limit}B"; bad=1; }
done < <(find "$ROOT/plugins" -name "SKILL.md" -path "*/skills/*")
[ "$bad" -eq 0 ] && check 0 "全部 skill 在尺寸约束内"

# ── 11. frontmatter 内容质量审查(CRITICAL 拦截) ──
section "11. frontmatter 内容质量"
if [ -n "$PY" ] && [ -f "$ROOT/tools/validate-frontmatter.py" ]; then
  OUT_FM=$("$PY" "$ROOT/tools/validate-frontmatter.py" "$ROOT/plugins" 2>&1); rc=$?
  if [ "$rc" -eq 0 ]; then check 0 "frontmatter 内容质量无 CRITICAL"; else check 1 "frontmatter 存在 CRITICAL 问题"; fi
  echo "$OUT_FM" | grep -E 'CRITICAL|WARN:' || true
else
  echo "  SKIP: 无 python 或缺 validate-frontmatter.py,跳过内容质量审查"
fi

# ── 12. 深度 skill test-cases 覆盖(软提示,不拦截 FAIL) ──
section "12. 深度 skill test-cases 覆盖(软提示)"
miss=0
while IFS= read -r f; do
  bname="$(basename "$(dirname "$f")")"
  case "$bname" in harmony-index|0-*-index) continue;; esac
  [ -f "$(dirname "$f")/test-cases/test-prompts.md" ] || miss=$((miss+1))
done < <(find "$ROOT/plugins" -name "SKILL.md" -path "*/skills/*")
if [ "$miss" -eq 0 ]; then check 0 "全部深度 skill 均有 test-cases/test-prompts.md"; else echo "  提示: $miss 个深度 skill 暂无 test-cases/test-prompts.md(建议逐步补充,不拦截)"; fi

# ── 13. 高优 skill evals 覆盖软提示（v0.7.0 引入）──
section "13. 8 高优 skill quality_assertion 覆盖（软提示，不拦截）"
declare -A priority_skills=(
  [arkts-syntax]=4 [arkui-patterns]=4 [stage-model]=4
  [security-permissions]=4 [network-requests]=4
  [audio-playback]=4 [media-system]=4 [ai-inference]=4
  [3d-ar]=2
)
for skill in "${!priority_skills[@]}"; do
  target=${priority_skills[$skill]}
  count=$("${PY:-python3}" -c "
import json
d = json.load(open('$ROOT/tools/evals/evals.json'))
print(sum(1 for e in d['evals']
          if e.get('skill') == '$skill'
          and 'quality_assertion' in e))
")
  if [ "$count" -ge "$target" ]; then
    check 0 "$skill: $count / $target quality_assertion"
  else
    check 0 "$skill: $count / $target quality_assertion（建议补足，非阻断）"
  fi
done

# ── 14. 高优 skill 主动纠错覆盖率(软提示,不拦截 FAIL) ──
section "14. 9 高优 skill 主动纠错覆盖率（软提示，不拦截）"
declare -A high_priority_skills=(
  [arkts-syntax]=1 [arkui-patterns]=1 [stage-model]=1
  [security-permissions]=1 [network-requests]=1
  [audio-playback]=1 [media-system]=1 [ai-inference]=1
  [3d-ar]=1
)
CORRECTION_MARKERS="⚠️|纠正|不存在|反模式|误区|禁止"
for skill in "${!high_priority_skills[@]}"; do
  skill_file=$(find "$ROOT/plugins" -name "SKILL.md" -path "*/skills/$skill/*" | head -1)
  if [ -n "$skill_file" ]; then
    matches=$(grep -cE "$CORRECTION_MARKERS" "$skill_file" 2>/dev/null) || matches=0
  else
    matches=0
  fi
  if [ "$matches" -ge 1 ]; then
    check 0 "$skill: $matches 处纠错标记"
  else
    echo "  提示: $skill 暂无主动纠错标记(建议补充⚠️/纠正/反模式段,非阻断)"
  fi
done

echo ""
echo "===== 结果: $PASS PASS / $FAIL FAIL ====="
if [ "$FAIL" -gt 0 ]; then exit 1; fi
