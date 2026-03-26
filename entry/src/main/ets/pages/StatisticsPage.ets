import { Bill } from '../model/Bill';
import { BillDAO, DateRangeFilter } from '../dao/BillDAO';
import { Category } from '../model/Category';
import { CategoryDAO } from '../dao/CategoryDAO';
import { UserSessionService } from '../service/UserSessionService';
import { AppSettingsService, ThemeMode } from '../service/AppSettingsService';
import { AppTheme } from '../common/config/AppTheme';
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
  @State segmentPeriods: string[] = ['周', '月', '年'];
  @State currentPeriod: string = '月';
  
  // 数据持有者
  private allBills: Bill[] = [];
  
  // 图表常量
  private readonly DAYS_IN_MONTH: number = 31;
  private readonly CHART_MAX_HEIGHT: number = 150;

  // Monochrome ring palette
  private donutColors: ResourceColor[] = [
    '#1A1A1A', '#3A3A3C', '#5A5A5D', '#7A7A7E', '#8E8E93',
    '#A8A8AD', '#BFBFC4', '#D6D6DB', '#ECECEF'
  ];

  private get pageBackgroundColor() {
    return AppTheme.Background;
  }

  private get cardBackgroundColor() {
    return AppTheme.CardBg;
  }

  private get textMainColor() {
    return AppTheme.TextMain;
  }

  private isSystemDarkTheme(): boolean {
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
      const userId = await UserSessionService.getCurrentUserId();
      if (!userId) return;

      const startDate = `${this.currentYear}-${this.currentMonth.toString().padStart(2, '0')}-01`;
      const lastDay = new Date(this.currentYear, this.currentMonth, 0).getDate();
      const endDate = `${this.currentYear}-${this.currentMonth.toString().padStart(2, '0')}-${lastDay}`;
      const dateRange: DateRangeFilter = { start: startDate, end: endDate };

      const bills = await BillDAO.getBillsByFilters(userId, dateRange);
      this.allBills = bills;

      this.processData(bills, lastDay);

    } catch (error) {
      hilog.error(0x0000, 'StatisticsPage', 'Failed to load data: %{public}s', JSON.stringify(error));
    } finally {
      this.isLoading = false;
    }
  }

  processData(bills: Bill[], daysInMonth: number) {
    let tExpense: number = 0;
    let tIncome: number = 0;
    const dTrend: number[] = new Array(daysInMonth).fill(0);
    const catMap = new Map<number, number>(); 

    bills.forEach(bill => {
      if (bill.type === 'expense') {
        tExpense += bill.amount;
        const day = parseInt(bill.transactionDate.split('-')[2]);
        if (day >= 1 && day <= daysInMonth) {
          dTrend[day - 1] += bill.amount;
        }
        const currentCatAmount = catMap.get(bill.categoryId) || 0;
        catMap.set(bill.categoryId, currentCatAmount + bill.amount);
      } else if (bill.type === 'income') {
        tIncome += bill.amount;
      }
    });

    this.totalExpense = tExpense;
    this.totalIncome = tIncome;
    
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
    
    const totalBase = this.displayType === 'expense' ? this.totalExpense : this.totalIncome;
    this.loadCategories(catMap, totalBase);
  }

  async loadCategories(catMap: Map<number, number>, totalBase: number) {
    const userId = await UserSessionService.getCurrentUserId();
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
          percentage: totalBase > 0 ? (amount / totalBase) * 100 : 0,
          color: AppTheme.TextMain
        });
      }
    });

    // 按金额降序排序
    ranking.sort((a, b) => b.amount - a.amount);
    this.categoryRanking = ranking;
  }

  getBarHeight(amount: number): number {
    const max = Math.max(...this.dailyTrend, 0);
    if (max === 0) return 0;
    return (amount / max) * this.CHART_MAX_HEIGHT;
  }

  getChartData(): ChartItem[] {
    return this.dailyTrend.map((amount, index) => new ChartItem(amount, index + 1));
  }

  getTopCategoryValues(): number[] {
    const values = this.categoryRanking.slice(0, 9).map(item => item.amount);
    return values.length > 0 ? values : []; // 确保DataPanel有默认值结构
  }
  
  getMaxTrendAmount(): number {
    return this.dailyTrend.length > 0 ? Math.max(...this.dailyTrend) : 0;
  }
  
  getAvgTrendAmount(): number {
    if (this.dailyTrend.length === 0) return 0;
    const sum = this.dailyTrend.reduce((a, b) => a + b, 0);
    return sum / this.dailyTrend.length;
  }

  private getCurrentStatLabel(): string {
    return this.displayType === 'expense' ? '支出' : '收入';
  }

  private getTrendTitle(): string {
    return this.displayType === 'expense' ? '支出趋势' : '收入趋势';
  }

  private getSourceOverviewTitle(): string {
    return this.displayType === 'expense' ? '支出占比概况' : '收入来源概况';
  }

  private getRankingTitle(): string {
    return this.displayType === 'expense' ? '支出类目排行' : '收入来源排行';
  }

  private switchDisplayType(type: 'expense' | 'income'): void {
    hilog.info(0x0000, 'StatisticsPage', `switchDisplayType: %{public}s -> %{public}s`, this.displayType, type);
    this.displayType = type;
    const lastDay = new Date(this.currentYear, this.currentMonth, 0).getDate();
    this.recalculateTrendAndRanking(lastDay);
  }

  @Builder
  CardHeader(title: string) {
    Stack({ alignContent: Alignment.BottomStart }) {
      Text(title)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.textMainColor)
    }
    .margin({ bottom: 15, right: 'auto' })
  }

  @Builder
  buildTopNav() {
    Column() {
      // 1. 分段选择器
      Row() {
        ForEach(this.segmentPeriods, (item: string) => {
          Text(item)
            .fontSize(14)
            .fontWeight(this.currentPeriod === item ? FontWeight.Bold : FontWeight.Normal)
            .fontColor(this.currentPeriod === item ? AppTheme.TextWhite : AppTheme.TextMain)
            .backgroundColor(this.currentPeriod === item ? AppTheme.HeroBg : AppTheme.CardBg)
            .borderRadius(24)
            .padding({ top: 6, bottom: 6, left: 24, right: 24 })
            .shadow(this.currentPeriod === item ? AppTheme.FabShadow : undefined)
            .onClick(() => {
              this.currentPeriod = item;
            })
        })
      }
      .backgroundColor(AppTheme.GlassBackground)
      .backdropBlur(30)
      .borderRadius(24)
      .padding(4)
      .margin({ top: 56, bottom: 20 }) // 留出系统状态栏空间
      
      // 2. 月份切换组件
      Row() {
        Text('<')
          .fontSize(18)
          .fontColor(AppTheme.TextMain)
          .fontWeight(FontWeight.Bold)
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .onClick(() => {
             if (this.currentMonth === 1) {
                this.currentMonth = 12;
                this.currentYear -= 1;
             } else {
                this.currentMonth -= 1;
             }
             this.loadData();
          })

        Text(`${this.currentYear}年${this.currentMonth}月统计`)
          .fontSize(16)
          .fontColor(AppTheme.TextMain)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16, right: 16 })
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

        Text('>')
          .fontSize(18)
          .fontColor(AppTheme.TextMain)
          .fontWeight(FontWeight.Bold)
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .onClick(() => {
             if (this.currentMonth === 12) {
                this.currentMonth = 1;
                this.currentYear += 1;
             } else {
                this.currentMonth += 1;
             }
             this.loadData();
          })
          
        Blank()
        
        Text('👁️')
          .fontSize(18)
          .fontColor(AppTheme.TextMain)
          .padding({ right: 10 })
      }
      .width('100%')
      .padding({ left: 20, right: 20 })
      .margin({ bottom: 16 })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .margin({ left: 16, right: 16, bottom: 12 })
    .padding({ bottom: 8 })
    .backgroundColor(AppTheme.GlassBackground)
    .backdropBlur(30)
    .borderRadius(28)
  }

  @Builder
  buildSummaryCards() {
    Row() {
      // 本月支出
      Button({ type: ButtonType.Normal }) {
        Column() {
          Text('本月支出')
            .fontSize(14)
            .fontColor(this.displayType === 'expense' ? AppTheme.TextWhite : AppTheme.TextSub)
            .margin({ bottom: 8 })
          Text(`¥${this.totalExpense.toFixed(2)}`)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.displayType === 'expense' ? AppTheme.TextWhite : this.textMainColor)
        }
        .width('100%')
        .height('100%')
        .alignItems(HorizontalAlign.Start)
        .justifyContent(FlexAlign.Center)
        .padding({ left: 20 })
      }
      .layoutWeight(1)
      .height(88)
      .borderRadius(24)
      .backgroundColor(this.displayType === 'expense' ? AppTheme.HeroBg : AppTheme.CardBg)
      .shadow(this.displayType === 'expense' ? AppTheme.FabShadow : AppTheme.CardShadow)
      .stateEffect(false)
      .onClick(() => {
        this.switchDisplayType('expense');
      })

      // 间隙
      Row().width(12)

      // 本月收入
      Button({ type: ButtonType.Normal }) {
        Column() {
          Text('本月收入')
            .fontSize(14)
            .fontColor(this.displayType === 'income' ? AppTheme.TextWhite : AppTheme.TextSub)
            .margin({ bottom: 8 })
          Text(`¥${this.totalIncome.toFixed(2)}`)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.displayType === 'income' ? AppTheme.TextWhite : this.textMainColor)
        }
        .width('100%')
        .height('100%')
        .alignItems(HorizontalAlign.Start)
        .justifyContent(FlexAlign.Center)
        .padding({ left: 20 })
      }
      .layoutWeight(1)
      .height(88)
      .borderRadius(24)
      .backgroundColor(this.displayType === 'income' ? AppTheme.HeroBg : AppTheme.CardBg)
      .shadow(this.displayType === 'income' ? AppTheme.FabShadow : AppTheme.CardShadow)
      .stateEffect(false)
      .onClick(() => {
        this.switchDisplayType('income');
      })
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
  }

  @Builder
  buildTrendDataSummary() {
    Row() {
      Column() {
        Text('单日最高')
          .fontSize(12)
          .fontColor(AppTheme.TextSub)
        Text(`¥${this.getMaxTrendAmount().toFixed(0)}`)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.textMainColor)
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      
      Column() {
        Text('日均')
          .fontSize(12)
          .fontColor(AppTheme.TextSub)
        Text(`¥${this.getAvgTrendAmount().toFixed(0)}`)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.textMainColor)
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 30 })
    }
    .width('100%')
    .margin({ bottom: 10 })
  }

  build() {
    Column() {
      // 1. 顶部区域：含状态栏隔离与月份切换器
      this.buildTopNav()
      
      // 2. 主区：可滑动的各类卡片
      Scroll() {
        Column() {
          // 2.1 总览：支出与收入双卡片
          this.buildSummaryCards()

          // 2.2 类别：趋势折线图
          Column() {
            Stack({ alignContent: Alignment.BottomStart }) {
              Text(this.getTrendTitle())
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.textMainColor)
            }
            .margin({ bottom: 15, right: 'auto' })
            this.buildTrendDataSummary()
            BezierLineChart({ data: this.dailyTrend, chartMaxHeight: this.CHART_MAX_HEIGHT })
          }
          .width('100%')
          .backgroundColor(AppTheme.CardBg)
          .borderRadius(24)
          .shadow(AppTheme.CardShadow)
          .margin({ top: 16 })
          .padding(24)

          // 2.3 类别：占比概况（带洞环形图）
          Column() {
            Stack({ alignContent: Alignment.BottomStart }) {
              Text(this.getSourceOverviewTitle())
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.textMainColor)
            }
            .margin({ bottom: 15, right: 'auto' })
            Stack({ alignContent: Alignment.Center }) {
              DataPanel({ 
                values: this.getTopCategoryValues(), 
                max: this.displayType === 'expense' ? this.totalExpense : this.totalIncome, 
                type: DataPanelType.Circle 
              })
                .width(180)
                .height(180)
                .valueColors(this.donutColors)
              
              Column() {
                Text(`本月${this.getCurrentStatLabel()}`)
                  .fontSize(12)
                  .fontColor(AppTheme.TextSub)
                Text(`¥${(this.displayType === 'expense' ? this.totalExpense : this.totalIncome).toFixed(2)}`)
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.textMainColor)
              }
            }
            .margin({ top: 10, bottom: 10 })
            .width('100%')
            .align(Alignment.Center)
          }
          .width('100%')
          .backgroundColor(AppTheme.CardBg)
          .borderRadius(24)
          .shadow(AppTheme.CardShadow)
          .margin({ top: 16 })
          .padding({ top: 24, bottom: 24, left: 20, right: 20 })
          .alignItems(HorizontalAlign.Start)

          // 2.4 类别：支出类目排行
          Column() {
            Stack({ alignContent: Alignment.BottomStart }) {
              Text(this.getRankingTitle())
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.textMainColor)
            }
            .margin({ bottom: 15, right: 'auto' })
            List({ space: 15 }) {
              ForEach(this.categoryRanking, (item: CategoryStatItem, index: number) => {
                ListItem() {
                  Column() {
                    Row() {
                      Row() {
                        Image($r('app.media.ic_tag_linear')) 
                          .width(16)
                          .height(16)
                          .fillColor(AppTheme.TextMain)
                          .objectFit(ImageFit.Contain)
                      }
                      .width(30)
                      .height(30)
                      .margin({ right: 10 })
                      .backgroundColor(AppTheme.CardBg)
                      .borderRadius(20)
                      .shadow(AppTheme.CardShadow)
                      .justifyContent(FlexAlign.Center)
                      
                      Column() {
                        Row() {
                          Text(item.name)
                            .fontColor(this.textMainColor)
                            .fontSize(16)
                          Blank()
                          Row() {
                            Text(`${item.percentage.toFixed(1)}% `)
                              .fontSize(12)
                              .fontColor(AppTheme.TextSub)
                            Text(`¥${item.amount.toFixed(0)}`)
                              .fontSize(16)
                              .fontWeight(FontWeight.Bold)
                              .fontColor(this.textMainColor)
                          }
                        }
                        .width('100%')

                        Progress({ value: item.percentage, total: 100, type: ProgressType.Linear })
                          .color(AppTheme.TextMain)
                          .backgroundColor(AppTheme.Border)
                          .height(6)
                          .margin({ top: 8 })
                      }
                      .layoutWeight(1)
                    }
                    .width('100%')
                    .padding({ top: 5, bottom: 5 })
                  }
                  .border({
                    width: { bottom: 0.5 },
                    color: { bottom: AppTheme.Border }
                  })
                  .padding({ bottom: index < this.categoryRanking.length - 1 ? 10 : 0 })
                }
              })
            }
            .width('100%')
            .margin({ top: 10 })
          }
          .width('100%')
          .backgroundColor(AppTheme.CardBg)
          .borderRadius(24)
          .shadow(AppTheme.CardShadow)
          .margin({ top: 16, bottom: 30 }) 
          .padding({ top: 24, bottom: 24, left: 20, right: 20 })
          .alignItems(HorizontalAlign.Start)
          
        }
        .width('100%')
        .padding({ left: 20, right: 20 }) 
        .constraintSize({ minHeight: '100%' })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    // 渐变与沉浸式区域
    .backgroundColor(AppTheme.Background)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
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

