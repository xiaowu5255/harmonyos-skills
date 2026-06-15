#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
为所有 SKILL.md 补充 ## Overview 和 ## When to Use 段。
插入位置: frontmatter 之后、正文第一个 H1 之前。

用法: python3 tools/add-overview-when.py [--dry-run]
"""
import os
import re
import sys

DRY_RUN = "--dry-run" in sys.argv
FORCE = "--force" in sys.argv
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PLUGINS = os.path.join(ROOT, "plugins")

# ── 工具函数 ──

def split_frontmatter(text):
    """返回 (fm_lines, body_start_idx)。fm_lines 不含 --- 行。"""
    lines = text.split("\n")
    if not lines or lines[0].strip() != "---":
        return None, 0
    for i in range(1, len(lines)):
        if lines[i].strip() == "---":
            return lines[1:i], i + 1
    return None, 0


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


def has_section(body, section_name):
    """检查正文是否已有该 section（## 开头）。"""
    pattern = re.compile(r"^## " + re.escape(section_name), re.MULTILINE)
    return bool(pattern.search(body))


# ── 索引 skill 的领域描述 ──

INDEX_DOMAINS = {
    "harmony-index": {
        "overview": "鸿蒙全栈开发总索引，覆盖应用框架、系统能力、媒体、图形、应用服务、AI、发布运维七大领域。根据任务描述自动路由到对应子索引。",
        "when": "- 用户提及任意 HarmonyOS/鸿蒙/ArkTS/ArkUI/元服务/Native/端云开发相关任务时\n- 需要确定该任务属于哪个技术领域时\n- 作为所有鸿蒙技能的入口路由"
    },
    "0-core-index": {
        "overview": "鸿蒙应用框架领域索引，覆盖 ArkTS 语法、状态管理、ArkUI 布局/导航/动画/窗口、Stage 模型、ArkWeb、元服务卡片、多设备适配、Hvigor 构建、工程调试。",
        "when": "- 涉及 ArkTS 语法、装饰器、编译器报错\n- ArkUI 布局、组件、动画开发\n- Stage 模型生命周期、Ability 配置\n- ArkWeb WebView、元服务卡片\n- 多设备适配、Hvigor 构建、工程调试"
    },
    "0-system-index": {
        "overview": "鸿蒙系统能力领域索引，覆盖后台任务、权限安全、网络/通信、数据存储、文件管理、加密/认证、分布式、Native NDK、传感器/设备。",
        "when": "- 涉及后台任务、权限管理、网络安全\n- 数据存储、文件系统操作\n- 加密解密、分布式能力\n- Native NDK 开发、传感器/设备接口"
    },
    "0-media-index": {
        "overview": "鸿蒙媒体能力领域索引，覆盖音频播放/录制/MIDI、相机拍照/录像、音视频编解码、图片处理、媒体库、DRM、AVSession 播控、扫码。",
        "when": "- 涉及音频播放/录制、MIDI 外设\n- 相机拍照/录像、Camera Kit\n- 音视频编解码、图片处理\n- 媒体库、DRM 版权保护\n- AVSession 播控、扫码功能"
    },
    "0-graphics-index": {
        "overview": "鸿蒙图形能力领域索引，覆盖 2D 绘制、3D 渲染、AR 增强现实、图形加速、空间感知。",
        "when": "- 涉及 Canvas 2D 绘制、路径/渐变\n- 3D 渲染、ETS 场景\n- AR 增强现实、空间感知\n- 图形加速、GPU 相关优化"
    },
    "0-ecosystem-index": {
        "overview": "鸿蒙应用服务领域索引，覆盖华为账号登录、消息推送、应用内支付、通知系统、定位地图、端云一体化、分享/联系人/日历/DeepLink。",
        "when": "- 涉及华为账号登录、推送服务\n- 应用内支付、IAP\n- 通知系统、定位地图\n- 端云一体化、AGC 云函数\n- 分享、联系人、日历、DeepLink"
    },
    "0-ai-index": {
        "overview": "鸿蒙 AI 能力领域索引，覆盖视觉 AI (OCR/检测)、语音 AI (识别/合成)、NLP、端侧推理 (MindSpore/CANN/NNRt)、意图框架。",
        "when": "- 涉及 OCR 文字识别、图像检测\n- 语音识别 (ASR)、语音合成 (TTS)\n- NLP 自然语言处理\n- 端侧推理、MindSpore/CANN/NNRt\n- 意图框架、智能推荐"
    },
    "0-release-index": {
        "overview": "鸿蒙发布与运维领域索引，覆盖性能优化 (Profiler/冷启动/内存)、QA 测试 (Hypium/UiTest/稳定性/云测)、应用签名、上架合规。",
        "when": "- 涉及性能优化、Profiler 分析\n- QA 测试、Hypium/UiTest\n- 应用签名、证书管理\n- 上架合规、隐私政策"
    },
}

