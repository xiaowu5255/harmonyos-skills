#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Hermes 适配层：扫描 SKILL.md 的 provides: index 元字段，
生成 Hermes 平台可消费的路由注册表。

用法:
  python3 tools/hermes-migrate.py                     # 输出 JSON 到 stdout
  python3 tools/hermes-migrate.py --format yaml       # 输出 YAML
  python3 tools/hermes-migrate.py --out hermes-registry.json  # 写入文件

原理:
  - 扫描所有 SKILL.md 的 frontmatter
  - 识别 provides: index 的索引 skill → 注册为 router
  - 识别 requires 字段的深度 skill → 注册为 skill
  - 输出 Hermes 兼容的注册表格式
"""
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PLUGINS = os.path.join(ROOT, "plugins")


def split_frontmatter(text):
    lines = text.split("\n")
    if not lines or lines[0].strip() != "---":
        return None
    for i in range(1, len(lines)):
        if lines[i].strip() == "---":
            return lines[1:i]
    return None


def extract_field(fm_lines, key):
    key_re = re.compile(r"^([A-Za-z_][A-Za-z0-9_-]*):(.*)$")
    for idx, line in enumerate(fm_lines):
        m = key_re.match(line)
        if not m or m.group(1) != key:
            continue
        inline = m.group(2).strip()
        if inline and inline not in (">-", ">", "|", "|-", ">+"):
            return inline.strip().strip('"').strip("'")
        buf = []
        for nxt in fm_lines[idx + 1:]:
            if key_re.match(nxt) and not nxt.startswith((" ", "\t")):
                break
            if nxt.strip() == "":
                continue
            buf.append(nxt.strip())
        return " ".join(buf).strip().strip('"').strip("'")
    return None


routers = []
skills = []

for dirpath, _dirs, files in os.walk(PLUGINS):
    if "SKILL.md" not in files or os.sep + "skills" + os.sep not in dirpath + os.sep:
        continue

    skill_name = os.path.basename(dirpath)
    path = os.path.join(dirpath, "SKILL.md")

    with open(path, encoding="utf-8") as fh:
        text = fh.read()

    fm = split_frontmatter(text)
    if fm is None:
        continue

    name = extract_field(fm, "name") or skill_name
    desc = extract_field(fm, "description") or ""
    provides = extract_field(fm, "provides") or ""
    requires = extract_field(fm, "requires") or ""

    if "index" in provides:
        routers.append({
            "name": name,
            "description": desc,
            "type": "router",
            "requires": requires or None,
            "file": os.path.relpath(path, ROOT),
        })
    else:
        skills.append({
            "name": name,
            "description": desc,
            "type": "skill",
            "requires": requires or None,
            "file": os.path.relpath(path, ROOT),
        })

registry = {
    "version": "1.0",
    "source": "harmonyos-skills",
    "total_routers": len(routers),
    "total_skills": len(skills),
    "routers": sorted(routers, key=lambda x: x["name"]),
    "skills": sorted(skills, key=lambda x: x["name"]),
}

# 解析命令行参数
fmt = "json"
out = None
args = sys.argv[1:]
for i, arg in enumerate(args):
    if arg == "--format" and i + 1 < len(args):
        fmt = args[i + 1]
    elif arg == "--out" and i + 1 < len(args):
        out = args[i + 1]

if fmt == "yaml":
    # 简易 YAML 输出(不依赖 PyYAML)
    lines = ["version: '1.0'", f"source: harmonyos-skills", f"total_routers: {len(routers)}", f"total_skills: {len(skills)}", "", "routers:"]
    for r in sorted(routers, key=lambda x: x["name"]):
        lines.append(f"  - name: {r['name']}")
        lines.append(f"    description: \"{r['description'][:80]}...\"" if len(r['description']) > 80 else f"    description: \"{r['description']}\"")
        lines.append(f"    type: router")
        if r["requires"]:
            lines.append(f"    requires: {r['requires']}")
        lines.append(f"    file: {r['file']}")
    lines.append("")
    lines.append("skills:")
    for s in sorted(skills, key=lambda x: x["name"]):
        lines.append(f"  - name: {s['name']}")
        lines.append(f"    description: \"{s['description'][:80]}...\"" if len(s['description']) > 80 else f"    description: \"{s['description']}\"")
        lines.append(f"    type: skill")
        if s["requires"]:
            lines.append(f"    requires: {s['requires']}")
        lines.append(f"    file: {s['file']}")
    output = "\n".join(lines) + "\n"
else:
    output = json.dumps(registry, ensure_ascii=False, indent=2) + "\n"

if out:
    with open(out, "w", encoding="utf-8") as fh:
        fh.write(output)
    print(f"写入 {out}: {len(routers)} routers, {len(skills)} skills")
else:
    print(output)
