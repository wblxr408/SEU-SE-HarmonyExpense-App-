import router from '@ohos.router';
import { Bill } from '../model/Bill';
import { BillDAO } from '../dao/BillDAO'; // 确保这里没有 DateRangeFilter 的报错，如果有，直接在代码里定义接口
import { CategoryDAO } from '../dao/CategoryDAO'; // 引入 CategoryDAO
import { Category } from '../model/Category';
import { DailyChartData, MonthSummary, CategoryStat } from '../model/ChartData';
import hilog from '@ohos.hilog';

const LOG_TAG = 'StatisticsPage';
const HILOG_DOMAIN = 0x0001;

@Entry
@Component
struct StatisticsPage {
  @State summary: MonthSummary = new MonthSummary();
  @State chartData: DailyChartData[] = [];
  @State categoryStats: CategoryStat[] = []; // 分类排行数据
  @State billList: Bill[] = [];
  @State maxChartAmount: number = 0;
  @State currentMonth: Date = new Date();
  @State allCategories: Category[] = []; // 缓存分类信息
  @StorageProp('currentUserId') currentUserId: number = 1;

  onPageShow() {
    this.loadData();
  }

  async loadData() {
    // 0. 先加载分类数据，方便后面匹配名字
    if (this.allCategories.length === 0) {
      this.allCategories = await CategoryDAO.getAll(this.currentUserId);
    }

    // 1. 计算当月时间范围
    const year = this.currentMonth.getFullYear();
    const month = this.currentMonth.getMonth() + 1;
    const startStr = `${year}-${month.toString().padStart(2, '0')}-01`;
    const lastDay = new Date(year, month, 0).getDate();
    const endStr = `${year}-${month.toString().padStart(2, '0')}-${lastDay}`;

    // 2. 从 DAO 获取原始数据
    const bills = await BillDAO.getBillsByFilters(this.currentUserId, { start: startStr, end: endStr });
    this.billList = bills;

    // 3. 处理数据
    this.processData(bills, lastDay);
  }

  processData(bills: Bill[], daysInMonth: number) {
    let expenseTotal = 0;
    let incomeTotal = 0;


    const dailyMap = new Map<string, number>();
    for(let i=1; i<=daysInMonth; i++) {
      dailyMap.set(i.toString().padStart(2, '0'), 0);
    }

    // --- B. 分类数据聚合 ---
    const categoryMap = new Map<number, number>(); // categoryId -> amount

    bills.forEach(bill => {
      if (bill.type === 'expense') {
        expenseTotal += bill.amount;

        const dateParts = bill.transactionDate.split('-');
        // 取最后一部分，并补零，确保 "1" 变成 "01"
        const day = bill.transactionDate.split('-')[2].padStart(2, '0');

        const currentDaily = dailyMap.get(day) || 0;
        dailyMap.set(day, currentDaily + bill.amount);

        // 2. 分类
        const currentCat = categoryMap.get(bill.categoryId) || 0;
        categoryMap.set(bill.categoryId, currentCat + bill.amount);

      } else {
        incomeTotal += bill.amount;
      }
    });

    // --- 更新汇总 ---
    this.summary.totalExpense = expenseTotal;
    this.summary.totalIncome = incomeTotal;
    this.summary.billCount = bills.length;

    // --- 生成图表数据 ---
    let maxVal = 0;
    const chartArr: DailyChartData[] = [];
    dailyMap.forEach((amount, day) => {
      if(amount > maxVal) maxVal = amount;
      chartArr.push(new DailyChartData(day, amount));
    });
    // 标记最高值
    chartArr.forEach(item => {
      item.isHighest = (item.amount === maxVal && maxVal > 0);
    });
    chartArr.sort((a, b) => parseInt(a.day) - parseInt(b.day));
    this.chartData = [...chartArr];
    this.maxChartAmount = maxVal;

    // --- 生成分类排行数据 ---
    const catStats: CategoryStat[] = [];
    categoryMap.forEach((amount, catId) => {
      // 查找分类详情
      const catInfo = this.allCategories.find(c => c.categoryId === catId);
      const name = catInfo ? catInfo.name : '未知分类';
      const icon = catInfo ? catInfo.icon : '❓';

      const stat = new CategoryStat(catId, name, icon, amount);
      stat.percentage = expenseTotal > 0 ? (amount / expenseTotal) * 100 : 0;
      catStats.push(stat);
    });

    // 按金额降序排列
    catStats.sort((a, b) => b.totalAmount - a.totalAmount);
    this.categoryStats = catStats;
  }

