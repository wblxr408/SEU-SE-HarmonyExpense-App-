import { Bill } from '../model/Bill';

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
            .backgroundColor('rgba(255, 77, 79, 0.1)')
            .fontColor('#FF4D4F')
            .height(48)
            .borderRadius(24)
            .layoutWeight(1)
            .onClick(() => {
              this.onDelete();
              this.controller?.close();
            })
            
          Button('编辑')
            .backgroundColor('#7FB069')
            .fontColor('#FFFFFF')
            .height(48)
            .borderRadius(24)
            .shadow({ radius: 8, color: 'rgba(127, 176, 105, 0.3)', offsetY: 4 })
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
      .backgroundColor('rgba(255, 255, 255, 0.75)')
      .backdropBlur(30)
      .borderRadius(32)
      .border({ width: 1, color: 'rgba(255, 255, 255, 0.9)', style: BorderStyle.Solid })
      .shadow({ radius: 32, color: 'rgba(0, 0, 0, 0.08)', offsetY: 12 })
      .padding({ top: 48, left: 24, right: 24, bottom: 24 })

      // 三、 破形悬浮分类 Icon (Floating Top Icon)
      Row() {
        Text(this.categoryName ? this.categoryName.charAt(0) : (this.bill.type === 'expense' ? '支' : '收'))
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.bill.type === 'expense' ? '#FFB347' : '#7FB069')
      }
      .width(72)
      .height(72)
      .backgroundColor('#FFFFFF')
      .borderRadius(36)
      .shadow({ radius: 16, color: 'rgba(127, 176, 105, 0.2)', offsetY: 6 })
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
        .fontColor('#888888')
      if (isAmount) {
        Text(this.bill.type === 'expense' ? `-${content}` : `+${content}`)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          // 金额颜色：支出薄荷绿不可取，题目要求是支出活力橙，收入薄荷绿
          .fontColor(this.bill.type === 'expense' ? '#FFB347' : '#7FB069')
      } else {
        Text(content)
          .fontSize(14)
          .fontColor('#333333')
          .fontWeight(FontWeight.Medium)
      }
    }
    .width('100%')
    .padding({ top: 16, bottom: 16 })
    .justifyContent(FlexAlign.SpaceBetween)
    .border(isLast ? undefined : { width: { bottom: 0.5 }, color: 'rgba(0,0,0,0.05)' })
  }
}
