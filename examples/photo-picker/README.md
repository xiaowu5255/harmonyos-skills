# 示例：PhotoViewPicker 免权限选图 + 沙箱存储

展示 skill: **security-permissions** / **file-system**

## 涉及知识点
- PhotoViewPicker 免权限选图
- URI 到沙箱路径转换
- 沙箱文件读写
- Picker 优先决策树（Picker 免权限 > 安全控件 > 动态申请）

## 文件说明
- `entry/src/main/ets/pages/PhotoPage.ets` — 选图与存储页面
