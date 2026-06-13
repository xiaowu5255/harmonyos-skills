# 示例：后台长时任务下载

展示 skill: **background-tasks**

## 涉及知识点
- 长时任务申请（backgroundTaskManager.startBackgroundRunning）
- 任务类型选型（DATA_TRANSFER vs AUDIO_PLAYBACK）
- "后台默认死"原则
- API 21+ 同一 UIAbility 最多 10 个长时任务

## 文件说明
- `entry/src/main/ets/pages/DownloadPage.ets` — 下载页面（含长时任务申请）
