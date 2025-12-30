import { Bill } from '../model/Bill';
import { BillDAO, DateRangeFilter } from '../dao/BillDAO';
import { Category } from '../model/Category';
import { CategoryDAO } from '../dao/CategoryDAO';
import { UserSessionService } from '../service/UserSessionService';
import { AppSettingsService, ThemeMode } from '../service/AppSettingsService';
import hilog from '@ohos.hilog';

@Component
export struct StatisticsPage {
  @Prop @Watch('onRefreshTrigger') refreshTrigger: number = 0;
  @State displayType: 'expense' | 'income' = 'expense'; // 切换状态

  @State currentYear: number = new Date().getFullYear();
  @State currentMonth: number = new Date().getMonth() + 1;
  @State totalExpense: number = 0;
  @State totalIncome: number = 0;
  @State dailyTrend: number[] = [];
  @State categoryRanking: CategoryStatItem[] = [];
  @State isLoading: boolean = false;
  @State isDarkTheme: boolean = false;
  
  // 数据持有者，支持切换而无需重新加载数据库
  private allBills: Bill[] = [];
  
  // 图表常量
  private readonly DAYS_IN_MONTH = 31;
  private readonly CHART_MAX_HEIGHT = 150;

  private get pageBackgroundColor() {
    return this.isDarkTheme ? '#000000' : '#F5F7F9';
  }

  private get cardBackgroundColor() {
    return this.isDarkTheme ? '#1C1C1E' : '#FFFFFF';
  }

  private get textMainColor() {
    return this.isDarkTheme ? Color.White : '#333333';
  }

  private isSystemDarkTheme(): boolean {
    // 默认返回false，因为ArkTS不支持动态获取系统主题
    // 用户可以通过手动设置深色/浅色模式来控制
    return false;
  }

  async aboutToAppear() {
    await this.loadTheme();
    await this.loadData();
  }

  async loadTheme() {
    const theme = await AppSettingsService.getTheme();
    if (theme === ThemeMode.DARK) {
      this.isDarkTheme = true;
      return;
    }
    if (theme === ThemeMode.LIGHT) {
      this.isDarkTheme = false;
      return;
    }
    this.isDarkTheme = this.isSystemDarkTheme();
  }

  onRefreshTrigger() {
    this.loadData();
  }