@Component
struct BezierLineChart {
  @Prop data: number[];
  @Prop chartMaxHeight: number;
  @State canvasWidth: number = 0;
  @State canvasHeight: number = 150;
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  aboutToAppear() {
    this.canvasHeight = this.chartMaxHeight;
  }

  build() {
    Canvas(this.ctx)
      .width('100%')
      .height(this.canvasHeight)
      .onAreaChange((oldValue: Area, newValue: Area) => {
        this.canvasWidth = Number(newValue.width);
        this.canvasHeight = Number(newValue.height);
        this.drawChart();
      })
      .onReady(() => {
        this.drawChart();
      })
  }

  drawChart() {
    if (!this.ctx || this.canvasWidth === 0 || this.data.length === 0) return;
    const ctx = this.ctx;
    const w = this.canvasWidth;
    const h = this.canvasHeight - 20; 
    
    ctx.clearRect(0, 0, this.canvasWidth, this.canvasHeight);

    const maxVal = Math.max(...this.data, 1); 
    const points: Point[] = [];
    const stepX = w / Math.max((this.data.length - 1), 1);
    
    let maxIdx = 0;

    this.data.forEach((val, i) => {
      if (val > this.data[maxIdx]) maxIdx = i;
      const p: Point = {
        x: i * stepX,
        y: h - (val / maxVal) * h + 10 
      };
      points.push(p);
    });

    if (points.length < 2) return;

    const gradient = ctx.createLinearGradient(0, 0, 0, this.canvasHeight);
    gradient.addColorStop(0, 'rgba(26, 26, 26, 0.24)');
    gradient.addColorStop(1, 'rgba(26, 26, 26, 0.0)');
    
    ctx.beginPath();
    ctx.moveTo(points[0].x, points[0].y);
    
    for (let i = 0; i < points.length - 1; i++) {
        const p0 = points[i];
        const p1 = points[i + 1];
        const cxC = (p0.x + p1.x) / 2;
        ctx.bezierCurveTo(cxC, p0.y, cxC, p1.y, p1.x, p1.y);
    }
    
    ctx.lineTo(points[points.length - 1].x, this.canvasHeight);
    ctx.lineTo(points[0].x, this.canvasHeight);
    ctx.closePath();
    ctx.fillStyle = gradient;
    ctx.fill();

    ctx.beginPath();
    ctx.moveTo(points[0].x, points[0].y);
    for (let i = 0; i < points.length - 1; i++) {
        const p0 = points[i];
        const p1 = points[i + 1];
        const cxC = (p0.x + p1.x) / 2;
        ctx.bezierCurveTo(cxC, p0.y, cxC, p1.y, p1.x, p1.y);
    }
    ctx.strokeStyle = '#1A1A1A';
    ctx.lineWidth = 2;
    ctx.stroke();

    const maxP = points[maxIdx];
    ctx.beginPath();
    ctx.arc(maxP.x, maxP.y, 4, 0, Math.PI * 2);
    ctx.fillStyle = '#FFFFFF';
    ctx.fill();
    ctx.strokeStyle = '#1A1A1A';
    ctx.lineWidth = 2;
    ctx.stroke();
  }
}
interface Point {
  x: number;
  y: number;
}
