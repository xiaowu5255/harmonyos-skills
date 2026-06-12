#!/usr/bin/env python3
"""diff_api.py — 对比两个鸿蒙 SDK 的 ArkTS 接口声明,生成 API 变更清单。

用法:
    python3 diff_api.py <旧SDK的ets/api目录> <新SDK的ets/api目录> [-o api-changes.md]

原理:扫描 .d.ts/.d.ets 文件,提取顶层/成员声明(function/class/interface/
enum/const/方法签名)及其前导注释中的 @since/@deprecated 标注,按
"文件相对路径 + 声明名"做键值 diff,输出新增/移除/标记废弃/签名变更四类。

这是确定性脚本,不依赖 LLM;输出的 markdown 可直接作为
api-version-migration 技能的 references 数据文件。
"""
import argparse
import os
import re
import sys
from typing import Dict, Tuple

CONTAINER_RE = re.compile(
    r'^\s*(?:export\s+)?(?:declare\s+)?(?:abstract\s+)?'
    r'(class|interface|enum|namespace|type|const|let|function)\s+'
    r'([A-Za-z_][A-Za-z0-9_]*)')
METHOD_RE = re.compile(
    r'^\s*(?:(?:static|readonly|async|public|private|protected)\s+)*'
    r'([A-Za-z_][A-Za-z0-9_]*)\s*\??\s*\(([^)]*)\)\s*:')
SINCE_RE = re.compile(r'@since\s+(\S+)')
DEPRECATED_RE = re.compile(r'@deprecated')


def parse_file(path: str, rel: str, out: Dict[str, Tuple[str, str, bool]]):
    """提取声明 → out[key] = (签名行, since, deprecated)"""
    try:
        with open(path, encoding='utf-8', errors='replace') as f:
            lines = f.readlines()
    except OSError:
        return
    comment_buf = []
    in_comment = False
    container = []  # 粗略容器栈(class/interface 名),给成员方法做命名空间
    for line in lines:
        stripped = line.strip()
        if in_comment:
            comment_buf.append(stripped)
            if '*/' in stripped:
                in_comment = False
            continue
        if stripped.startswith('/**') or stripped.startswith('/*'):
            comment_buf = [stripped]
            in_comment = '*/' not in stripped
            continue
        m = CONTAINER_RE.match(line)
        m2 = None if m else METHOD_RE.match(line)
        if m or m2:
            comment = ' '.join(comment_buf)
            since_m = SINCE_RE.search(comment)
            since = since_m.group(1) if since_m else ''
            deprecated = bool(DEPRECATED_RE.search(comment))
            if m:  # 容器/顶层声明
                kind, name = m.group(1), m.group(2)
                key = f'{rel}::{name}'
                sig = f'{kind} {name}'
                if kind in ('class', 'interface', 'enum', 'namespace'):
                    container = [name]
            else:  # 方法签名
                name = m2.group(1)
                if name in ('if', 'for', 'while', 'switch', 'return', 'catch'):
                    comment_buf = []
                    continue
                params = re.sub(r'\s+', ' ', m2.group(2)).strip()
                ns = container[0] + '.' if container else ''
                key = f'{rel}::{ns}{name}()'
                sig = f'{ns}{name}({params})'
            out[key] = (sig, since, deprecated)
            comment_buf = []
        elif stripped and not stripped.startswith('*'):
            comment_buf = []


def scan(root: str) -> Dict[str, Tuple[str, str, bool]]:
    apis: Dict[str, Tuple[str, str, bool]] = {}
    for dirpath, _, files in os.walk(root):
        for fn in files:
            if fn.endswith(('.d.ts', '.d.ets')):
                p = os.path.join(dirpath, fn)
                parse_file(p, os.path.relpath(p, root), apis)
    return apis


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('old_dir')
    ap.add_argument('new_dir')
    ap.add_argument('-o', '--output', default='api-changes.md')
    args = ap.parse_args()
    for d in (args.old_dir, args.new_dir):
        if not os.path.isdir(d):
            sys.exit(f'目录不存在: {d}')

    old = scan(args.old_dir)
    new = scan(args.new_dir)
    print(f'旧 SDK 声明数: {len(old)},新 SDK 声明数: {len(new)}')

    added = sorted(k for k in new if k not in old)
    removed = sorted(k for k in old if k not in new)
    newly_deprecated = sorted(
        k for k in new if k in old and new[k][2] and not old[k][2])
    sig_changed = sorted(
        k for k in new if k in old and new[k][0] != old[k][0])

    def section(title, keys, src):
        out = [f'\n## {title}({len(keys)})\n']
        for k in keys[:2000]:
            rel, name = k.split('::', 1)
            sig, since, dep = src[k]
            extra = f' `@since {since}`' if since else ''
            extra += ' **deprecated**' if dep else ''
            out.append(f'- `{name}` — {rel}{extra}')
        if len(keys) > 2000:
            out.append(f'- …截断,共 {len(keys)} 条')
        return '\n'.join(out)

    md = ['# SDK API 变更清单\n',
          f'- 旧: `{args.old_dir}`\n- 新: `{args.new_dir}`\n',
          '> 由 tools/sdk-diff/diff_api.py 生成。正则解析为近似结果,',
          '> 用于变更发现与影响面初筛;最终以声明文件原文为准。',
          section('新增 API', added, new),
          section('移除 API(高危,升级前必查工程引用)', removed, old),
          section('新标记 deprecated', newly_deprecated, new),
          section('签名变更(行为可能不同)', sig_changed, new)]
    with open(args.output, 'w', encoding='utf-8') as f:
        f.write('\n'.join(md) + '\n')
    print(f'已写入 {args.output}: +{len(added)} / -{len(removed)} / '
          f'deprecated {len(newly_deprecated)} / changed {len(sig_changed)}')


if __name__ == '__main__':
    main()
