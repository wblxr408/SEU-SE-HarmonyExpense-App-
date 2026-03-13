import router from '@ohos.router'
import { promptAction } from '@kit.ArkUI'
import { Bill } from '../model/Bill'
import { BillDAO } from '../dao/BillDAO'
import { Account } from '../model/Account'
import { AccountDAO } from '../dao/AccountDAO'
import { Category } from '../model/Category'
import { CategoryDAO } from '../dao/CategoryDAO'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { BreakPointType } from '../common/config/BreakpointSystem'
import { AppTheme } from '../common/config/AppTheme'
import { UserSessionService } from '../service/UserSessionService'
import { AnomalyDetectionService, AnomalyDetectionResult } from '../service/AnomalyDetectionService'
import { SmartCategoryService, CategoryRecommendation } from '../service/SmartCategoryService'

const HILOG_DOMAIN = 0x0001
const LOG_TAG = 'AddBill'

class SelectOption {
  value: string

  constructor(value: string) {
    this.value = value
  }
}

@CustomDialog
struct AnomalyAlertDialog {
  controller: CustomDialogController
  anomalies: AnomalyDetectionResult[] = []
  onConfirm: () => void = () => {}

  build() {
    Column({ space: 16 }) {
      Text('\u5f02\u5e38\u6d88\u8d39\u63d0\u9192')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppTheme.TextMain)
        .width('100%')
        .textAlign(TextAlign.Start)

      List({ space: 10 }) {
        ForEach(this.anomalies, (item: AnomalyDetectionResult) => {
          ListItem() {
            Column({ space: 4 }) {
              Text(this.getAnomalyTitle(item.anomalyType))
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppTheme.TextMain)
              Text(item.description)
                .fontSize(13)
                .fontColor(AppTheme.TextSub)
            }
            .alignItems(HorizontalAlign.Start)
            .padding(16)
            .width('100%')
            .backgroundColor(AppTheme.CardBg)
            .borderRadius(16)
            .border({ width: 0.5, color: AppTheme.Border })
          }
        })
      }
      .width('100%')
      .constraintSize({ maxHeight: 220 })

      Button('\u6211\u77e5\u9053\u4e86')
        .width('100%')
        .height(48)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppTheme.TextWhite)
        .backgroundColor(AppTheme.HeroBg)
        .borderRadius(24)
        .shadow(AppTheme.FabShadow)
        .onClick(() => {
          this.controller.close()
          this.onConfirm()
        })
    }
    .padding(24)
    .backgroundColor(AppTheme.CardBg)
    .borderRadius(24)
    .shadow(AppTheme.CardShadow)
    .width('90%')
  }

  getAnomalyTitle(type: string): string {
    const map: Record<string, string> = {
      'high_amount': '\u91d1\u989d\u8fc7\u9ad8',
      'low_amount': '\u91d1\u989d\u5f02\u5e38',
      'frequency_spike': '\u4ea4\u6613\u9891\u7e41',
      'unusual_category': '\u5206\u7c7b\u5f02\u5e38',
      'pattern_break': '\u6d88\u8d39\u4e60\u60ef\u6539\u53d8'
    }
    return map[type] || '\u68c0\u6d4b\u5230\u5f02\u5e38'
  }
}

@Entry
@Component
struct AddBill {
  @State amount: string = ''
  @State selectedDate: Date = new Date()
  @State notes: string = ''
  @State billType: 'expense' | 'income' = 'expense'
  @State allCategories: Array<Category> = []
  @State allAccounts: Array<Account> = []
  @State selectedCategoryId: number = 1
  @State selectedAccountId: number = 1
  @State categoryOptions: SelectOption[] = []
  @State accountOptions: SelectOption[] = []
  @State detectionAnomalies: AnomalyDetectionResult[] = []
  @State recommendations: CategoryRecommendation[] = []
  @State predictedCategoryId: number = 0

  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm'
  inputFontSize: BreakPointType<number> = new BreakPointType({
    sm: 34,
    md: 38,
    lg: 42
  })
  contentPadding: BreakPointType<number> = new BreakPointType({
    sm: 20,
    md: 24,
    lg: 28
  })

  private readonly keypadRows: string[][] = [
    ['7', '8', '9', 'DATE'],
    ['4', '5', '6', '+'],
    ['1', '2', '3', '-'],
    ['.', '0', 'DEL', 'DONE']
  ]