  async loadData() {
    this.isLoading = true;
    try {
      const userId = UserSessionService.getCurrentUserId();
      if (!userId) return;

      // 1. 计算当前月份的日期范围
      const startDate = `${this.currentYear}-${this.currentMonth.toString().padStart(2, '0')}-01`;
      const lastDay = new Date(this.currentYear, this.currentMonth, 0).getDate();
      const endDate = `${this.currentYear}-${this.currentMonth.toString().padStart(2, '0')}-${lastDay}`;
      const dateRange: DateRangeFilter = { start: startDate, end: endDate };

      // 2. 获取本月所有账单
      const bills = await BillDAO.getBillsByFilters(userId, dateRange);
      this.allBills = bills; // 确保保存数据以供切换

      // 3. 处理数据
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
    const catMap = new Map<number, number>(); // 分类ID -> 金额

    bills.forEach(bill => {
      if (bill.type === 'expense') {
        tExpense += bill.amount;
        
        // 每日趋势（天数索引为日期 - 1）
        const date = new Date(bill.transactionDate);
        // 确保日期解析正确（假设 YYYY-MM-DD 字符串）
        // 注意：JS 中的 new Date('2023-01-01') 通常表现为 UTC，但 getDate() 使用本地时间。
        // 为了避免时区问题，手动解析字符串或使用可靠的解析方法更安全。
        const day = parseInt(bill.transactionDate.split('-')[2]);
        if (day >= 1 && day <= daysInMonth) {
          dTrend[day - 1] += bill.amount;
        }

        // 分类排行
        const currentCatAmount = catMap.get(bill.categoryId) || 0;
        catMap.set(bill.categoryId, currentCatAmount + bill.amount);

      } else if (bill.type === 'income') {
        tIncome += bill.amount;
      }
    });

    this.totalExpense = tExpense;
    this.totalIncome = tIncome;
    
    // 根据显示类型计算趋势
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
    
    // 重新计算排行的总一百分比
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
          color: '#E0E0E0' // 占位符颜色，如果有的话最好从 Category 获取
        });
      }
    });

    // 按金额降序排序
    ranking.sort((a, b) => b.amount - a.amount);
    this.categoryRanking = ranking;
  }

  build() {
    Column() {
      // 头部
      Row() {
        Image($r('app.media.back')) // 假设这是导航返回或仅是 tab 标题
          .width(24)
          .height(24)
          .visibility(Visibility.Hidden) // 因为在 tab 中所以隐藏
        Text('统计报表')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.textMainColor)
          .margin({ left: 16 })
      }
      .width('100%')
      .padding(16)
      .backgroundColor(this.pageBackgroundColor)
      
      Scroll() {
        Column() {
          // 月份选择器和总计
          Column() {
            Row() {
              Text(`${this.currentYear}年${this.currentMonth}月`)
                .fontSize(16)
                .fontColor(Color.Gray)
              Text(' ▽') // 简单指示器
                .fontSize(12)
                .fontColor(Color.Gray)
            }
            .onClick(() => {
              DatePickerDialog.show({
                selected: new Date(this.currentYear, this.currentMonth - 1),
                onAccept: (value: DatePickerResult) => {
                  this.currentYear = value.year!;
                  this.currentMonth = value.month! + 1;
                  this.loadData();
                }
              })
            })
            .margin({ top: 10, bottom: 5 })

            Text(`¥${(this.displayType === 'expense' ? this.totalExpense : this.totalIncome).toFixed(2)}`)
              .fontSize(36)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.textMainColor)
            
            Text(this.displayType === 'expense' ? '总支出 (点击切换)' : '总收入 (点击切换)')
              .fontSize(12)
              .fontColor(Color.Gray)
              .margin({ bottom: 20 })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
          .backgroundColor(this.pageBackgroundColor)
          .padding({ top: 20, bottom: 20 })
          .onClick(() => {
             this.displayType = this.displayType === 'expense' ? 'income' : 'expense';
             const lastDay = new Date(this.currentYear, this.currentMonth, 0).getDate();
             this.recalculateTrendAndRanking(lastDay);
          })

          // 每日趋势图表
          Column() {
             Text('每日趋势')
              .fontSize(14)
              .fontColor(this.textMainColor)
              .width('100%')
              .margin({ bottom: 10 })
            
            // 柱状图区域
            Scroll() {
              Row({ space: 10 }) {
                ForEach(this.getChartData(), (item: ChartItem) => {
                  Column() {
                    // 柱子
                    Column()
                      .width(8)
                      .height(this.getBarHeight(item.amount))
                      .backgroundColor('#4A90E2') // 蓝色柱子
                      .borderRadius({ topLeft: 4, topRight: 4 })
                    
                    // 日期
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
          .backgroundColor(this.cardBackgroundColor)
          .borderRadius(16)
          .margin({ top: -10, bottom: 10 }) // 如果需要可以稍微重叠，或者仅设置边距
 
          // 分类排行
          Column() {
            Text(this.displayType === 'expense' ? '支出分类排行' : '收入分类排行')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.textMainColor)
              .width('100%')
              .margin({ bottom: 15 })

            List({ space: 15 }) {
              ForEach(this.categoryRanking, (item: CategoryStatItem) => {
                ListItem() {
                  Column() {
                    Row() {
                      // 图标占位符
                      Image($r('app.media.icon')) 
                        .width(30)
                        .height(30)
                        .margin({ right: 10 })
                      
                      Column() {
                        Row() {
                          Text(item.name)
                            .fontColor(this.textMainColor)
                            .fontSize(16)
                          Blank()
                           Row() {
                            Text(`${item.percentage.toFixed(1)}% `)
                              .fontSize(12)
                              .fontColor(Color.Gray)
                            Text(`¥${item.amount.toFixed(0)}`)
                              .fontSize(16)
                              .fontWeight(FontWeight.Bold)
                              .fontColor(this.textMainColor)
                          }
                        }
                        .width('100%')
                        .justifyContent(FlexAlign.SpaceBetween)

                        // 进度条
                        Progress({ value: item.percentage, total: 100, type: ProgressType.Linear })
                          .color('#4A90E2')
                          .backgroundColor(this.isDarkTheme ? '#333333' : '#E0E0E0')
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
          .padding(20) // 匹配截图中的间距
          
        }
        .width('100%')
        .constraintSize({ minHeight: '100%' })
        .backgroundColor(this.pageBackgroundColor) // 主通用背景
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.pageBackgroundColor)
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
