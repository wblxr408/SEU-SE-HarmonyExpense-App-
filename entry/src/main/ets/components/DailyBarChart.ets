import { DailyChartData} from '../model/ChartData'

@Component
export struct DailyBarChart {
  @Prop dataList: DailyChartData[]; // 接收处理好的数据
  @Prop maxAmount: number; // 当前数据的最大值

  build() {
    Column() {
      // 柱状图区域
      Row({ space: 4 }) {
        ForEach(this.dataList, (item: DailyChartData) => {
          Column() {
            //  柱子
            // 这里的 100 是基础高度，根据比例缩放
            Column()
              .width('100%')
              .height(`${(item.amount / (this.maxAmount || 1)) * 100}%`)
              .backgroundColor(item.isHighest ? '#2E8BFF' : '#4D4D4D') // 最高亮色，其他深灰色
              .borderRadius({ topLeft: 2, topRight: 2 })

          }
          .height('100%') // 容器占满高度
          .width(8) // 柱子宽度
          .justifyContent(FlexAlign.End) // 底部对齐
          .onClick(() => {
            // TODO: 点击柱子显示具体金额的交互
            console.info(`Clicked day ${item.day}: ${item.amount}`);
          })
        })
      }
      .width('100%')
      .height(100) // 图表固定高度
      .alignItems(VerticalAlign.Bottom) // 底部对齐

      //底部日期轴
    }
    .padding(10)
    .backgroundColor('#1C1C1E') // 深色背景
    .borderRadius(12)
  }
}