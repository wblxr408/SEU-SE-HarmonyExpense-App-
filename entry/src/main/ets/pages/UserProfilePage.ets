
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { UserSessionService } from '../service/UserSessionService';
import { UserProfileDAO } from '../dao/UserProfileDAO';
import { UserProfile, INCOME_LOW, INCOME_MEDIUM, INCOME_HIGH,
  SPENDING_SAVER, SPENDING_BALANCED, SPENDING_SPENDER,
  EXECUTION_STRICT, EXECUTION_FLEXIBLE, EXECUTION_LOOSE,
  RISK_CONSERVATIVE, RISK_MODERATE, RISK_AGGRESSIVE } from '../model/UserProfile';
import { AppTheme } from '../common/config/AppTheme';

@Entry
@Component
struct UserProfilePage {
  @State profile: UserProfile | null = null;
  @State isLoading: boolean = true;
  @State isRefreshing: boolean = false;

  async aboutToAppear() {
    await this.loadProfile();
  }

  async loadProfile() {
    this.isLoading = true;
    try {
      const userId = await UserSessionService.getCurrentUserId();
      if (!userId) {
        this.isLoading = false;
        return;
      }
      this.profile = await UserProfileDAO.getByUserId(userId);
    } catch (err) {
      console.error('[UserProfilePage] Load profile failed:', err);
    } finally {
      this.isLoading = false;
    }
  }

  async refreshAnalysis() {
    this.isRefreshing = true;
    try {
      const userId = await UserSessionService.getCurrentUserId();
      if (!userId) return;
      const success = await UserProfileDAO.analyzeAndUpdate(userId);
      if (success) {
        this.profile = await UserProfileDAO.getByUserId(userId);
        promptAction.showToast({ message: '画像分析已更新' });
      } else {
        promptAction.showToast({ message: '分析失败，请确保有足够的账单数据' });
      }
    } catch (err) {
      console.error('[UserProfilePage] Refresh analysis failed:', err);
      promptAction.showToast({ message: '分析失败' });
    } finally {
      this.isRefreshing = false;
    }
  }

  // ==================== 标签映射 ====================

  getIncomeLevelLabel(level: string): string {
    if (level === INCOME_LOW) return '低收入';
    if (level === INCOME_MEDIUM) return '中等收入';
    if (level === INCOME_HIGH) return '高收入';
    return '未知';
  }

  getIncomeLevelIcon(level: string): string {
    if (level === INCOME_LOW) return '💰';
    if (level === INCOME_MEDIUM) return '💎';
    if (level === INCOME_HIGH) return '👑';
    return '❓';
  }

  getSpendingLabel(personality: string): string {
    if (personality === SPENDING_SAVER) return '储蓄型';
    if (personality === SPENDING_BALANCED) return '平衡型';
    if (personality === SPENDING_SPENDER) return '消费型';
    return '未知';
  }

  getSpendingDesc(personality: string): string {
    if (personality === SPENDING_SAVER) return '您很少超支，善于控制消费';
    if (personality === SPENDING_BALANCED) return '偶尔超支，整体消费合理';
    if (personality === SPENDING_SPENDER) return '消费较多，建议适当控制';
    return '';
  }

  getSpendingIcon(personality: string): string {
    if (personality === SPENDING_SAVER) return '🛡️';
    if (personality === SPENDING_BALANCED) return '⚖️';
    if (personality === SPENDING_SPENDER) return '🛒';
    return '❓';
  }

  getExecutionLabel(pattern: string): string {
    if (pattern === EXECUTION_STRICT) return '严格执行';
    if (pattern === EXECUTION_FLEXIBLE) return '灵活执行';
    if (pattern === EXECUTION_LOOSE) return '宽松执行';
    return '未知';
  }

  getExecutionDesc(pattern: string): string {
    if (pattern === EXECUTION_STRICT) return '偏差 < 10%，执行力极强';
    if (pattern === EXECUTION_FLEXIBLE) return '偏差 10-30%，张弛有度';
    if (pattern === EXECUTION_LOOSE) return '偏差 > 30%，需加强管控';
    return '';
  }

  getRiskLabel(tolerance: string): string {
    if (tolerance === RISK_CONSERVATIVE) return '保守型';
    if (tolerance === RISK_MODERATE) return '稳健型';
    if (tolerance === RISK_AGGRESSIVE) return '激进型';
    return '未知';
  }

  // ==================== UI Builders ====================

