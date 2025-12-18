<<<<<<< HEAD
import { Bill } from '../model/Bill';
import { BillDAO, DateRangeFilter } from '../dao/BillDAO';
import { Category } from '../model/Category';
import { CategoryDAO } from '../dao/CategoryDAO';
import { UserSessionService } from '../service/UserSessionService';
import hilog from '@ohos.hilog';

@Component
export struct StatisticsPage {
  @Prop @Watch('onRefreshTrigger') refreshTrigger: number = 0;
  @State displayType: 'expense' | 'income' = 'expense'; // Toggle state

  @State currentYear: number = new Date().getFullYear();
  @State currentMonth: number = new Date().getMonth() + 1;
  @State totalExpense: number = 0;
  @State totalIncome: number = 0;
  @State dailyTrend: number[] = [];
  @State categoryRanking: CategoryStatItem[] = [];
  @State isLoading: boolean = false;
  
  // Data Holder to support toggling without reloading DB
  private allBills: Bill[] = [];
  
  // Constants for chart
  private readonly DAYS_IN_MONTH = 31;
  private readonly CHART_MAX_HEIGHT = 150;

  async aboutToAppear() {
    await this.loadData();
  }

  onRefreshTrigger() {
=======
import router from '@ohos.router';
import { Bill } from '../model/Bill';
import { BillDAO } from '../dao/BillDAO'; 
import { CategoryDAO } from '../dao/CategoryDAO';
import { Category } from '../model/Category';
import { DailyChartData, MonthSummary, CategoryStat } from '../model/ChartData';
import { AppTheme } from '../common/AppTheme';
import { DailyBarChart } from '../components/DailyBarChart';
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
  // 新增：统计类型 'expense' | 'income'
  @State statType: 'expense' | 'income' = 'expense';

  onPageShow() {
>>>>>>> main
    this.loadData();
  }

  async loadData() {
<<<<<<< HEAD
    this.isLoading = true;
    try {
      const userId = UserSessionService.getCurrentUserId();
      if (!userId) return;

      // 1. Calculate date range for current month
      const startDate = `${this.currentYear}-${this.currentMonth.toString().padStart(2, '0')}-01`;
      const lastDay = new Date(this.currentYear, this.currentMonth, 0).getDate();
      const endDate = `${this.currentYear}-${this.currentMonth.toString().padStart(2, '0')}-${lastDay}`;
      const dateRange: DateRangeFilter = { start: startDate, end: endDate };

      // 2. Fetch all bills for the month
      const bills = await BillDAO.getBillsByFilters(userId, dateRange);
      this.allBills = bills; // Ensure data is saved for toggling

      // 3. Process data
      this.processData(bills, lastDay);

    } catch (error) {
      hilog.error(0x0000, 'StatisticsPage', 'Failed to load data: %{public}s', JSON.stringify(error));
    } finally {
      this.isLoading = false;
    }
  }

  processData(bills: Bill[], daysInMonth: number) {
    let tExpense = 0;
    let tIncome = 0;
    const dTrend: number[] = new Array(daysInMonth).fill(0);
    const catMap = new Map<number, number>(); // categoryId -> amount

    bills.forEach(bill => {
      if (bill.type === 'expense') {
        tExpense += bill.amount;
        
        // Daily Trend (Day index is date - 1)
        const date = new Date(bill.transactionDate);
        // Ensure date parsing is correct (assuming YYYY-MM-DD string)
        // Note: new Date('2023-01-01') in JS acts as UTC often, but getDate() uses local. 
        // Safer to parse string manually to avoid timezone issues or use reliable parsing.
        const day = parseInt(bill.transactionDate.split('-')[2]);
        if (day >= 1 && day <= daysInMonth) {
          dTrend[day - 1] += bill.amount;
        }

        // Category Ranking
        const currentCatAmount = catMap.get(bill.categoryId) || 0;
        catMap.set(bill.categoryId, currentCatAmount + bill.amount);

      } else if (bill.type === 'income') {
        tIncome += bill.amount;
      }
    });

    this.totalExpense = tExpense;
    this.totalIncome = tIncome;
    
    // Calculate trend based on displayType
    this.recalculateTrendAndRanking(daysInMonth);
  }

  recalculateTrendAndRanking(daysInMonth: number) {
     const dTrend: number[] = new Array(daysInMonth).fill(0);
     const catMap = new Map<number, number>(); 
     
     this.allBills.filter(b => b.type === this.displayType).forEach(bill => {
        const day = parseInt(bill.transactionDate.split('-')[2]);
        if (day >= 1 && day <= daysInMonth) {
          dTrend[day - 1] += bill.amount;
        }
        const currentCatAmount = catMap.get(bill.categoryId) || 0;
        catMap.set(bill.categoryId, currentCatAmount + bill.amount);
     });

    this.dailyTrend = dTrend; 
    
    // Recalculate ranking total for percentages
    const totalBase = this.displayType === 'expense' ? this.totalExpense : this.totalIncome;
    this.loadCategories(catMap, totalBase);
  }

  async loadCategories(catMap: Map<number, number>, totalExpense: number) {
    const userId = UserSessionService.getCurrentUserId();
    if (!userId) return;
    
    const categories = await CategoryDAO.getAll(userId);
    const ranking: CategoryStatItem[] = [];

    catMap.forEach((amount, catId) => {
      const cat = categories.find(c => c.categoryId === catId);
      if (cat) {
        ranking.push({
          categoryId: catId,
          name: cat.name,
          amount: amount,
          percentage: totalExpense > 0 ? (amount / totalExpense) * 100 : 0,
          color: '#E0E0E0' // Placeholder color, ideally from Category if available
        });
      }
    });

    // Sort by amount desc
    ranking.sort((a, b) => b.amount - a.amount);
    this.categoryRanking = ranking;
  }

  build() {
    Column() {
      // Header
      Row() {
        Image($r('app.media.back')) // Assuming this is navigation back or maybe just title for tab
          .width(24)
          .height(24)
          .visibility(Visibility.Hidden) // Hidden since it's in a tab
        Text('统计报表')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })
      }
      .width('100%')
      .padding(16)
      
      Scroll() {
        Column() {
          // Month Selector and Total
          Column() {
            Row() {
              Text(`${this.currentYear}年${this.currentMonth}月`)
                .fontSize(16)
                .fontColor(Color.Gray)
              Text(' ▽') // Simple indicator
                .fontSize(12)
                .fontColor(Color.Gray)
            }
            .onClick(() => {
              DatePickerDialog.show({
                selected: new Date(this.currentYear, this.currentMonth - 1),
                onAccept: (value: DatePickerResult) => {
                  this.currentYear = value.year!;
                  this.currentMonth = value.month! + 1;
=======
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
      // 1. 计算总收支
      if (bill.type === 'expense') {
        expenseTotal += bill.amount;
      } else {
        incomeTotal += bill.amount;
      }

      // 2. 根据当前统计类型 (statType) 聚合数据
      if (bill.type === this.statType) {
        const dateParts = bill.transactionDate.split('-');
        const day = dateParts[2].padStart(2, '0');

        // 每日趋势
        const currentDaily = dailyMap.get(day) || 0;
        dailyMap.set(day, currentDaily + bill.amount);

        // 分类排行
        const currentCat = categoryMap.get(bill.categoryId) || 0;
        categoryMap.set(bill.categoryId, currentCat + bill.amount);
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
      // 计算百分比
      const total = this.statType === 'expense' ? expenseTotal : incomeTotal;
      stat.percentage = total > 0 ? (amount / total) * 100 : 0;
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
                .fontSize(20).fontWeight(FontWeight.Bold).fontColor(AppTheme.DarkTextMain)
                .margin({ left: 12 })
            }
            .width('100%').height(56).padding({ left: 4 })

            // 月份总览
            Row() { // 包裹在一个 Row 里方便点击
              Text(`${this.currentMonth.getFullYear()}年${this.currentMonth.getMonth() + 1}月`)
                .fontSize(14).fontColor(AppTheme.DarkTextSub)
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
>>>>>>> main
                  this.loadData();
                }
              })
            })
<<<<<<< HEAD
            .margin({ top: 10, bottom: 5 })

            Text(`¥${(this.displayType === 'expense' ? this.totalExpense : this.totalIncome).toFixed(2)}`)
              .fontSize(36)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
            
            Text(this.displayType === 'expense' ? '总支出 (点击切换)' : '总收入 (点击切换)')
              .fontSize(12)
              .fontColor(Color.Gray)
              .margin({ bottom: 20 })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
          .backgroundColor(Color.Black) // Matches screenshot dark header area
          .padding({ top: 20, bottom: 20 })
          .onClick(() => {
             this.displayType = this.displayType === 'expense' ? 'income' : 'expense';
             const lastDay = new Date(this.currentYear, this.currentMonth, 0).getDate();
             this.recalculateTrendAndRanking(lastDay);
          })

          // Daily Trend Chart
          Column() {
            Text('每日趋势')
              .fontSize(14)
              .fontColor(Color.White)
              .width('100%')
              .margin({ bottom: 10 })
            
            // Bar Chart Area
            Scroll() {
              Row({ space: 10 }) {
                ForEach(this.getChartData(), (item: ChartItem) => {
                  Column() {
                    // Bar
                    Column()
                      .width(8)
                      .height(this.getBarHeight(item.amount))
                      .backgroundColor('#4A90E2') // Blue bars
                      .borderRadius({ topLeft: 4, topRight: 4 })
                    
                    // Date
                    Text(item.day.toString())
                      .fontSize(10)
                      .fontColor(Color.Gray)
                      .margin({ top: 5 })
                  }
                  .justifyContent(FlexAlign.End)
                  .height(this.CHART_MAX_HEIGHT + 20)
                })
              }
              .padding({ left: 10, right: 10 })
            }
            .scrollable(ScrollDirection.Horizontal)
            .width('100%')
            .scrollBar(BarState.Off)
          }
          .width('95%')
          .padding(15)
          .backgroundColor('#1C1C1E') // Dark card background
          .borderRadius(16)
          .margin({ top: -10, bottom: 10 }) // Overlap slightly if needed, or just margin

          // Category Ranking
          Column() {
            Text(this.displayType === 'expense' ? '支出分类排行' : '收入分类排行')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
              .width('100%')
              .margin({ bottom: 15 })

            List({ space: 15 }) {
              ForEach(this.categoryRanking, (item: CategoryStatItem) => {
                ListItem() {
                  Column() {
                    Row() {
                      // Icon placeholder
                      Image($r('app.media.icon')) 
                        .width(30)
                        .height(30)
                        .margin({ right: 10 })
                      
                      Column() {
                        Row() {
                          Text(item.name)
                            .fontColor(Color.White)
                            .fontSize(16)
                          Blank()
                           Row() {
                            Text(`${item.percentage.toFixed(1)}% `)
                              .fontSize(12)
                              .fontColor(Color.Gray)
                            Text(`¥${item.amount.toFixed(0)}`)
                              .fontSize(16)
                              .fontWeight(FontWeight.Bold)
                              .fontColor(Color.White)
                          }
                        }
                        .width('100%')
                        .justifyContent(FlexAlign.SpaceBetween)

                        // Progress Bar
                        Progress({ value: item.percentage, total: 100, type: ProgressType.Linear })
                          .color('#4A90E2')
                          .backgroundColor('#333333')
                          .height(6)
                          .margin({ top: 8 })
                      }
                      .layoutWeight(1)
                    }
                  }
                  .width('100%')
                  .padding({ top: 5, bottom: 5 })
                }
              })
            }
            .width('100%')
          }
          .width('100%')
          .padding(20) // Matches screenshot spacing
          
        }
        .width('100%')
        .constraintSize({ minHeight: '100%' })
        .backgroundColor(Color.Black) // Main generic background
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Black)
  }

  getBarHeight(amount: number): number {
    const max = Math.max(...this.dailyTrend, 0);
    if (max === 0) return 0;
    return (amount / max) * this.CHART_MAX_HEIGHT;
  }

  getChartData(): ChartItem[] {
    return this.dailyTrend.map((amount, index) => new ChartItem(amount, index + 1));
  }
}

class ChartItem {
  amount: number;
  day: number;

  constructor(amount: number, day: number) {
    this.amount = amount;
    this.day = day;
  }

}

interface CategoryStatItem {
  categoryId: number;
  name: string;
  amount: number;
  percentage: number;
  color: string;
}
=======


            Column() {
              Text(this.statType === 'expense' ? `¥${this.summary.totalExpense.toFixed(2)}` : `¥${this.summary.totalIncome.toFixed(2)}`)
                .fontSize(32).fontWeight(FontWeight.Bold).fontColor(AppTheme.DarkTextMain)
              Text(this.statType === 'expense' ? '总支出 (点击切换)' : '总收入 (点击切换)')
                .fontSize(12).fontColor(AppTheme.DarkTextSub)
            }
            .margin({ bottom: 20 })
            .onClick(() => {
              // 切换逻辑
              this.statType = this.statType === 'expense' ? 'income' : 'expense';
              // 重新计算数据
              const year = this.currentMonth.getFullYear();
              const month = this.currentMonth.getMonth() + 1;
              const lastDay = new Date(year, month, 0).getDate();
              this.processData(this.billList, lastDay);
            })

            // 柱状图区域
            Column() {
              Row() {
                Text('每日趋势').fontSize(14).fontColor(AppTheme.DarkTextMain).fontWeight(FontWeight.Medium)
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
            .backgroundColor(AppTheme.DarkCardBg)
            .borderRadius(16)
          }
          .width('100%')
          .padding(16)
          .backgroundColor(AppTheme.DarkBackground)

          // --- 2. 分类支出排行 (新功能) ---
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
                      // 图标
                      Text(item.icon).fontSize(20).width(30)

                      // 名字和进度条
                      Column({ space: 6 }) {
                        Row() {
                          Text(item.categoryName).fontColor(AppTheme.DarkTextMain).fontSize(14)
                          Blank()
                          Text(`${item.percentage.toFixed(1)}%`).fontColor(AppTheme.DarkTextSub).fontSize(12)
                          Text(` ¥${item.totalAmount.toFixed(0)}`).fontColor(AppTheme.DarkTextMain).fontSize(14).fontWeight(FontWeight.Bold)
                        }.width('100%')

                        // 简单的进度条
                        Progress({ value: item.percentage, total: 100, type: ProgressType.Linear })
                          .color(AppTheme.ChartHighlight) // 蓝色进度条
                          .backgroundColor(AppTheme.ChartInactive) // Dark gray bg
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
              .height('auto') // 自适应高度
            }
          }
          .padding({ left: 16, right: 16, bottom: 30 })
        }
      }
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .height('100%')
      .backgroundColor(AppTheme.DarkBackground) // 确保全屏深色背景
    }
    .hideTitleBar(true)
  }
}

>>>>>>> main
