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
    this.loadData();
  }

  async loadData() {
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
                  this.loadData();
                }
              })
            })
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