  build() {
    Navigation() {
      // 整体是一个可滚动的列
      Scroll() {
        Column() {
          // --- 1. 顶部黑色卡片 (你的代码) ---
          Column() {
            // 标题栏
            Row() {
              Image($r('app.media.back'))
                .width(24).height(24)
                .colorFilter(
                  [
                    1, 0, 0, 0, 255,
                    0, 1, 0, 0, 255,
                    0, 0, 1, 0, 255,
                    0, 0, 0, 1, 0
                  ]
                )
                .onClick(() => router.back())

              Text('统计报表')
                .fontSize(20).fontWeight(FontWeight.Bold).fontColor(Color.White)
                .margin({ left: 12 })
            }
            .width('100%').height(56).padding({ left: 4 })

            // 月份总览
            Row() { // 包裹在一个 Row 里方便点击
              Text(`${this.currentMonth.getFullYear()}年${this.currentMonth.getMonth() + 1}月`)
                .fontSize(14).fontColor('#999999')
              Image($r('app.media.back')) // 假设你有一个下拉箭头图标
                .width(12).height(12).margin({ left: 4 }).colorFilter(
                [
                  1, 0, 0, 0, 255,
                  0, 1, 0, 0, 255,
                  0, 0, 1, 0, 255,
                  0, 0, 0, 1, 0
                ]
              )
            }
            .margin({ bottom: 4 })
            .onClick(() => {
              // 使用系统自带的日期选择弹窗
              DatePickerDialog.show({
                start: new Date("2020-01-01"),
                end: new Date("2100-12-31"),
                selected: this.currentMonth,
                onAccept: (value: DatePickerResult) => {
                  // 更新当前月份
                  const newDate = new Date(value.year, value.month, 1);
                  this.currentMonth = newDate;
                  // 重新加载数据
                  this.loadData();
                }
              })
            })

            Text(`¥${this.summary.totalExpense.toFixed(2)}`)
              .fontSize(32).fontWeight(FontWeight.Bold).fontColor(Color.White)
            Text('总支出')
              .fontSize(12).fontColor('#999999').margin({ bottom: 20 })

            // 柱状图区域
            Column() {
              Row() {
                Text('每日趋势').fontSize(14).fontColor(Color.White).fontWeight(FontWeight.Medium)
                Blank()
              }.width('100%').margin({ bottom: 10 })

              // 引用我们刚才写的组件
              DailyBarChart({
                dataList: this.chartData,
                maxAmount: this.maxChartAmount
              })
                .height(180)
                .width('100%')

            }
            .padding(16)
            .backgroundColor('#1C1C1E')
            .borderRadius(16)
          }
          .width('100%')
          .padding(16)
          .backgroundColor(Color.Black)

          // --- 2. 分类支出排行 (新功能) ---
          Column() {
            Text('支出分类排行')
              .fontSize(16).fontWeight(FontWeight.Bold).fontColor(Color.White)
              .width('100%').margin({ bottom: 12, top: 20, left: 4 })

            if (this.categoryStats.length === 0) {
              Text('本月暂无支出').fontColor('#666666').fontSize(14).margin({top: 20}).width('100%').textAlign(TextAlign.Center)
            } else {
              List({ space: 12 }) {
                ForEach(this.categoryStats, (item: CategoryStat) => {
                  ListItem() {
                    Row() {
                      // 图标
                      Text(item.icon).fontSize(20).width(30)

                      // 名字和进度条
                      Column({ space: 6 }) {
                        Row() {
                          Text(item.categoryName).fontColor(Color.White).fontSize(14)
                          Blank()
                          Text(`${item.percentage.toFixed(1)}%`).fontColor('#666666').fontSize(12)
                          Text(` ¥${item.totalAmount.toFixed(0)}`).fontColor(Color.White).fontSize(14).fontWeight(FontWeight.Bold)
                        }.width('100%')

                        // 简单的进度条
                        Progress({ value: item.percentage, total: 100, type: ProgressType.Linear })
                          .color('#4D8DFF') // 蓝色进度条
                          .backgroundColor('#333333')
                          .height(6)
                      }
                      .layoutWeight(1)
                    }
                    .padding(12)
                    .backgroundColor('#1C1C1E')
                    .borderRadius(12)
                  }
                })
              }
              .width('100%')
              .height('auto') // 自适应高度
            }
          }
          .padding({ left: 16, right: 16, bottom: 30 })
        }
      }
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .height('100%')
      .backgroundColor(Color.Black) // 确保全屏深色背景
    }
    .hideTitleBar(true)
  }
}
@Component
struct DailyBarChart {
  @Prop dataList: DailyChartData[] = [];
  @Prop maxAmount: number = 1;

  // 1. 定义滚动控制器
  private scroller: Scroller = new Scroller();

  build() {
    Column() {
      if (this.dataList.length === 0) {
        Text("等待数据加载...")
          .fontColor(Color.White).fontSize(12).margin(20)
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
                  .backgroundColor(item.isHighest ? '#4D8DFF' : '#555555')
                  .borderRadius({ topLeft: 4, topRight: 4 })
                  .constraintSize({ minHeight: 4 }) // 0金额也显示一个小底座
              }
              .width(12)
              .height('80%')
              .justifyContent(FlexAlign.End)

              // --- 日期 ---
              Text(item.day)
                .fontSize(10)
                .fontColor(item.isHighest ? '#FFFFFF' : '#999999')
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
        // 3. 【关键优化】组件显示时，自动滚动到最后一天（或者今天）
        //稍微延迟一下确保数据渲染完了
        setTimeout(() => {
          this.scroller.scrollToIndex(this.dataList.length - 1);
        }, 100);
      })
    }
    .width('100%')
    .height('100%')
  }
}