  anomalyDialogController: CustomDialogController = new CustomDialogController({
    builder: AnomalyAlertDialog({
      anomalies: this.detectionAnomalies,
      onConfirm: async () => {
        const selectedCategory = this.allCategories.find(c => c.categoryId === this.selectedCategoryId)
        if (selectedCategory) {
          const userId = await UserSessionService.getCurrentUserId()
          if (userId) {
            SmartCategoryService.learnFromUserAction(
              userId,
              this.notes,
              parseFloat(this.amount),
              this.selectedCategoryId,
              selectedCategory.name,
              this.predictedCategoryId
            )
          }
        }
        promptAction.showToast({ message: '\u4fdd\u5b58\u6210\u529f\uff0c\u4f59\u989d\u5df2\u66f4\u65b0' })
        router.back()
      }
    }),
    autoCancel: false,
    customStyle: true
  })

  async updateRecommendations() {
    const userId = await UserSessionService.getCurrentUserId()
    if (!userId) return

    if (!this.notes && !this.amount) {
      this.recommendations = []
      return
    }

    const amountNum = parseFloat(this.amount) || 0
    this.recommendations = await SmartCategoryService.recommendCategory(userId, this.notes, amountNum)

    if (this.recommendations.length > 0) {
      this.predictedCategoryId = this.recommendations[0].categoryId
    }
  }

  async loadData() {
    try {
      const userId = await UserSessionService.getCurrentUserId()
      if (!userId) {
        promptAction.showToast({ message: '\u8bf7\u5148\u767b\u5f55' })
        return
      }

      this.allCategories = await CategoryDAO.getByType(userId, this.billType)
      this.allAccounts = await AccountDAO.getByUserId(userId)

      this.categoryOptions = this.allCategories.map((c: Category) => new SelectOption(c.name))
      this.accountOptions = this.allAccounts.map((a: Account) => new SelectOption(a.name))

      if (this.allCategories.length > 0 &&
        !this.allCategories.some((c: Category) => c.categoryId === this.selectedCategoryId)) {
        this.selectedCategoryId = this.allCategories[0].categoryId
      }
      if (this.allAccounts.length > 0 &&
        !this.allAccounts.some((a: Account) => a.accountId === this.selectedAccountId)) {
        this.selectedAccountId = this.allAccounts[0].accountId
      }

      const rules = await SmartCategoryService.getUserRules(userId)
      if (rules.length === 0) {
        hilog.info(HILOG_DOMAIN, LOG_TAG, 'No smart rules found, learning from history')
        const result = await SmartCategoryService.batchLearnFromHistory(userId, 90)
        if (result.rulesCreated > 0) {
          promptAction.showToast({ message: '\u5df2\u6839\u636e\u5386\u53f2\u8d26\u5355\u4f18\u5316\u5206\u7c7b\u63a8\u8350' })
        }
      }
    } catch (err) {
      const error = err as Error
      hilog.error(HILOG_DOMAIN, LOG_TAG, 'Load data failed: %{public}s', JSON.stringify(error))
      promptAction.showToast({ message: '\u52a0\u8f7d\u5206\u7c7b\u6216\u8d26\u6237\u5931\u8d25' })
    }
  }

