#!/bin/bash
# ============================================================
# harmony-test-plan — 测试计划大纲生成
# 独立脚本版本：输出 QA 检查清单骨架
# 深度定制化计划需 engineering 上下文，由 AI Agent 辅助
# ============================================================
set -euo pipefail

echo "=========================================="
echo "  HarmonyOS 测试计划大纲"
echo "  基于 testing-harmony 技能 QA 全景图"
echo "=========================================="

ROOT_DIR="${1:-$(pwd)}"

echo ""
echo "--- 测试维度与工具 ---"
echo ""

cat <<EOF
| 维度 | 工具 | 自动化 | 阶段 |
|------|------|--------|------|
| 单元测试 | Hypium | 是 | 每次提交 |
| UI 测试 | UiTest (onClick/onTouch/滑动) | 是 | PR |
| 兼容性测试 | 云测 (多设备/多API) | 是 | 发布前 |
| 性能测试 | Profiler (Launch/Frame/Memory) | 部分 | 发布前 |
| 稳定性测试 | Monkey/压力遍历 | 是 | 发布前 |
| 安全测试 | 动态权限/加密/凭证 | 部分 | 发布前 |
| 签名安装 | 签名校验+p7b | 手动 | 发布前 |
| 无障碍 | 屏幕朗读+色彩对比 | 手动 | 发布前 |

--- 发布前检查清单 (裁剪自 qa-checklist.md) ---

[ ] 所有 API 调用在 compatibleSdkVersion 范围内
[ ] 调试证书已切换为发布证书
[ ] 混淆已开启且 release 包核心流程真机实测通过
[ ] 隐私声明齐全、权限用途描述准确
[ ] 冷启动 < 3s (中端设备)
[ ] 长列表滑动不掉帧 (≥55fps)
[ ] 折叠屏展开/折叠切换无崩溃
[ ] 通知授权已处理各种授权状态
[ ] 已完成一轮云测兼容性 (≥5 款设备)

--- 当前工程信息 ---
EOF

# 检查当前工程
if [ -f "$ROOT_DIR/build-profile.json5" ]; then
  echo ""
  echo "检测到鸿蒙工程: $ROOT_DIR"
  
  COMP_SDK=$(grep -oP 'compatibleSdkVersion:\s*\K\d+' "$ROOT_DIR/build-profile.json5" | head -1 || echo "N/A")
  echo "  compatibleSdkVersion: $COMP_SDK"
  
  # 检查是否有卡片
  if [ -f "$ROOT_DIR/entry/src/main/module.json5" ]; then
    if grep -q 'FormExtensionAbility\|form' "$ROOT_DIR/entry/src/main/module.json5" 2>/dev/null; then
      echo "  [专项] 含卡片功能 → 需补服务卡片专项测试"
    fi
  fi
  
  # 权限分析
  PERM_COUNT=$(grep -c 'ohos.permission' "$ROOT_DIR/entry/src/main/module.json5" 2>/dev/null || echo 0)
  echo "  权限数: $PERM_COUNT → 每个权限需测试授权/拒绝/永久拒绝态"
  
  # 检查是否有测试目录
  if [ -d "$ROOT_DIR/ohosTest" ]; then
    echo "  ohosTest/ 已存在 → 检查测试覆盖率"
  else
    echo "  [建议] 创建 ohosTest/ 目录添加自动化测试"
  fi
fi

echo ""
echo "下一步："
echo "  填上具体设备形态、端云工程标识、发布时间后→ AI Agent 定制化输出完整计划"
