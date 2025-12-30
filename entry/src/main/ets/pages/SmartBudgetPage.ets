import router from '@ohos.router';
import { SmartBudgetPlan, ForecastResult, BudgetAdvice, CategoryBudgetAllocation } from '../model/SmartBudgetPlan';
import { Category } from '../model/Category';
import { BillDAO } from '../dao/BillDAO';
import { CategoryDAO } from '../dao/CategoryDAO';
import { BudgetDAO } from '../dao/BudgetDAO';
import { Budget } from '../model/Budget';
import { UserSessionService } from '../service/UserSessionService';
import { BudgetForecastUtils, ADVICE_DECREASE, ADVICE_MAINTAIN, ADVICE_OPTIMIZATION, ADVICE_INCREASE, FORECAST_ENSEMBLE, EnsembleForecastResult } from '../model/SmartBudgetPlan';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct SmartBudgetPage {
  @State smartPlan: SmartBudgetPlan | null = null;
  @State isLoading: boolean = true;
  @State healthScore: number = 0;
  
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(new RenderingContextSettings(true));

  // -----------------------------------
  // Lifecycle
  // -----------------------------------
  aboutToAppear() {
    this.loadData();
  }

  // -----------------------------------
  // Apply Budget Actions
  // -----------------------------------
  async applyAdvice(advice: BudgetAdvice) {
    try {
      const userId = UserSessionService.getCurrentUserId();
      if (!userId) return;

      // 查找该分类的现有预算
      const existingBudgets = await BudgetDAO.getByUserId(userId);
      const existingBudget = existingBudgets.find(b => b.categoryId === advice.categoryId);

      if (existingBudget) {
        // 更新现有预算
        existingBudget.amount = advice.suggestedBudget;
        await BudgetDAO.update(existingBudget);
      } else {
        // 创建新预算
        const newBudget = new Budget();
        newBudget.userId = userId;
        newBudget.categoryId = advice.categoryId;
        newBudget.amount = advice.suggestedBudget;
        newBudget.period = 'monthly';
        newBudget.startDate = new Date().toISOString();
        newBudget.createdAt = new Date().toISOString();
        newBudget.isActive = 1;
        await BudgetDAO.insert(newBudget);
      }

      promptAction.showToast({ message: `已调整 ${advice.categoryName} 的预算为 ¥${advice.suggestedBudget}` });
    } catch (error) {
      console.error('[SmartBudgetPage] Apply advice failed:', error);
      promptAction.showToast({ message: '预算调整失败' });
    }
  }

  async applyAllOptimizations() {
    try {
      if (!this.smartPlan) return;

      const userId = UserSessionService.getCurrentUserId();
      if (!userId) return;

      const advices = this.smartPlan.getAdvices();
      const existingBudgets = await BudgetDAO.getByUserId(userId);

      let updateCount = 0;
      for (const advice of advices) {
        const existingBudget = existingBudgets.find(b => b.categoryId === advice.categoryId);

        if (existingBudget) {
          existingBudget.amount = advice.suggestedBudget;
          await BudgetDAO.update(existingBudget);
        } else {
          const newBudget = new Budget();
          newBudget.userId = userId;
          newBudget.categoryId = advice.categoryId;
          newBudget.amount = advice.suggestedBudget;
          newBudget.period = 'monthly';
          newBudget.startDate = new Date().toISOString();
          newBudget.createdAt = new Date().toISOString();
          newBudget.isActive = 1;
          await BudgetDAO.insert(newBudget);
        }
        updateCount++;
      }

      promptAction.showToast({ message: `成功优化 ${updateCount} 个预算项` });
    } catch (error) {
      console.error('[SmartBudgetPage] Apply all optimizations failed:', error);
      promptAction.showToast({ message: '批量优化失败' });
    }
  }

  // -----------------------------------
  // Data Loading & Mocking
  // -----------------------------------
  async loadData() {
    this.isLoading = true;
    try {
      const userId = UserSessionService.getCurrentUserId();
      if (!userId) {
        this.isLoading = false;
        return;
      }

      this.smartPlan = await this.generateSmartData(userId);
      this.healthScore = this.calculateHealthScore(this.smartPlan);
    } catch (error) {
      console.error('[SmartBudgetPage] Load data failed:', error);
    } finally {
      this.isLoading = false;
    }
  }

  async generateSmartData(userId: number): Promise<SmartBudgetPlan> {
    const plan = new SmartBudgetPlan();
    plan.period = '2025-01'; // Should be dynamic based on current date
    plan.planName = '智能预算规划';
    plan.generatedAt = new Date().toISOString();
    plan.userId = userId;

    // 1. Fetch Data
    const bills = await BillDAO.getByUserId(userId);
    const categories = await CategoryDAO.getAll(userId);
    const currentBudgets = await BudgetDAO.getByUserId(userId);

    console.debug(`[SmartBudgetPage] Fetched ${bills.length} bills, ${categories.length} categories, ${currentBudgets.length} budgets`);

    // Calculate actual current total budget
    let currentTotalBudget = 0;
    currentBudgets.forEach(b => {
      // Assuming 0 or 1 for isActive/isDeleted, or check logic in Budget model
      if (b.isActive === 1) { 
        currentTotalBudget += b.amount;
      }
    });

    // 2. Process Data (Group by Month & Category)
    // Map<CategoryId, Map<MonthStr, Amount>>
    const categoryHistory = new Map<number, Map<string, number>>();
    // Map<MonthStr, TotalAmount>
    const monthlyTotals = new Map<string, number>();
    
    // Sort bills ascending for time series
    bills.sort((a, b) => new Date(a.transactionDate).getTime() - new Date(b.transactionDate).getTime());

    bills.forEach(bill => {
      if (bill.type !== 'expense') return; // Only expense
      
      const month = bill.transactionDate.substring(0, 7); // YYYY-MM
      
      // Category Aggregation
      if (!categoryHistory.has(bill.categoryId)) {
        categoryHistory.set(bill.categoryId, new Map());
      }
      const catMap = categoryHistory.get(bill.categoryId)!;
      catMap.set(month, (catMap.get(month) || 0) + bill.amount);

      // Total Aggregation
      const curTotal = monthlyTotals.get(month) || 0;
      monthlyTotals.set(month, curTotal + bill.amount);
    });

    // 3. Generate Forecasts (Total)
    const distinctMonths = Array.from(monthlyTotals.keys()).sort();
    console.debug(`[SmartBudgetPage] Distinct months found: ${JSON.stringify(distinctMonths)}`);
    
    // Create Config
    const config = BudgetForecastUtils.createDefaultConfig();
    
    // Global Forecast
    const forecasts: ForecastResult[] = [];
    
    // Reconstruct history forecasts for chart
    if (distinctMonths.length >= 1) { // Changed from 2 to 1 to show even single month
      distinctMonths.slice(-6).forEach((m, idx) => {
         forecasts.push({
            period: m,
            predictedAmount: monthlyTotals.get(m) || 0, // Actual as "predicted" for history points
            lowerBound: 0,
            upperBound: 0,
            confidence: 1,
            algorithm: 'actual'
         });
      });
    }
    
    // Future Forecast
    const totalHistoryData = distinctMonths.map(m => monthlyTotals.get(m) || 0);
    // If no history, default to 0 prediction
    let nextMonthForecast: EnsembleForecastResult = { predicted: 0, confidence: 0 };
    if (totalHistoryData.length > 0) {
      nextMonthForecast = BudgetForecastUtils.ensembleForecast(totalHistoryData, config);
    }
    
    // Dynamic next month string
    const lastMonth = distinctMonths.length > 0 ? distinctMonths[distinctMonths.length-1] : new Date().toISOString().substring(0, 7);
    let nextMonthStr = 'Next Month';
    try {
       const d = new Date(lastMonth + '-01');
       d.setMonth(d.getMonth() + 1);
       const y = d.getFullYear();
       const m = d.getMonth() + 1;
       nextMonthStr = `${y}-${m < 10 ? '0' + m : m}`;
    } catch (e) {}
    
    forecasts.push({
      period: nextMonthStr,
      predictedAmount: Math.max(0, nextMonthForecast.predicted),
      lowerBound: nextMonthForecast.predicted * 0.9,
      upperBound: nextMonthForecast.predicted * 1.1,
      confidence: nextMonthForecast.confidence > 0 ? nextMonthForecast.confidence : 0.5,
      algorithm: 'ensemble'
    });
    
    plan.forecastsJson = JSON.stringify(forecasts);
    plan.totalBudget = currentTotalBudget; 

    // 4. Generate Advices per Category
    const advices: BudgetAdvice[] = [];
    
    for (const cat of categories) {
      if (cat.type !== 'expense') continue;

      const catMap = categoryHistory.get(cat.categoryId);
      // Allow even 1 month of history to generate some advice
      if (!catMap || catMap.size < 1) continue; 

      const catHistoryData = distinctMonths.map(m => catMap.get(m) || 0);
      const prediction = BudgetForecastUtils.ensembleForecast(catHistoryData, config);
      
      const avg = BudgetForecastUtils.simpleMovingAverage(catHistoryData, 3);
      // Need at least 2 points for regression slope, else 0
      const regression = BudgetForecastUtils.linearRegression(catHistoryData);
      const trend = regression.slope > 50 ? 'up' : (regression.slope < -50 ? 'down' : 'stable');
      
      let type = ADVICE_MAINTAIN;
      let reason = '消费稳定，建议保持';
      let priority = 3;
      let savings = 0;
      let suggested = Math.round(prediction.predicted);

      // Logic adjustments for short history
      if (catHistoryData.length < 2) {
         type = ADVICE_MAINTAIN;
         reason = `${cat.name}仅有少量数据，建议按当前水平规划`;
         suggested = Math.round(avg);
      } else {
          if (trend === 'up' && prediction.predicted > avg * 1.1) {
             type = ADVICE_DECREASE;
             reason = `检测到在${cat.name}的消费通过呈上升趋势，建议控制预算`;
             priority = 1;
             suggested = Math.round(avg); 
             savings = prediction.predicted - suggested;
          } else if (trend === 'down') {
             type = ADVICE_OPTIMIZATION;
             reason = `近期${cat.name}消费减少，建议调整预算以释放资金`;
             priority = 2;
             suggested = Math.round(prediction.predicted);
          } else if (prediction.predicted > 2000 && trend === 'stable') {
             type = ADVICE_OPTIMIZATION;
             reason = `${cat.name}占比较大，建议设置限额管控`;
             priority = 2;
          }
      }

      if ((type !== ADVICE_MAINTAIN && suggested > 0) || (prediction.predicted > 500)) {
           if (type === ADVICE_MAINTAIN && prediction.predicted > 1000) {
              priority = 3;
              reason = `${cat.name}是主要支出项，请持续关注`;
           }
           
         advices.push(BudgetForecastUtils.createBudgetAdvice(
           cat.categoryId.toString(), cat.categoryId, cat.name, type, 
           Math.round(avg), 
           suggested, reason, priority, savings, trend
         ));
      }
    }
    
    // Sort by priority
    advices.sort((a, b) => a.priority - b.priority);
    plan.advicesJson = JSON.stringify(advices);

    return plan;
  }

  calculateHealthScore(plan: SmartBudgetPlan): number {
    if (!plan) return 0;
    // Simple heuristic
    let score = 80;
    const advices = plan.getAdvices();
    // More urgent advices -> lower score
    const highPriority = advices.filter(a => a.priority === 1).length;
    score -= (highPriority * 10);
    return Math.max(0, Math.min(100, score));
  }

  drawChart() {
    if (!this.smartPlan) return;
    const forecasts = this.smartPlan.getForecasts();
    if (forecasts.length === 0) return;

    const width = this.context.width;
    const height = this.context.height;
    const padding = 20;
    
    // Clear
    this.context.clearRect(0, 0, width, height);

    // Find range
    let minAmt = 999999;
    let maxAmt = 0;
    forecasts.forEach(f => {
      if (f.predictedAmount < minAmt) minAmt = f.predictedAmount;
      if (f.predictedAmount > maxAmt) maxAmt = f.predictedAmount;
    });
    // Add buffer
    minAmt = minAmt * 0.9;
    maxAmt = maxAmt * 1.1;
    const range = maxAmt - minAmt;

    // Helper to map coordinates
    const getX = (index: number) => padding + (index * (width - 2 * padding) / (forecasts.length - 1));
    const getY = (amount: number) => height - padding - ((amount - minAmt) / range) * (height - 2 * padding);

    // Draw Grid
    this.context.strokeStyle = '#f0f0f0';
    this.context.lineWidth = 1;
    this.context.beginPath();
    // Horizontal lines
    for(let i=0; i<=4; i++) {
      const y = padding + (i * (height - 2*padding) / 4);
      this.context.moveTo(padding, y);
      this.context.lineTo(width - padding, y);
    }
    this.context.stroke();

    // Draw Line
    this.context.strokeStyle = '#1890FF';
    this.context.lineWidth = 3;
    this.context.lineCap = 'round';
    this.context.beginPath();

    for (let i = 0; i < forecasts.length; i++) {
        const x = getX(i);
        const y = getY(forecasts[i].predictedAmount);
        if (i === 0) {
            this.context.moveTo(x, y);
        } else {
            // Bezier curve for smoothness
            const prevX = getX(i-1);
            const prevY = getY(forecasts[i-1].predictedAmount);
            const cp1x = prevX + (x - prevX) / 2;
            const cp1y = prevY;
            const cp2x = prevX + (x - prevX) / 2;
            const cp2y = y;
            this.context.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, x, y);
        }
    }
    this.context.stroke();

    // Draw Points
    forecasts.forEach((f, i) => {
        const x = getX(i);
        const y = getY(f.predictedAmount);
        
        this.context.beginPath();
        this.context.arc(x, y, 4, 0, 6.28);
        this.context.fillStyle = (i === forecasts.length - 1) ? '#FAAD14' : '#1890FF';
        this.context.fill();

        // Draw Label text
        this.context.fillStyle = '#666';
        this.context.font = '10px sans-serif';
        this.context.textAlign = 'center';
        this.context.fillText(f.period.split('-')[1] + '月', x, height - 5);
        
        // Draw Amount
        this.context.fillText(f.predictedAmount.toFixed(0), x, y - 10);
    });
  }

  // -----------------------------------
  // UI Builder Components
  // -----------------------------------
  
  @Builder
  NavBar() {
    Row() {
      Image($r('app.media.app_icon'))
        .width(24)
        .height(24)
        .onClick(() => router.back())
        .margin({ right: 16 })
        
      Text('智能预算分析')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
    }
    .width('100%')
    .padding({ top: 40, bottom: 20, left: 20, right: 20 })
    .backgroundColor('#4facfe')
    .linearGradient({
      angle: 135,
      colors: [[0x4facfe, 0.0], [0x00f2fe, 1.0]]
    })
  }

  @Builder
  OverviewCard() {
    Column() {
      Text('本月预算健康度')
        .fontSize(14)
        .fontColor(Color.White)
        .opacity(0.9)
        .margin({ bottom: 10 })

      Row() {
        // Left: Health Score
        Stack() {
          Progress({ value: this.healthScore, total: 100, type: ProgressType.Ring })
            .width(100)
            .color(Color.White)
            .style({ strokeWidth: 10 })
          
          Column() {
            Text(this.healthScore.toFixed(0))
              .fontSize(32)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
            Text('分')
              .fontSize(12)
              .fontColor(Color.White)
          }
        }
        .margin({ right: 30 })

        // Right: Stats
        Column({ space: 10 }) {
          Column() {
            Text('预测总支出')
              .fontSize(12)
              .fontColor(Color.White)
              .opacity(0.8)
            Text(`¥${this.smartPlan?.getForecasts().pop()?.predictedAmount ?? 0}`)
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
          }.alignItems(HorizontalAlign.Start)

          Column() {
            Text('当前预算设定')
              .fontSize(12)
              .fontColor(Color.White)
              .opacity(0.8)
            Text(`¥${this.smartPlan?.totalBudget ?? 0}`)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(Color.White)
          }.alignItems(HorizontalAlign.Start)
        }
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
    }
    .width('90%')
    .padding(20)
    .margin({ top: -30 })
    .backgroundColor('#1A1A1A')
    .borderRadius(16)
    .shadow({ radius: 10, color: 'rgba(0,0,0,0.2)', offsetY: 5 })
  }
  
  @Builder
  TrendChart() {
    Column() {
      Text('收支趋势预测')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 15, left: 5 })
        .width('100%')

      if (this.smartPlan) {
        Canvas(this.context)
          .width('100%')
          .height(200)
          .backgroundColor(Color.White)
          .borderRadius(12)
          .onReady(() => {
            this.drawChart();
          })
      }
    }
    .width('90%')
    .margin({ top: 20 })
  }

  @Builder
  AdviceList() {
    Column({ space: 15 }) {
      Text('智能建议')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 5, left: 5 })
        .width('100%')

      if (this.smartPlan) {
        ForEach(this.smartPlan.getAdvices(), (item: BudgetAdvice) => {
          this.AdviceCard(item)
        })
      }
    }
    .width('90%')
    .margin({ bottom: 80 })
  }

  @Builder
  AdviceCard(item: BudgetAdvice) {
    Row() {
      // Icon & Info
      Column() {
        Row({ space: 10 }) {
          // Category Icon Placeholder
          Circle({ width: 40, height: 40 })
            .fill(item.adviceType === 'decrease' ? '#FFF2F0' : '#F6FFED')
            
          Column({ space: 4 }) {
            Text(item.categoryName)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
            
            Text(item.reason)
              .fontSize(12)
              .fontColor(Color.Gray)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
        }
      }
      .layoutWeight(1)

      // Action
      Column() {
        if (item.adviceType === 'decrease') {
           Text(`省 ¥${item.potentialSavings.toFixed(0)}`)
             .fontSize(14)
             .fontColor('#F5222D')
             .fontWeight(FontWeight.Medium)
        } else if (item.adviceType === 'increase') {
           Text(`+${item.changePercent}%`)
             .fontSize(14)
             .fontColor('#FAAD14')
             .fontWeight(FontWeight.Medium)
        } else {
           Text('保持')
             .fontSize(14)
             .fontColor('#52C41A')
             .fontWeight(FontWeight.Medium)
        }

        Button('采纳')
          .fontSize(12)
          .height(28)
          .margin({ top: 5 })
          .backgroundColor(item.adviceType === 'decrease' ? '#F5222D' : '#1890FF')
          .onClick(() => {
            this.applyAdvice(item);
          })
      }
      .width(70)
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .padding(15)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .shadow({ radius: 5, color: 'rgba(0,0,0,0.05)', offsetY: 2 })
  }

  // -----------------------------------
  // Main Build
  // -----------------------------------
  build() {
    Column() {
      this.NavBar()
      
      Scroll() {
        Column() {
          this.OverviewCard()
          this.TrendChart()
          this.AdviceList()
        }
        .width('100%')
      }
      .layoutWeight(1)
      .align(Alignment.Top)
      
      // Bottom Action
      Button('一键优化预算')
        .width('90%')
        .height(50)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .backgroundColor('#1890FF')
        .margin({ bottom: 20 })
        .shadow({ radius: 10, color: 'rgba(24, 144, 255, 0.4)', offsetY: 5 })
        .onClick(async () => {
          await this.applyAllOptimizations();
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F0F2F5')
  }
}