  async aboutToAppear() {
    const params = router.getParams() as Record<string, string | number>
    if (params) {
      if (params['prefilledAmount']) {
        this.amount = String(params['prefilledAmount'])
      }
      if (params['prefilledNote']) {
        this.notes = String(params['prefilledNote'])
      }
      if (params['prefilledCategoryId']) {
        this.selectedCategoryId = Number(params['prefilledCategoryId'])
      }
      if (params['prefilledDate']) {
        const dateStr = String(params['prefilledDate'])
        const parts = dateStr.split('-')
        if (parts.length === 3) {
          this.selectedDate = new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2]))
        }
      }
    }

    await this.loadData()
  }

  private formatDate(date: Date): string {
    const y: number = date.getFullYear()
    const m: string = (date.getMonth() + 1).toString().padStart(2, '0')
    const d: string = date.getDate().toString().padStart(2, '0')
    return `${y}-${m}-${d}`
  }

  private getSelectedAccountName(): string {
    return this.allAccounts.find((a: Account) => a.accountId === this.selectedAccountId)?.name ?? '\u9ed8\u8ba4\u8d26\u6237'
  }

  private getAmountDisplay(): string {
    return this.amount && this.amount.length > 0 ? this.amount : '0'
  }

  private getDateDisplay(): string {
    const month = (this.selectedDate.getMonth() + 1).toString().padStart(2, '0')
    const day = this.selectedDate.getDate().toString().padStart(2, '0')
    return `${month}.${day}`
  }

  private pickDate() {
    DatePickerDialog.show({
      start: new Date('2020-01-01'),
      end: new Date('2030-12-31'),
      selected: this.selectedDate,
      onAccept: (value: DatePickerResult) => {
        const now = new Date()
        const year = value.year ?? now.getFullYear()
        const month = value.month ?? now.getMonth()
        const day = value.day ?? now.getDate()
        this.selectedDate = new Date(year, month, day)
      }
    })
  }

  private onTypeChange(type: 'expense' | 'income') {
    if (this.billType === type) return
    this.billType = type
    this.loadData()
  }

  private appendAmount(char: string) {
    if (char === '.') {
      if (this.amount.includes('.')) {
        return
      }
      this.amount = this.amount.length > 0 ? `${this.amount}.` : '0.'
      this.updateRecommendations()
      return
    }

    if (this.amount === '0') {
      this.amount = char
    } else {
      this.amount = `${this.amount}${char}`
    }
    this.updateRecommendations()
  }

  private deleteAmount() {
    if (this.amount.length === 0) {
      return
    }
    this.amount = this.amount.substring(0, this.amount.length - 1)
    this.updateRecommendations()
  }

  private onKeypadPress(key: string) {
    if (key === 'DATE') {
      this.pickDate()
      return
    }
    if (key === 'DEL') {
      this.deleteAmount()
      return
    }
    if (key === 'DONE') {
      this.submitBill()
      return
    }
    if (key === '+') {
      this.onTypeChange('income')
      return
    }
    if (key === '-') {
      this.onTypeChange('expense')
      return
    }
    this.appendAmount(key)
  }

  private async submitBill() {
    const userId = await UserSessionService.getCurrentUserId()
    if (!userId) {
      promptAction.showToast({ message: '\u767b\u5f55\u5931\u6548' })
      return
    }

    const finalAmount = parseFloat(this.amount)
    if (isNaN(finalAmount) || finalAmount <= 0) {
      promptAction.showToast({ message: '\u8bf7\u8f93\u5165\u6709\u6548\u91d1\u989d' })
      return
    }
    if (!this.selectedCategoryId || this.selectedCategoryId <= 0) {
      promptAction.showToast({ message: '\u8bf7\u9009\u62e9\u5206\u7c7b' })
      return
    }
    if (!this.selectedAccountId || this.selectedAccountId <= 0) {
      promptAction.showToast({ message: '\u8bf7\u9009\u62e9\u8d26\u6237' })
      return
    }

    const now = new Date().toISOString()
    const newBill = new Bill()
    newBill.userId = userId
    newBill.accountId = this.selectedAccountId
    newBill.categoryId = this.selectedCategoryId
    newBill.type = this.billType
    newBill.amount = finalAmount
    newBill.note = this.notes
    newBill.transactionDate = this.formatDate(this.selectedDate)
    newBill.createdAt = now
    newBill.updatedAt = now
    newBill.isDeleted = 0

    try {
      const account = await AccountDAO.getById(this.selectedAccountId)
      if (!account) {
        promptAction.showToast({ message: '\u8d26\u6237\u4e0d\u5b58\u5728' })
        return
      }

      if (this.billType === 'expense') {
        if (account.balance < finalAmount) {
          promptAction.showToast({ message: `\u4f59\u989d\u4e0d\u8db3\uff1a${account.balance.toFixed(2)}` })
          return
        }
        account.balance -= finalAmount
      } else {
        account.balance += finalAmount
      }

      await AccountDAO.update(account)
    } catch (err) {
      console.error('Account update failed:', err)
    }

    try {
      const rowId = await BillDAO.insert(newBill)
      newBill.billId = rowId
      const anomalies = await AnomalyDetectionService.detectBillAnomaly(newBill, userId)

      if (anomalies.length > 0) {
        this.detectionAnomalies = anomalies
        this.anomalyDialogController.open()
      } else {
        const selectedCategory = this.allCategories.find(c => c.categoryId === this.selectedCategoryId)
        if (selectedCategory) {
          SmartCategoryService.learnFromUserAction(
            userId,
            this.notes,
            finalAmount,
            this.selectedCategoryId,
            selectedCategory.name,
            this.predictedCategoryId
          )
        }

        promptAction.showToast({ message: '\u4fdd\u5b58\u6210\u529f\uff0c\u4f59\u989d\u5df2\u66f4\u65b0' })
        router.back()
      }
    } catch (err) {
      const error = err as Error
      console.error('[AddBill] Save failed: %{public}s', JSON.stringify(error))
      promptAction.showToast({ message: `\u4fdd\u5b58\u5931\u8d25: ${error.message}` })
    }
  }

  @Builder
  private TopBar() {
    Row() {
      Button() {
        Text('<')
          .fontSize(20)
          .fontColor(AppTheme.TextMain)
          .fontWeight(FontWeight.Bolder)
      }
      .width(42)
      .height(42)
      .backgroundColor(AppTheme.CardBg)
      .borderRadius(21)
      .shadow(AppTheme.CardShadow)
      .onClick(() => router.back())

      if (this.allAccounts.length > 0) {
        Select(this.accountOptions)
          .value(this.getSelectedAccountName())
          .fontColor(AppTheme.TextMain)
          .selectedOptionFont({ size: 18, weight: FontWeight.Bold })
          .optionFont({ size: 16, weight: FontWeight.Medium })
          .backgroundColor(AppTheme.CardBg)
          .borderRadius(20)
          .height(42)
          .width('70%')
          .onSelect((index: number) => {
            this.selectedAccountId = this.allAccounts[index].accountId
          })
      } else {
        Button('\u6dfb\u52a0\u8d26\u6237')
          .height(42)
          .fontSize(16)
          .fontColor(AppTheme.TextMain)
          .backgroundColor(AppTheme.CardBg)
          .borderRadius(20)
          .shadow(AppTheme.CardShadow)
          .onClick(() => {
            router.pushUrl({ url: 'pages/AccountManagement' })
          })
      }

      Blank()
        .width(42)
        .height(42)
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
    .padding({ left: 20, right: 20, top: 12, bottom: 16 })
    .backgroundColor(AppTheme.GlassBackground)
    .backdropBlur(30)
    .borderRadius(24)
  }

  @Builder
  private TypeSwitcher() {
    Row({ space: 10 }) {
      this.TypeButton('\u652f\u51fa', 'expense')
      this.TypeButton('\u6536\u5165', 'income')
    }
    .width('100%')
    .padding(6)
    .margin({ top: 16, bottom: 16 })
    .backgroundColor(AppTheme.CardBg)
    .borderRadius(24)
    .shadow(AppTheme.CardShadow)
  }

  @Builder
  private TypeButton(text: string, type: 'expense' | 'income') {
    Button() {
      Text(text)
        .fontSize(18)
        .fontWeight(this.billType === type ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(this.billType === type ? AppTheme.TextWhite : AppTheme.TextSub)
    }
    .layoutWeight(1)
    .height(46)
    .backgroundColor(this.billType === type ? AppTheme.HeroBg : AppTheme.CardBg)
    .borderRadius(20)
    .onClick(() => this.onTypeChange(type))
  }

  @Builder
  private RecommendationSection() {
    if (this.recommendations.length > 0) {
      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
        ForEach(this.recommendations.slice(0, 6), (item: CategoryRecommendation) => {
          Row() {
            Text(item.categoryName)
              .fontSize(12)
              .fontColor(AppTheme.TextWhite)
            Text(' \u63a8\u8350')
              .fontSize(10)
              .fontColor(AppTheme.TextWhite)
              .opacity(0.7)
          }
          .padding({ left: 12, right: 12, top: 7, bottom: 7 })
          .backgroundColor(AppTheme.HeroBg)
          .borderRadius(16)
          .margin({ right: 8, bottom: 8 })
          .onClick(() => {
            this.selectedCategoryId = item.categoryId
            promptAction.showToast({ message: `\u5df2\u91c7\u7528\u63a8\u8350\uff1a${item.reason}` })
          })
        })
      }
      .width('100%')
      .margin({ bottom: 12 })
    }
  }

  @Builder
  private CategorySection() {
    Column({ space: 16 }) {
      Row() {
        Text('\u5206\u7c7b')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppTheme.TextMain)
        Text('\u70b9\u51fb\u9009\u62e9')
          .fontSize(13)
          .fontColor(AppTheme.TextSub)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)

      Grid() {
        ForEach(this.allCategories, (item: Category) => {
          GridItem() {
            this.CategoryItem(item)
          }
        })
      }
      .columnsTemplate('1fr 1fr 1fr 1fr')
      .columnsGap(10)
      .rowsGap(14)
    }
    .width('100%')
    .padding(24)
    .backgroundColor(AppTheme.CardBg)
    .borderRadius(24)
    .shadow(AppTheme.CardShadow)
  }

  @Builder
  private CategoryItem(item: Category) {
    Column({ space: 8 }) {
      Stack({ alignContent: Alignment.Center }) {
        Circle({ width: 58, height: 58 })
          .fill(this.selectedCategoryId === item.categoryId ? AppTheme.HeroBg : AppTheme.CardBg)
          .border({
            width: 0.5,
            color: this.selectedCategoryId === item.categoryId ? AppTheme.HeroBg : AppTheme.Border
          })

        Text(item.name.substring(0, 1))
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.selectedCategoryId === item.categoryId ? AppTheme.TextWhite : AppTheme.TextMain)
      }
      Text(item.name)
        .fontSize(13)
        .fontColor(this.selectedCategoryId === item.categoryId ? AppTheme.TextMain : AppTheme.TextSub)
        .fontWeight(this.selectedCategoryId === item.categoryId ? FontWeight.Bold : FontWeight.Medium)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.selectedCategoryId = item.categoryId
    })
  }

  @Builder
  private BottomPanel() {
    Column({ space: 14 }) {
      Column({ space: 12 }) {
        Row() {
          Text(this.billType === 'expense' ? '- \u00a5' : '+ \u00a5')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.billType === 'expense' ? AppTheme.Expense : AppTheme.Income)
          Text(this.getAmountDisplay())
            .fontSize(this.inputFontSize.getValue(this.currentBreakpoint) as number)
            .fontWeight(FontWeight.Bolder)
            .fontColor(this.billType === 'expense' ? AppTheme.Expense : AppTheme.Income)
        }
        .width('100%')

        Row({ space: 10 }) {
          TextInput({ placeholder: '\u6dfb\u52a0\u5907\u6ce8', text: this.notes })
            .placeholderColor(AppTheme.TextSub)
            .fontSize(16)
            .fontColor(AppTheme.TextMain)
            .onChange((value: string) => {
              this.notes = value
              this.updateRecommendations()
            })
            .height(44)
            .layoutWeight(1)
            .padding({ left: 12, right: 12 })
            .backgroundColor(AppTheme.CardBg)
            .borderRadius(14)
            .border({ width: 0.5, color: AppTheme.Border })

          Button(this.getDateDisplay())
            .height(44)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppTheme.TextMain)
            .backgroundColor(AppTheme.CardBg)
            .borderRadius(14)
            .border({ width: 0.5, color: AppTheme.Border })
            .onClick(() => this.pickDate())
        }
        .width('100%')
      }
      .width('100%')
      .padding(20)
      .backgroundColor(AppTheme.CardBg)
      .borderRadius(24)
      .shadow(AppTheme.CardShadow)

      Column({ space: 10 }) {
        ForEach(this.keypadRows, (row: string[]) => {
          Row({ space: 10 }) {
            ForEach(row, (key: string) => {
              this.KeypadButton(key)
            })
          }
          .width('100%')
        })
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 16, bottom: 24 })
    .backgroundColor(AppTheme.GlassBackground)
    .backdropBlur(30)
    .borderRadius({ topLeft: 30, topRight: 30 })
  }

  @Builder
  private KeypadButton(key: string) {
    Button() {
      Text(key === 'DATE' ? this.getDateDisplay() : this.getKeyDisplay(key))
        .fontSize(key === 'DONE' ? 20 : 18)
        .fontWeight(key === 'DONE' ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(key === 'DONE' ? AppTheme.TextWhite : AppTheme.TextMain)
    }
    .layoutWeight(1)
    .height(58)
    .backgroundColor(key === 'DONE' ? AppTheme.HeroBg : AppTheme.CardBg)
    .borderRadius(18)
    .border({ width: key === 'DONE' ? 0 : 0.5, color: AppTheme.Border })
    .shadow(key === 'DONE' ? AppTheme.FabShadow : AppTheme.CardShadow)
    .onClick(() => this.onKeypadPress(key))
  }

  private getKeyDisplay(key: string): string {
    if (key === 'DEL') {
      return 'DEL'
    }
    if (key === 'DONE') {
      return '\u5b8c\u6210'
    }
    if (key === 'DATE') {
      return this.getDateDisplay()
    }
    return key
  }

  build() {
    Navigation() {
      Stack({ alignContent: Alignment.Bottom }) {
        Column() {
          this.TopBar()
          this.TypeSwitcher()
          this.RecommendationSection()
          Scroll() {
            Column() {
              this.CategorySection()
            }
            .width('100%')
            .padding({ bottom: 340 })
          }
          .width('100%')
          .layoutWeight(1)
        }
        .width('100%')
        .height('100%')
        .padding({
          left: this.contentPadding.getValue(this.currentBreakpoint) as number,
          right: this.contentPadding.getValue(this.currentBreakpoint) as number,
          top: 6
        })

        this.BottomPanel()
      }
      .width('100%')
      .height('100%')
      .backgroundColor(AppTheme.Background)
    }
    .titleMode(NavigationTitleMode.Mini)
    .hideTitleBar(true)
    .hideBackButton(true)
  }
}