  @Builder
  HeroCard() {
    Column() {
      // 消费性格大标签
      Row() {
        Text(this.getSpendingIcon(this.profile!.spendingPersonality))
          .fontSize(28)
        Column() {
          Text(this.getSpendingLabel(this.profile!.spendingPersonality))
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppTheme.TextWhite)
          Text(this.getSpendingDesc(this.profile!.spendingPersonality))
            .fontSize(12)
            .fontColor(AppTheme.TextWhite)
            .opacity(0.75)
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 14 })
      }
      .width('100%')
      .margin({ bottom: 20 })

      // 三个标签徽章
      Row() {
        this.BadgeItem(this.getIncomeLevelIcon(this.profile!.incomeLevel),
          this.getIncomeLevelLabel(this.profile!.incomeLevel))
        this.BadgeItem('📊',
          this.getExecutionLabel(this.profile!.budgetExecutionPattern))
        this.BadgeItem('🎯',
          this.getRiskLabel(this.profile!.riskTolerance))
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .width('100%')
    .padding(24)
    .margin({ left: 16, right: 16, bottom: 16 })
    .backgroundColor(AppTheme.HeroBg)
    .borderRadius(24)
    .shadow(AppTheme.FabShadow)
  }

  @Builder
  BadgeItem(icon: string, label: string) {
    Row() {
      Text(icon).fontSize(14)
      Text(label)
        .fontSize(12)
        .fontColor(AppTheme.TextWhite)
        .fontWeight(FontWeight.Medium)
        .margin({ left: 4 })
    }
    .padding({ top: 6, bottom: 6, left: 12, right: 12 })
    .backgroundColor('rgba(255,255,255,0.12)')
    .borderRadius(20)
  }

  @Builder
  FinancialCard() {
    Column() {
      Text('财务概览')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppTheme.TextMain)
        .margin({ bottom: 20 })
        .width('100%')

      Row() {
        this.StatItem('月均收入', `¥${this.profile!.averageMonthlyIncome.toFixed(0)}`)
        this.StatItem('月均支出', `¥${this.profile!.averageMonthlyExpense.toFixed(0)}`)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)

      Row() {
        this.StatItem('储蓄率', `${(this.profile!.getSavingsRate() * 100).toFixed(1)}%`)
        this.StatItem('超支率', `${(this.profile!.budgetOverrunRate * 100).toFixed(1)}%`)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ top: 16 })

