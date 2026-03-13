import { Bill } from '../model/Bill';
import { AppTheme } from '../common/config/AppTheme';

@CustomDialog
export struct BillDetailDialog {
  controller?: CustomDialogController;
  @Prop bill: Bill;
  @Prop categoryName: string;
  onDelete: () => void = () => {};
  onEdit: () => void = () => {};

  build() {
    Stack({ alignContent: Alignment.Top }) {
      // 二、 毛玻璃卡片主体 (Glassmorphism Card)
      Column() {
        // 四、 内容区明细排版 (Details List)
        Column() {
          this.DetailRow('类型', this.categoryName || (this.bill.type === 'expense' ? '支出' : '收入'), false)
          // 根据账户ID获取名称由于是异步的，可在外部传入或这里简化为账户ID。由于账单明细通常显示类型、金额、时间即可。
          // 此处作为示例显示账单所属ID，理想做法是在页面组合好传入。
          this.DetailRow('账户ID', this.bill.accountId.toString(), false)
          this.DetailRow('金额', this.bill.amount.toFixed(2), true)
          // 时间截取掉T和尾部的秒
          this.DetailRow('时间', this.bill.transactionDate.replace('T', ' ').substring(0, 16), false)
          this.DetailRow('备注', this.bill.note || '无', false, true)
        }

        // 五、 底部操作区 (Pill-shape Actions)
        Row({ space: 16 }) {
          Button('删除')
            .backgroundColor(AppTheme.CardBg)
            .fontColor(AppTheme.TextMain)
            .height(48)
            .borderRadius(24)
            .border({ width: 0.5, color: AppTheme.Border })
            .layoutWeight(1)
            .onClick(() => {
              this.onDelete();
              this.controller?.close();
            })
            
          Button('编辑')
            .backgroundColor(AppTheme.HeroBg)
            .fontColor(AppTheme.TextWhite)
            .height(48)
            .borderRadius(24)
            .shadow(AppTheme.FabShadow)
            .layoutWeight(1)
            .onClick(() => {
              this.onEdit();
              this.controller?.close();
            })
        }
        .width('100%')
        .margin({ top: 32 })
      }
      .margin({ top: 36 })
      .backgroundColor(AppTheme.CardBg)
      .borderRadius(24)
      .shadow(AppTheme.CardShadow)
      .padding({ top: 48, left: 24, right: 24, bottom: 24 })

      // 三、 破形悬浮分类 Icon (Floating Top Icon)
      Row() {
        Text(this.categoryName ? this.categoryName.charAt(0) : (this.bill.type === 'expense' ? '支' : '收'))
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.bill.type === 'expense' ? AppTheme.Expense : AppTheme.Income)
      }
      .width(72)
      .height(72)
      .backgroundColor(AppTheme.CardBg)
      .borderRadius(36)
      .shadow(AppTheme.CardShadow)
      .offset({ y: -36 })
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
    }
    .width('90%')
  }

  @Builder DetailRow(title: string, content: string, isAmount: boolean = false, isLast: boolean = false) {
    Row() {
      Text(title)
        .fontSize(14)
        .fontColor(AppTheme.TextSub)
      if (isAmount) {
        Text(this.bill.type === 'expense' ? `-${content}` : `+${content}`)
          .fontSize(22)
          .fontWeight(this.bill.type === 'expense' ? FontWeight.Medium : FontWeight.Bolder)
          .fontColor(this.bill.type === 'expense' ? AppTheme.Expense : AppTheme.Income)
      } else {
        Text(content)
          .fontSize(14)
          .fontColor(AppTheme.TextMain)
          .fontWeight(FontWeight.Medium)
      }
    }
    .width('100%')
    .padding({ top: 20, bottom: 20 })
    .justifyContent(FlexAlign.SpaceBetween)
    .border(isLast ? undefined : { width: { bottom: 0.5 }, color: AppTheme.Border })
  }
}
