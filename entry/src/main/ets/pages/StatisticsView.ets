import router from '@ohos.router';
import { Bill } from '../model/Bill';
import { BillDAO, DateRangeFilter } from '../dao/BillDAO'; 
import { CategoryDAO } from '../dao/CategoryDAO';
import { Category } from '../model/Category';
import { DailyChartData, MonthSummary, CategoryStat } from '../model/ChartData';
import { AppTheme } from '../common/AppTheme';
import { DailyBarChart } from '../components/DailyBarChart';
import hilog from '@ohos.hilog';
import { UserSessionService } from '../service/UserSessionService';

const LOG_TAG = 'StatisticsView';
const HILOG_DOMAIN = 0x0001;

/**
 * Reusable statistics component for embedding in Tabs or other pages.
 * Does not have @Entry.
 */
@Component
export struct StatisticsView {
  @Prop @Watch('onRefreshTrigger') refreshTrigger: number = 0;
  @State summary: MonthSummary = new MonthSummary();
  @State chartData: DailyChartData[] = [];
  @State categoryStats: CategoryStat[] = [];
  @State billList: Bill[] = [];
  @State maxChartAmount: number = 0;
  @State currentMonth: Date = new Date();
  @State allCategories: Category[] = []; 
  @State statType: 'expense' | 'income' = 'expense';

  onRefreshTrigger() {
    this.loadData();
  }

  async aboutToAppear() {
     this.loadData();
  }

  async loadData() {
    const userId = UserSessionService.getCurrentUserId();
    if (!userId) return;

    if (this.allCategories.length === 0) {
      this.allCategories = await CategoryDAO.getAll(userId);
    }

    const year = this.currentMonth.getFullYear();
    const month = this.currentMonth.getMonth() + 1;
    const startStr = `${year}-${month.toString().padStart(2, '0')}-01`;
    const lastDay = new Date(year, month, 0).getDate();
    const endStr = `${year}-${month.toString().padStart(2, '0')}-${lastDay}`;
    const dateRange: DateRangeFilter = { start: startStr, end: endStr };

    const bills = await BillDAO.getBillsByFilters(userId, dateRange);
    this.billList = bills;

    this.processData(bills, lastDay);
  }

  processData(bills: Bill[], daysInMonth: number) {
    let expenseTotal = 0;
    let incomeTotal = 0;


    const dailyMap = new Map<string, number>();
    for(let i=1; i<=daysInMonth; i++) {
      dailyMap.set(i.toString().padStart(2, '0'), 0);
    }

    const categoryMap = new Map<number, number>();

    bills.forEach(bill => {
      if (bill.type === 'expense') {
        expenseTotal += bill.amount;
      } else {
        incomeTotal += bill.amount;
      }

      if (bill.type === this.statType) {
        const dateParts = bill.transactionDate.split('-');
        const day = dateParts[2].padStart(2, '0');

        const currentDaily = dailyMap.get(day) || 0;
        dailyMap.set(day, currentDaily + bill.amount);

        const currentCat = categoryMap.get(bill.categoryId) || 0;
        categoryMap.set(bill.categoryId, currentCat + bill.amount);
      }
    });

    this.summary.totalExpense = expenseTotal;
    this.summary.totalIncome = incomeTotal;
    this.summary.billCount = bills.length;

    let maxVal = 0;
    const chartArr: DailyChartData[] = [];
    dailyMap.forEach((amount, day) => {
      if(amount > maxVal) maxVal = amount;
      chartArr.push(new DailyChartData(day, amount));
    });
    chartArr.forEach(item => {
      item.isHighest = (item.amount === maxVal && maxVal > 0);
    });
    chartArr.sort((a, b) => parseInt(a.day) - parseInt(b.day));
    this.chartData = [...chartArr];
    this.maxChartAmount = maxVal;

    const catStats: CategoryStat[] = [];
    categoryMap.forEach((amount, catId) => {
      const catInfo = this.allCategories.find(c => c.categoryId === catId);
      const name = catInfo ? catInfo.name : '未知分类';
      const icon = catInfo ? catInfo.icon : '❓';

      const stat = new CategoryStat(catId, name, icon, amount);
      const total = this.statType === 'expense' ? expenseTotal : incomeTotal;
      stat.percentage = total > 0 ? (amount / total) * 100 : 0;
      catStats.push(stat);
    });

    catStats.sort((a, b) => b.totalAmount - a.totalAmount);
    this.categoryStats = catStats;
  }

