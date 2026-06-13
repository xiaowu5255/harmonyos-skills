#!/usr/bin/env bash
# 校验 doc-anchors.md 中登记的官方文档 URL 是否仍可访问(HTTP 200)。
# 用法: bash check-doc-urls.sh [path/to/doc-anchors.md]
# 退出码: 有任意 URL 非 200 时返回 1(便于 CI / weekly-sdk-watch 拦截失效链接)。
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ANCHORS="${1:-$HERE/../references/doc-anchors.md}"

if [ ! -f "$ANCHORS" ]; then
  echo "FAIL: 找不到锚点表: $ANCHORS"
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "SKIP: 未找到 curl,跳过 URL 校验"
  exit 0
fi

# 提取所有 developer.huawei.com 文档 URL(去重)
mapfile -t urls < <(grep -oE 'https://developer\.huawei\.com/consumer/cn/doc/[A-Za-z0-9._/-]+' "$ANCHORS" | sort -u)

if [ "${#urls[@]}" -eq 0 ]; then
  echo "WARN: 锚点表中未发现可校验 URL"
  exit 0
fi

fail=0
for u in "${urls[@]}"; do
  code=$(curl -s -o /dev/null -w '%{http_code}' -A 'Mozilla/5.0' --max-time 25 "$u" || echo "000")
  if [ "$code" = "200" ]; then
    echo "  OK  ($code)  $u"
  else
    echo "  BAD ($code)  $u"
    fail=1
  fi
done

if [ "$fail" -ne 0 ]; then
  echo "===== 存在失效或非 200 的文档 URL,请更新锚点表 ====="
  exit 1
fi
echo "===== 全部文档 URL 可访问 ====="