      // 储蓄率进度条
      Column() {
        Row() {
          Text('储蓄率')
            .fontSize(12)
            .fontColor(AppTheme.TextSub)
          Blank()
          Text(`${(this.profile!.getSavingsRate() * 100).toFixed(1)}%`)
            .fontSize(12)
            .fontColor(AppTheme.TextMain)
            .fontWeight(FontWeight.Medium)
        }
        .width('100%')
        .margin({ top: 20, bottom: 8 })

        Progress({
          value: Math.max(0, this.profile!.getSavingsRate() * 100),
          total: 100,
          type: ProgressType.Linear
        })
          .color(AppTheme.TextMain)
          .backgroundColor(AppTheme.Border)
          .height(6)
      }
    }
    .width('100%')
    .padding(24)
    .margin({ left: 16, right: 16, bottom: 16 })
    .backgroundColor(AppTheme.CardBg)
    .borderRadius(24)
    .shadow(AppTheme.CardShadow)
  }

  @Builder
  StatItem(label: string, value: string) {
    Column() {
      Text(label)
        .fontSize(12)
        .fontColor(AppTheme.TextSub)
      Text(value)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppTheme.TextMain)
        .margin({ top: 4 })
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  BehaviorCard() {
    Column() {
      Text('行为特征')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppTheme.TextMain)
        .margin({ bottom: 20 })
        .width('100%')

      // 预算执行模式
      this.BehaviorRow('预算执行',
        this.getExecutionLabel(this.profile!.budgetExecutionPattern),
        this.getExecutionDesc(this.profile!.budgetExecutionPattern))

      Divider().color(AppTheme.Border).margin({ top: 14, bottom: 14 })

      // 建议接受率
      this.BehaviorRow('建议接受率',
        `${(this.profile!.adviceAcceptanceRate * 100).toFixed(0)}%`,
        '您对智能预算建议的采纳程度')

      Divider().color(AppTheme.Border).margin({ top: 14, bottom: 14 })

      // 用户标签
      Row() {
        Text('用户标签')
          .fontSize(14)
          .fontColor(AppTheme.TextMain)
        Blank()
      }
      .width('100%')

      Flex({ wrap: FlexWrap.Wrap }) {
        if (this.profile!.isYoungUser()) {
          this.TagChip('🧑 年轻用户')
        }
        if (this.profile!.isHighIncome()) {
          this.TagChip('💎 高收入')
        }
        if (this.profile!.isLargeFamily()) {
          this.TagChip('👨‍👩‍👧‍👦 大家庭')
        }
        if (this.profile!.isSaver()) {
          this.TagChip('🛡️ 储蓄达人')
        }
        if (this.profile!.isSpender()) {
          this.TagChip('🛒 消费达人')
        }
        if (this.profile!.isStrictBudgetExecutor()) {
          this.TagChip('✅ 预算严格')
        }
        if (this.profile!.age > 0) {
          this.TagChip(`🎂 ${this.profile!.age}岁`)
        }
        if (this.profile!.familySize > 1) {
          this.TagChip(`👥 ${this.profile!.familySize}口之家`)
        }
      }
      .margin({ top: 10 })
    }
    .width('100%')
    .padding(24)
    .margin({ left: 16, right: 16, bottom: 16 })
    .backgroundColor(AppTheme.CardBg)
    .borderRadius(24)
    .shadow(AppTheme.CardShadow)
  }

  @Builder
  BehaviorRow(title: string, value: string, desc: string) {
    Column() {
      Row() {
        Text(title)
          .fontSize(14)
          .fontColor(AppTheme.TextMain)
        Blank()
        Text(value)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppTheme.TextMain)
      }
      .width('100%')

      Text(desc)
        .fontSize(12)
        .fontColor(AppTheme.TextSub)
        .margin({ top: 4 })
        .width('100%')
    }
  }

  @Builder
  TagChip(label: string) {
    Text(label)
      .fontSize(12)
      .fontColor(AppTheme.TextMain)
      .padding({ top: 4, bottom: 4, left: 10, right: 10 })
      .backgroundColor(AppTheme.Background)
      .borderRadius(12)
      .margin({ right: 8, bottom: 8 })
  }

  @Builder
  ProfileInfoRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor(AppTheme.TextSub)
      Blank()
      Text(value)
        .fontSize(14)
        .fontColor(AppTheme.TextMain)
        .fontWeight(FontWeight.Medium)
    }
    .width('100%')
    .height(48)
  }

  @Builder
  EmptyState() {
    Column() {
      Text('📊')
        .fontSize(64)
        .margin({ bottom: 16 })
      Text('暂无画像数据')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppTheme.TextMain)
        .margin({ bottom: 8 })
      Text('点击下方按钮，系统将根据您的账单数据自动分析生成画像')
        .fontSize(14)
        .fontColor(AppTheme.TextSub)
        .textAlign(TextAlign.Center)
        .maxLines(2)
        .padding({ left: 40, right: 40 })
    }
    .width('100%')
    .padding({ top: 80, bottom: 40 })
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  UpdateTimeFooter() {
    if (this.profile && this.profile.updatedAt) {
      Text(`最近更新：${this.profile.updatedAt.substring(0, 16).replace('T', ' ')}`)
        .fontSize(12)
        .fontColor(AppTheme.TextSub)
        .textAlign(TextAlign.Center)
        .width('100%')
        .margin({ top: 8, bottom: 16 })
    }
  }

  // ==================== Main Build ====================

  build() {
    Navigation() {
      Column() {
        if (this.isLoading) {
          Column() {
            LoadingProgress()
              .width(48)
              .height(48)
              .color(AppTheme.TextMain)
            Text('加载中...')
              .fontSize(14)
              .fontColor(AppTheme.TextSub)
              .margin({ top: 12 })
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else {
          Scroll() {
            Column() {
              if (this.profile) {
                this.HeroCard()
                this.FinancialCard()
                this.BehaviorCard()
                this.UpdateTimeFooter()
              } else {
                this.EmptyState()
              }

              // 刷新按钮
              Button(this.isRefreshing ? '分析中...' : (this.profile ? '刷新画像分析' : '生成我的画像'))
                .width('80%')
                .height(48)
                .backgroundColor(AppTheme.HeroBg)
                .fontColor(AppTheme.TextWhite)
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .borderRadius(24)
                .shadow(AppTheme.FabShadow)
                .enabled(!this.isRefreshing)
                .margin({ top: 16, bottom: 40 })
                .onClick(() => {
                  this.refreshAnalysis();
                })
            }
            .width('100%')
            .padding({ top: 16 })
          }
          .width('100%')
          .layoutWeight(1)
          .scrollBar(BarState.Off)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(AppTheme.Background)
    }
    .title('我的画像')
    .titleMode(NavigationTitleMode.Mini)
  }
}