# ── 深度 skill 的 When to Use 模板 ──

def generate_when_from_desc(name, desc):
    """从 description 字段提取触发条件，生成 When to Use 段。"""
    if not desc:
        return f"- 当用户请求与 {name} 相关的开发任务时"

    # 先清理空白
    desc_clean = clean_whitespace(desc)

    # 提取"涉及...时"的模式
    triggers = []

    # 匹配"涉及...时"（到第一个"时"）
    m = re.findall(r"涉及(.+?)时", desc_clean)
    if m:
        for item in m:
            # 分割逗号/顿号/斜杠
            parts = re.split(r"[、,，/／和与及]", item)
            for p in parts:
                p = p.strip()
                # 去掉开头的连接词
                p = re.sub(r"^(?:或将|或者|以及|并且|同时|及)\s*", "", p)
                # 过滤: 长度>=2、不以@开头(装饰器)、不是纯符号
                if len(p) >= 2 and not p.startswith("@") and not re.match(r'^[\W\s]+$', p):
                    triggers.append(f"- 涉及 {p} 时")

    # 匹配"when"英文句式
    m_en = re.findall(r"[Ww]hen\s+(.+?)(?:\.|,|$)", desc_clean)
    if m_en:
        for item in m_en:
            triggers.append(f"- When {item.strip()}")

    if not triggers:
        triggers.append(f"- 当用户请求与 {name} 相关的开发任务时")

    # 去重并限制数量
    seen = set()
    unique = []
    for t in triggers:
        if t not in seen:
            seen.add(t)
            unique.append(t)
    return "\n".join(unique[:8])


def clean_whitespace(text):
    """清理 YAML 块标量带来的多余空白和换行。"""
    # 将换行+空白合并为单个空格
    text = re.sub(r"\s*\n\s*", " ", text)
    # 合并多个空格
    text = re.sub(r"  +", " ", text)
    return text.strip()


def generate_overview_from_desc(name, desc):
    """从 description 字段生成 Overview 段。"""
    if not desc:
        return f"{name} 技能，提供相关 HarmonyOS 开发指导。"

    # 清理空白
    overview = clean_whitespace(desc)

    # 去掉"凡是涉及...务必先使用本技能..."整句(含后续破折号内容)
    overview = re.sub(r"凡是涉及.*?本技能[——\-].*?(?=[。.])", "", overview)
    overview = re.sub(r"凡是涉及.*?本技能.*?[。.]", "", overview)
    overview = re.sub(r"凡是涉及.*?时.*?[。.]", "", overview)
    # 去掉残余"凡是"
    overview = re.sub(r"^[。.]\s*", "", overview)
    # 去掉"涉及...时使用/加载本技能"末尾路由指令
    overview = re.sub(r"涉及.*?时[首先]*使用\s*本技能.*?$", "", overview)
    overview = re.sub(r"涉及.*?时[首先]*加载.*?$", "", overview)
    # 清理双重句号
    overview = re.sub(r"。。+", "。", overview)

    # 去掉开头的 >-
    overview = re.sub(r"^>-\s*", "", overview)

    # 确保以句号结尾
    overview = overview.strip()
    if overview and not overview.endswith(("。", ".", "）", ")")):
        overview += "。"

    return overview if overview else f"{name} 技能，提供相关 HarmonyOS 开发指导。"


