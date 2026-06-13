# 示例：音频播放 + 锁屏播控

展示 skill: **audio-playback** / **media-system**

## 涉及知识点
- Audio Kit：AudioRenderer 播放、StreamUsage 选型
- AVSession：播控中心/锁屏显示
- AudioConcurrencyMode：音频焦点管理
- 设备路由监听（蓝牙耳机插拔）

## 文件说明
- `entry/src/main/ets/pages/PlayerPage.ets` — 播放器页面（含焦点管理 + AVSession 注册）
- `entry/src/main/ets/services/AudioPlayerService.ets` — 音频播放服务封装
