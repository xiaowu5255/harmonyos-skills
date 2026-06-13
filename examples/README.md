# HarmonyOS Skills — 示例项目

> 每个示例对应一个典型场景，展示对应 skill 的核心模式。
> 这些是活体 evals——如果 skill 正确，这里的代码应该能在 DevEco Studio 中编译运行。

## 示例列表

| # | 示例 | 对应 Skill | 场景 |
|---|------|-----------|------|
| 1 | `navigation-app` | arkui-patterns / stage-model | Navigation 多页应用 + UIAbility 生命周期 |
| 2 | `cloud-function` | cloud-foundation | 端云一体化：云函数调用 + 云数据库 |
| 3 | `media-player` | audio-playback / media-system | 音频播放 + 锁屏播控 |
| 4 | `service-card` | atomic-services-and-cards | 元服务卡片：FormExtensionAbility + 刷新 |
| 5 | `ble-scanner` | connectivity | BLE 蓝牙设备扫描与连接 |
| 6 | `background-download` | background-tasks | 后台长时任务下载 |
| 7 | `multi-device-layout` | multi-device-adaptation | 折叠屏/平板响应式布局 |
| 8 | `photo-picker` | security-permissions / file-system | PhotoViewPicker 免权限选图 + 沙箱存储 |

## 使用方式

1. 用 DevEco Studio 创建新工程（选择对应模板）
2. 将示例目录下的文件复制到对应位置
3. 根据需要调整 `bundleName`、签名配置
4. 编译运行

## 注意事项

- 示例代码以 HarmonyOS 6.x / API 20-24 为目标
- 元服务示例需用 Atomic Service 模板
- 端云一体化示例需先在 AGC 创建项目并关联
- 蓝牙示例需真机测试
