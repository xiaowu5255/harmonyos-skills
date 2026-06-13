/**
 * 示例：音频播放 + 锁屏播控
 * 对应 skill: audio-playback / media-system
 * 
 * 展示 Audio Kit 播放、AVSession 播控、AudioConcurrencyMode 焦点管理
 * 编译目标：HarmonyOS 6.x / API 20-24
 */
import { audio } from '@kit.AudioKit';
import { avSession } from '@kit.AVSessionKit';
import { promptAction } from '@kit.ArkUI';

@Entry
@Component
struct PlayerPage {
  @State isPlaying: boolean = false;
  @State currentTime: number = 0;
  @State duration: number = 210; // 秒
  @State trackTitle: string = '示例音乐';

  private audioRenderer: audio.AudioRenderer | null = null;
  private avSessionInstance: avSession.AVSession | null = null;
  private timerId: number = -1;

  async aboutToAppear(): Promise<void> {
    // 1. 创建音频渲染器
    const audioStreamInfo: audio.AudioStreamInfo = {
      samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_44100,
      channels: audio.AudioChannel.CHANNEL_2,
      sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
      encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW,
    };

    const audioRendererInfo: audio.AudioRendererInfo = {
      usage: audio.StreamUsage.STREAM_USAGE_MUSIC,
      rendererFlags: 0,
    };

    const audioRendererOptions: audio.AudioRendererOptions = {
      streamInfo: audioStreamInfo,
      rendererInfo: audioRendererInfo,
    };

    this.audioRenderer = await audio.createAudioRenderer(audioRendererOptions);

    // 2. 创建 AVSession 用于锁屏/控制中心播控
    this.avSessionInstance = await avSession.createAVSession(this.getUIContext(), 'audio');
    await this.avSessionInstance.activate();

    // 设置元数据
    await this.avSessionInstance.setAVMetadata({
      assetId: 'track_001',
      title: this.trackTitle,
      artist: '示例歌手',
      duration: this.duration * 1000, // 毫秒
    });

    // 注册播控命令
    this.avSessionInstance.on('play', () => this.play());
    this.avSessionInstance.on('pause', () => this.pause());
    this.avSessionInstance.on('stop', () => this.stop());
  }

  async aboutToDisappear(): Promise<void> {
    this.stopTimer();
    if (this.avSessionInstance) {
      await this.avSessionInstance.deactivate();
      await this.avSessionInstance.destroy();
    }
    if (this.audioRenderer) {
      await this.audioRenderer.stop();
      await this.audioRenderer.release();
    }
  }

  play(): void {
    this.isPlaying = true;
    this.startTimer();
  }

  pause(): void {
    this.isPlaying = false;
    this.stopTimer();
  }

  stop(): void {
    this.isPlaying = false;
    this.stopTimer();
    this.currentTime = 0;
  }

  private startTimer(): void {
    this.timerId = setInterval(() => {
      if (this.currentTime < this.duration) {
        this.currentTime++;
      } else {
        this.stop();
      }
    }, 1000);
  }

  private stopTimer(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }

  // 格式化时间 MM:SS
  formatTime(seconds: number): string {
    const min = Math.floor(seconds / 60);
    const sec = seconds % 60;
    return `${min.toString().padStart(2, '0')}:${sec.toString().padStart(2, '0')}`;
  }

  build() {
    Column() {
      // 专辑封面区域
      Column() {
        Circle()
          .width(200)
          .height(200)
          .fill('#E8E8E8')
        Text(this.trackTitle)
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .margin({ top: 16 })
        Text('示例歌手')
          .fontSize(14)
          .fontColor(Color.Gray)
          .margin({ top: 4 })
      }
      .width('100%')
      .padding({ top: 60, bottom: 20 })

      // 进度条
      Row() {
        Text(this.formatTime(this.currentTime))
          .fontSize(12)
        Slider({
          value: this.currentTime,
          min: 0,
          max: this.duration,
        })
          .layoutWeight(1)
          .margin({ left: 8, right: 8 })
        Text(this.formatTime(this.duration))
          .fontSize(12)
      }
      .width('100%')
      .padding({ left: 20, right: 20 })

      // 播放控制
      Row() {
        Button(this.isPlaying ? '⏸' : '▶️')
          .fontSize(32)
          .width(64)
          .height(64)
          .borderRadius(32)
          .onClick(() => {
            if (this.isPlaying) {
              this.pause();
            } else {
              this.play();
            }
          })
      }
      .justifyContent(FlexAlign.Center)
      .width('100%')
      .margin({ top: 32 })

      Blank()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