  build() {
    Column() {
      Scroll() {
        Column() {
          Column() {
            Row() {
              Text('统计报表')
                .fontSize(20).fontWeight(FontWeight.Bold).fontColor(AppTheme.DarkTextMain)
                .margin({ left: 12 })
            }
            .width('100%').height(56).padding({ left: 4 })

            Row() { 
              Text(`${this.currentMonth.getFullYear()}年${this.currentMonth.getMonth() + 1}月`)
                .fontSize(14).fontColor(AppTheme.DarkTextSub)
              Text(' ▽').fontColor(AppTheme.DarkTextSub).fontSize(12)
            }
            .margin({ bottom: 4 })
            .onClick(() => {
              DatePickerDialog.show({
                start: new Date("2020-01-01"),
                end: new Date("2100-12-31"),
                selected: this.currentMonth,
                onAccept: (value: DatePickerResult) => {
                  const newDate = new Date(value.year, value.month, 1);
                  this.currentMonth = newDate;
                  this.loadData();
                }
              })
            })
            .margin({ top: 10, bottom: 5 })

            Column() {
              Text(this.statType === 'expense' ? `¥${this.summary.totalExpense.toFixed(2)}` : `¥${this.summary.totalIncome.toFixed(2)}`)
                .fontSize(32).fontWeight(FontWeight.Bold).fontColor(AppTheme.DarkTextMain)
              Text(this.statType === 'expense' ? '总支出 (点击切换)' : '总收入 (点击切换)')
                .fontSize(12).fontColor(AppTheme.DarkTextSub)
            }
            .margin({ bottom: 20 })
            .onClick(() => {
              this.statType = this.statType === 'expense' ? 'income' : 'expense';
              const year = this.currentMonth.getFullYear();
              const month = this.currentMonth.getMonth() + 1;
              const lastDay = new Date(year, month, 0).getDate();
              this.processData(this.billList, lastDay);
            })

            Column() {
              Row() {
                Text('每日趋势').fontSize(14).fontColor(AppTheme.DarkTextMain).fontWeight(FontWeight.Medium)
                Blank()
              }.width('100%').margin({ bottom: 10 })

              DailyBarChart({
                dataList: this.chartData,
                maxAmount: this.maxChartAmount
              })
                .height(180)
                .width('100%')

            }
            .padding(16)
            .backgroundColor(AppTheme.DarkCardBg)
            .borderRadius(16)
          }
          .width('100%')
          .padding(16)
          .backgroundColor(AppTheme.DarkBackground)

          Column() {
            Text(this.statType === 'expense' ? '支出分类排行' : '收入分类排行')
              .fontSize(16).fontWeight(FontWeight.Bold).fontColor(AppTheme.DarkTextMain)
              .width('100%').margin({ bottom: 12, top: 20, left: 4 })

            if (this.categoryStats.length === 0) {
              Text(this.statType === 'expense' ? '本月暂无支出' : '本月暂无收入').fontColor(AppTheme.TextSub).fontSize(14).margin({top: 20}).width('100%').textAlign(TextAlign.Center)
            } else {
              List({ space: 12 }) {
                ForEach(this.categoryStats, (item: CategoryStat) => {
                  ListItem() {
                    Row() {
                      Text(item.icon).fontSize(20).width(30)
                      Column({ space: 6 }) {
                        Row() {
                          Text(item.categoryName).fontColor(AppTheme.DarkTextMain).fontSize(14)
                          Blank()
                          Text(`${item.percentage.toFixed(1)}%`).fontColor(AppTheme.DarkTextSub).fontSize(12)
                          Text(` ¥${item.totalAmount.toFixed(0)}`).fontColor(AppTheme.DarkTextMain).fontSize(14).fontWeight(FontWeight.Bold)
                        }.width('100%')

                        Progress({ value: item.percentage, total: 100, type: ProgressType.Linear })
                          .color(AppTheme.ChartHighlight)
                          .backgroundColor(AppTheme.ChartInactive) 
                          .height(6)
                      }
                      .layoutWeight(1)
                    }
                    .padding(12)
                    .backgroundColor(AppTheme.DarkCardBg)
                    .borderRadius(12)
                  }
                })
              }
              .width('100%')
              .height('auto') 
            }
          }
          .padding({ left: 16, right: 16, bottom: 30 })
        }
      }
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .height('100%')
      .backgroundColor(AppTheme.DarkBackground)
    }
  }
}
