// ArkTS 服务卡片页面样板。运行于受限环境:仅能用卡片支持的组件/API 子集,不能 import 任意模块。
// 复杂逻辑放 FormExtensionAbility 或经 postCardAction 拉起的 UIAbility。接口签名以本地 SDK 为准。

// 卡片与卡片提供方共享的数据用 LocalStorageProp 接收(由 onAddForm/onUpdateForm 返回的 formData 注入)
@Entry
@Component
struct WidgetCard {
  // 'title' 对应提供方 updateForm 时 formData 里的字段名
  @LocalStorageProp('title') title: string = '点击刷新';
  @LocalStorageProp('count') count: number = 0;

  build() {
    Column({ space: 8 }) {
      Text(this.title).fontSize(16).fontColor($r('app.color.card_text'))
      Text(`计数:${this.count}`).fontSize(14)

      // message:发消息给 FormExtensionAbility 的 onFormEvent(轻交互,不拉起应用)
      Button('+1')
        .onClick(() => {
          postCardAction(this, {
            action: 'message',
            params: { method: 'increment' }
          });
        })

      // router:拉起 UIAbility 指定页面(处理好任意入口直达)
      Button('打开应用')
        .onClick(() => {
          postCardAction(this, {
            action: 'router',
            abilityName: 'EntryAbility',
            params: { from: 'widget' }
          });
        })
    }
    .width('100%').height('100%').padding(12)
    .justifyContent(FlexAlign.Center)
  }
}
