#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Skill frontmatter 内容质量审查(借鉴 harmonyos-agent-skills 的 .hmos-skill-reviewer 思路,
但只保留与本仓库约定一致的硬规则,风格问题降级为 WARN,不破坏现有 skill)。

判定分级:
  CRITICAL(返回码 1)—— name 字符集非法 / description 缺失 / description > 1024 字符 /
                        frontmatter 结构缺失。
  WARNING(不影响返回码)—— description 过短(<40)/ 缺 what+when 信号 / name 含版本号 /
                          正文非恰好一个 H1。

用法: python tools/validate-frontmatter.py [plugins_dir]
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PLUGINS = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "plugins")

NAME_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
VERSION_SUFFIX_RE = re.compile(r"-v?\d+$")
# what+when 信号:中文触发词或英文 use-when 句式
WHEN_SIGNAL_RE = re.compile(r"涉及|触发|当.*?时|使用本|时使用|时加载|时优先|use when|when ", re.IGNORECASE)

crit = 0
warn = 0
checked = 0


def split_frontmatter(text):
    if not text.startswith("---"):
        return None, text
    parts = text.split("\n")
    if parts[0].strip() != "---":
        return None, text
    for i in range(1, len(parts)):
        if parts[i].strip() == "---":
            return parts[1:i], "\n".join(parts[i + 1:])
    return None, text


def extract_field(fm_lines, key):
    """返回 (raw_value_string)。支持单行 / 块标量(>- | >)/ 引号。"""
    key_re = re.compile(r"^([A-Za-z_][A-Za-z0-9_-]*):(.*)$")
    for idx, line in enumerate(fm_lines):
        m = key_re.match(line)
        if not m or m.group(1) != key:
            continue
        inline = m.group(2).strip()
        if inline and inline not in (">-", ">", "|", "|-", ">+"):
            return inline.strip().strip('"').strip("'")
        # 块标量:收集后续缩进行,直到下一个列 0 的 key 或结束
        buf = []
        for nxt in fm_lines[idx + 1:]:
            if key_re.match(nxt) and not nxt.startswith((" ", "\t")):
                break
            if nxt.strip() == "":
                continue
            buf.append(nxt.strip())
        return " ".join(buf).strip().strip('"').strip("'")
    return None


def report(level, skill, msg):
    global crit, warn
    if level == "CRIT":
        crit += 1
        print("  CRITICAL: [%s] %s" % (skill, msg))
    else:
        warn += 1
        print("  WARN:     [%s] %s" % (skill, msg))


for dirpath, _dirs, files in os.walk(PLUGINS):
    if "SKILL.md" not in files or os.sep + "skills" + os.sep not in dirpath + os.sep:
        continue
    skill = os.path.basename(dirpath)
    path = os.path.join(dirpath, "SKILL.md")
    with open(path, encoding="utf-8") as fh:
        text = fh.read()
    checked += 1

    fm, body = split_frontmatter(text)
    if fm is None:
        report("CRIT", skill, "缺少 YAML frontmatter(--- 包裹)")
        continue

    name = extract_field(fm, "name")
    desc = extract_field(fm, "description")

    # name 审查
    if not name:
        report("CRIT", skill, "frontmatter 缺少 name 字段")
    else:
        if not NAME_RE.match(name):
            report("CRIT", skill, "name 非法(仅小写字母/数字/连字符,不可首尾或连续连字符): '%s'" % name)
        if len(name) > 64:
            report("CRIT", skill, "name 超过 64 字符: '%s'" % name)
        if name != skill:
            report("CRIT", skill, "name '%s' 与目录名不一致" % name)
        if VERSION_SUFFIX_RE.search(name):
            report("WARN", skill, "name 含版本号后缀,建议去掉: '%s'" % name)

    # description 审查
    if not desc:
        report("CRIT", skill, "frontmatter 缺少 description 字段")
    else:
        n = len(desc)
        if n > 1024:
            report("CRIT", skill, "description 超过 1024 字符(%d),需精简" % n)
        elif n < 40:
            report("WARN", skill, "description 过短(%d 字符),建议补充 what+when" % n)
        if not WHEN_SIGNAL_RE.search(desc):
            report("WARN", skill, "description 缺少触发场景(when)信号,建议加'涉及…时使用'之类")

    # 正文 H1 数量
    h1 = len(re.findall(r"^# [^\n]+", body, re.MULTILINE))
    if h1 != 1:
        report("WARN", skill, "正文应恰好一个 H1 标题,实际 %d 个" % h1)

print("")
print("===== frontmatter 审查: %d skill / %d CRITICAL / %d WARNING =====" % (checked, crit, warn))
sys.exit(1 if crit > 0 else 0)
