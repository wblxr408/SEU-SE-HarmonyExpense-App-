import { DailyChartData } from '../model/ChartData';
import { AppTheme } from '../common/AppTheme';

@Component
export struct DailyBarChart {
  @Prop dataList: DailyChartData[] = [];
  @Prop maxAmount: number = 1;

  // 1. 定义滚动控制器
  private scroller: Scroller = new Scroller();

  build() {
    Column() {
      if (this.dataList.length === 0) {
        Text("等待数据加载...")
          .fontColor(AppTheme.DarkTextMain).fontSize(12).margin(20)
      }

      List({ space: 12, scroller: this.scroller }) { // 2. 绑定控制器
        ForEach(this.dataList, (item: DailyChartData, index: number) => {
          ListItem() {
            Column() {
              // --- 柱子 ---
              Column() {
                Column()
                  .width('100%')
                  .height(`${(item.amount / (this.maxAmount || 1)) * 100}%`)
                  .backgroundColor(item.isHighest ? AppTheme.ChartHighlight : AppTheme.ChartInactive)
                  .borderRadius({ topLeft: 4, topRight: 4 })
                  .constraintSize({ minHeight: 4 }) // 0金额也显示一个小底座
              }
              .width(12)
              .height('80%')
              .justifyContent(FlexAlign.End)

              // --- 日期 ---
              Text(item.day)
                .fontSize(10)
                .fontColor(item.isHighest ? AppTheme.DarkTextMain : AppTheme.DarkTextSub)
                .margin({ top: 6 })
            }
            .height('100%')
            .justifyContent(FlexAlign.End)
          }
        }, (item: DailyChartData) => item.day)
      }
      .listDirection(Axis.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
      .height('100%')
      .alignListItem(ListItemAlign.Start)
      .onAppear(() => {
        // 3. 【关键优化】组件显示时，自动滚动到 "今天" (对应的索引)
        // item.day 是 "01", "02"... 字符串
        setTimeout(() => {
          const today = new Date().getDate();
          const todayStr = today.toString().padStart(2, '0');
          // 找到今天的索引，如果没有，就滚动到最后(兜底)
          const index = this.dataList.findIndex(d => d.day === todayStr);

          if (index >= 0) {
             this.scroller.scrollToIndex(index);
          } else {
             // 如果找不到今天(比如看的是上个月)，可以滚动到有数据的最后一天，或者开头
             // 这里选择滚动到开头，让用户从头看
             this.scroller.scrollToIndex(0);
          }
        }, 100);
      })
    }
    .width('100%')
    .height('100%')
  }
}