# ── 主处理 ──

modified = 0
skipped = 0

for dirpath, _dirs, files in os.walk(PLUGINS):
    if "SKILL.md" not in files or os.sep + "skills" + os.sep not in dirpath + os.sep:
        continue

    skill_name = os.path.basename(dirpath)
    path = os.path.join(dirpath, "SKILL.md")

    with open(path, encoding="utf-8") as fh:
        text = fh.read()

    fm_lines, body_start = split_frontmatter(text)
    if fm_lines is None:
        print(f"  SKIP: {skill_name} — 无 frontmatter")
        skipped += 1
        continue

    name = extract_field(fm_lines, "name") or skill_name
    desc = extract_field(fm_lines, "description") or ""
    provides = extract_field(fm_lines, "provides") or ""

    # 判断是索引还是深度 skill
    is_index = "index" in provides or name.endswith("-index") or name == "harmony-index"

    body = text[body_start:]

    # 如果是 force 模式，先删除已有的 Overview/When to Use 段
    if FORCE:
        body = re.sub(r"\n## Overview\n.*?(?=\n## |\n# )", "\n", body, flags=re.DOTALL)
        body = re.sub(r"\n## When to Use\n.*?(?=\n## |\n# )", "\n", body, flags=re.DOTALL)
        body = re.sub(r"\n{3,}", "\n\n", body)

    # 检查是否已有 Overview / When to Use
    need_overview = FORCE or (not has_section(body, "Overview") and not has_section(body, "概述"))
    need_when = FORCE or (not has_section(body, "When to Use") and not has_section(body, "使用场景") and not has_section(body, "触发场景"))

    if not need_overview and not need_when:
        print(f"  SKIP: {skill_name} — 已有 Overview/When to Use")
        skipped += 1
        continue

    # 生成内容
    if is_index and name in INDEX_DOMAINS:
        overview_text = INDEX_DOMAINS[name]["overview"]
        when_text = INDEX_DOMAINS[name]["when"]
    else:
        overview_text = generate_overview_from_desc(name, desc)
        when_text = generate_when_from_desc(name, desc)

    # 构建插入段
    insert_parts = []
    if need_overview:
        insert_parts.append(f"## Overview\n\n{overview_text}")
    if need_when:
        insert_parts.append(f"## When to Use\n\n{when_text}")

    insert_block = "\n\n".join(insert_parts) + "\n\n"

    # 插入位置: 在 body 的第一个非空行前插入
    # 但要找到第一个 H1 的位置
    h1_match = re.search(r"^# [^\n]+", body, re.MULTILINE)
    if h1_match:
        insert_pos = h1_match.start()
        new_body = body[:insert_pos] + insert_block + body[insert_pos:]
    else:
        # 没有 H1，直接在 body 开头插入
        new_body = insert_block + body

    new_text = text[:body_start] + new_body

    if DRY_RUN:
        print(f"  DRY-RUN: {skill_name} — would add {'Overview' if need_overview else ''}{'+' if need_overview and need_when else ''}{'When to Use' if need_when else ''}")
    else:
        with open(path, "w", encoding="utf-8") as fh:
            fh.write(new_text)
        print(f"  DONE: {skill_name} — added {'Overview' if need_overview else ''}{' + ' if need_overview and need_when else ''}{'When to Use' if need_when else ''}")

    modified += 1

print(f"\n===== 完成: {modified} 修改 / {skipped} 跳过 =====")
