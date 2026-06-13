/**
 * 示例：Navigation 多页应用
 * 对应 skill: arkui-patterns / stage-model
 * 
 * 展示 NavPathStack 路由管理、页面间参数传递
 * 编译目标：HarmonyOS 6.x / API 20-24
 */
import { promptAction } from '@kit.ArkUI';

// --- 路由工具类 ---
class NavRouter {
  static pathStack: NavPathStack = new NavPathStack();

  static push(dest: string, params?: object): void {
    NavRouter.pathStack.pushPathByName(dest, params);
  }

  static pop(): void {
    NavRouter.pathStack.pop();
  }
}

// --- 详情页数据模型 ---
class ItemData {
  id: number;
  title: string;
  content: string;

  constructor(id: number, title: string, content: string) {
    this.id = id;
    this.title = title;
    this.content = content;
  }
}

// --- 主页 ---
@Entry
@Component
struct MainPage {
  @State items: ItemData[] = [
    new ItemData(1, 'ArkTS 硬约束', '禁止 any/unknown、强制属性初始化...'),
    new ItemData(2, '状态管理 V1 vs V2', '@State/@Prop 到 @ObservedV2/@Trace 的演进'),
    new ItemData(3, 'TaskPool 并发', 'Sendable 约束、任务超时 3 分钟硬限制'),
  ];

  build() {
    Navigation(NavRouter.pathStack) {
      Column() {
        // 标题
        Text('HarmonyOS 知识速查')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .padding({ top: 16, bottom: 8, left: 16, right: 16 })

        // 知识列表
        List() {
          ForEach(this.items, (item: ItemData) => {
            ListItem() {
              Row() {
                Column() {
                  Text(item.title)
                    .fontSize(18)
                    .fontWeight(FontWeight.Medium)
                  Text(item.content)
                    .fontSize(14)
                    .fontColor(Color.Gray)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                Image($r('app.media.ic_public_arrow_right'))
                  .width(24)
                  .height(24)
              }
              .width('100%')
              .padding(16)
              .onClick(() => {
                NavRouter.push('DetailPage', { item: item });
              })
            }
          }, (item: ItemData) => item.id.toString())
        }
        .layoutWeight(1)
        .width('100%')
      }
      .width('100%')
      .height('100%')
    }
    .title('知识速查')
    .mode(NavigationMode.Stack)
    .navDestination(this.detailPageBuilder)
  }

  // 详情页构建器（NavDestination）
  @Builder
  detailPageBuilder(name: string, param: Object) {
    if (name === 'DetailPage') {
      DetailPage({ item: (param as Record<string, ItemData>)['item'] })
    }
  }
}

// --- 详情页 ---
@Component
struct DetailPage {
  @State item: ItemData = new ItemData(0, '', '');

  build() {
    NavDestination() {
      Scroll() {
        Column() {
          Text(this.item.title)
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .padding({ top: 20, bottom: 12 })

          Text(this.item.content)
            .fontSize(16)
            .lineHeight(24)
            .padding({ bottom: 20 })

          Button('返回')
            .onClick(() => NavRouter.pop())
        }
        .padding(20)
        .width('100%')
      }
    }
    .title(this.item.title)
  }
}
