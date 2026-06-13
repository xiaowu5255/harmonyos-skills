# 示例：元服务卡片

展示 skill: **atomic-services-and-cards**

## 涉及知识点
- FormExtensionAbility 生命周期
- 卡片三种刷新通路：定时/条件/消息
- formId 持久化与 formProvider 通信
- 元服务包体约束（≤2MB 分包，≤10MB 总和）

## 文件说明
- `entry/src/main/ets/formability/FormAbility.ets` — 卡片 FormExtensionAbility
- `entry/src/main/ets/widget/pages/WidgetCard.ets` — 卡片 UI 组件
- `entry/src/main/resources/base/profile/form_config.json` — 卡片配置
