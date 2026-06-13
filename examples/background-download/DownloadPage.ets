/**
 * 示例：后台长时任务下载
 * 对应 skill: background-tasks
 * 
 * 展示 backgroundTaskManager.startBackgroundRunning 与长时任务类型选型
 * "后台默认死"原则：切后台必须申请长时任务，否则下载被系统挂起
 * 编译目标：HarmonyOS 6.x / API 20-24
 */
import { backgroundTaskManager } from '@kit.BackgroundTasksKit';
import { request } from '@kit.BasicServicesKit';
import { promptAction } from '@kit.ArkUI';

@Entry
@Component
struct DownloadPage {
  @State downloadProgress: number = 0;
  @State isDownloading: boolean = false;
  @State statusText: string = '等待开始';
  private bgTaskId: number = -1;

  async startDownload(): Promise<void> {
    this.isDownloading = true;
    this.statusText = '正在申请长时任务...';

    try {
      // 1. 申请长时任务（"后台默认死"——不申请后台即被挂起）
      const continuousTaskInfo = await backgroundTaskManager.startBackgroundRunning(
        this.getUIContext(),
        backgroundTaskManager.BackgroundMode.DATA_TRANSFER,
        { // WantAgent 参数
          action: 'ohos.want.action.HOME',
          parameters: {},
        }
      );
      this.bgTaskId = continuousTaskInfo.taskId;
      this.statusText = '长时任务已申请，下载中...';

      // 2. 模拟下载进度（实际场景使用 @ohos.request 模块）
      const totalSteps = 10;
      for (let i = 0; i <= totalSteps; i++) {
        if (!this.isDownloading) {
          this.statusText = '下载已取消';
          await this.stopBackgroundTask();
          return;
        }
        await this.sleep(500);
        this.downloadProgress = Math.round((i / totalSteps) * 100);
        this.statusText = `下载中 ${this.downloadProgress}%`;
      }

      this.statusText = '下载完成！';
      await promptAction.showToast({ message: '下载完成' });
    } catch (err) {
      this.statusText = `下载失败: ${JSON.stringify(err)}`;
    } finally {
      await this.stopBackgroundTask();
      this.isDownloading = false;
    }
  }

  async cancelDownload(): Promise<void> {
    this.isDownloading = false;
    this.downloadProgress = 0;
    this.statusText = '已取消';
    await this.stopBackgroundTask();
  }

  private async stopBackgroundTask(): Promise<void> {
    if (this.bgTaskId !== -1) {
      try {
        await backgroundTaskManager.stopBackgroundRunning(this.getUIContext());
      } catch (e) {
        // 任务可能已自动结束
      }
      this.bgTaskId = -1;
    }
  }

  private sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  build() {
    Column() {
      Text('后台下载示例')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 40, bottom: 20 })

      // 进度环
      Stack() {
        Progress({
          value: this.downloadProgress,
          total: 100,
          type: ProgressType.Ring
        })
          .width(120)
          .height(120)
          .style({ strokeWidth: 8 })

        Text(`${this.downloadProgress}%`)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
      }
      .margin({ bottom: 20 })

      Text(this.statusText)
        .fontSize(14)
        .fontColor(Color.Gray)
        .margin({ bottom: 32 })

      // 控制按钮
      if (!this.isDownloading) {
        Button('开始下载')
          .width('60%')
          .onClick(() => this.startDownload())
      } else {
        Button('取消下载')
          .width('60%')
          .backgroundColor('#FF4444')
          .onClick(() => this.cancelDownload())
      }

      Blank()

      // 说明文字
      Text('提示：切到后台下载仍然继续（已申请长时任务）\nAPI 21+ 同一 UIAbility 最多同时 10 个长时任务')
        .fontSize(12)
        .fontColor('#999')
        .textAlign(TextAlign.Center)
        .padding(20)
    }
    .width('100%')
    .height('100%')
    .padding(20)
  }
}
