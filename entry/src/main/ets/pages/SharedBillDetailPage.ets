import router from '@ohos.router';
import { SharedLedgerService } from '../service/SharedLedgerService';
import { SharedBill, LedgerMember, BillSplitDetail } from '../model/SharedLedger';
import { UserSessionService } from '../service/UserSessionService';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct SharedBillDetailPage {
  @State billId: number = 0;
  @State bill: SharedBill | null = null;
  @State isLoading: boolean = true;
  @State currentUserId: number = 0;
  @State isOwnerOrAdmin: boolean = false;

  // Dialog for Delete Confirmation
  deleteController: CustomDialogController = new CustomDialogController({
    builder: ConfirmDialog({
      title: '删除账单',
      message: '确定要删除这条账单吗？此操作无法撤销。',
      onConfirm: () => this.handleDelete()
    }),
    alignment: DialogAlignment.Center
  });

  aboutToAppear() {
    const params = router.getParams() as Record<string, number>;
    if (params && params.billId) {
      this.billId = params.billId;
      this.currentUserId = UserSessionService.getCurrentUserId();
      this.loadData();
    } else {
      promptAction.showToast({ message: '参数错误' });
      router.back();
    }
  }

  onPageShow() {
    if (this.billId) {
      this.loadData();
    }
  }

  async loadData() {
    this.isLoading = true;
    try {
      if (!this.currentUserId) return;
      
      const bill = await SharedLedgerService.getSharedBillById(this.billId);
      if (!bill) {
        promptAction.showToast({ message: '账单不存在或已删除' });
        router.back();
        return;
      }
      this.bill = bill;

      // Check permissions (Admin or Creator can edit/delete)
      const role = await SharedLedgerService.getMemberRole(bill.ledgerId, this.currentUserId);
      this.isOwnerOrAdmin = (role === 'owner' || role === 'admin' || bill.creatorId === this.currentUserId);

    } catch (error) {
      console.error('[SharedBillDetail] 加载失败:', error);
      promptAction.showToast({ message: '加载失败' });
    } finally {
      this.isLoading = false;
    }
  }

  async handleDelete() {
    if (!this.bill) return;
    try {
      await SharedLedgerService.deleteSharedBill(this.bill.billId, this.currentUserId);
      promptAction.showToast({ message: '删除成功' });
      router.back();
    } catch (error) {
      promptAction.showToast({ message: '删除失败: ' + error.message });
    }
  }

  handleEdit() {
    if (!this.bill) return;
    router.pushUrl({
      url: 'pages/AddSharedBill',
      params: {
        ledgerId: this.bill.ledgerId,
        billId: this.bill.billId
      }
    });
  }

  build() {
    Column() {
      // 1. Header
      Row() {
        Image($r('app.media.back')) // Assumption: Resource exists
          .width(24).height(24)
          .onClick(() => router.back())
          .margin({ right: 10 })
        Text('账单详情')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
        
        Blank()

        if (this.isOwnerOrAdmin) {
          // Edit Button (Icon or Text)
           Text('编辑')
            .fontSize(16).fontColor(Color.Blue)
            .onClick(() => this.handleEdit())
        }
      }
      .width('100%').padding(16).backgroundColor(Color.White)

      if (this.isLoading || !this.bill) {
        Column() { Text('加载中...') }.justifyContent(FlexAlign.Center).height('100%')
      } else {
        Scroll() {
          Column({ space: 15 }) {
            // 2. Main Info Card
            Column() {
              // Category Icon & Name
              Row() {
                 // Placeholder for category icon
                 Circle({ width: 40, height: 40 }).fill('#E3F2FD')
                   .overlay(Text(this.bill.categoryName.substring(0, 1)).fontSize(18).fontColor('#2196F3'))
                   .margin({ right: 12 })
                 
                 Column() {
                   Text(this.bill.categoryName)
                     .fontSize(18).fontWeight(FontWeight.Medium)
                   Text(this.bill.note || '无备注')
                     .fontSize(14).fontColor(Color.Gray).margin({ top: 4 })
                 }.alignItems(HorizontalAlign.Start)
              }.width('100%').margin({ bottom: 20 })

              // Amount
              Text(`¥${this.bill.amount.toFixed(2)}`)
                .fontSize(36).fontWeight(FontWeight.Bold)
                .fontColor(Color.Black)
                .margin({ bottom: 5 })
              
              Text(`由 ${this.bill.creatorName} 支付`)
                .fontSize(14).fontColor(Color.Gray).margin({ bottom: 20 })

              Divider().color('#EEE')

              // Metadata
              Row().height(10)
              this.MetaRow('交易时间', this.bill.transactionDate.substring(0, 16).replace('T', ' '))
              this.MetaRow('账单类型', this.bill.type === 'expense' ? '支出' : '收入')
              this.MetaRow('分摊方式', this.getSplitMethodLabel(this.bill.splitType))

            }
            .width('100%')
            .padding(20)
            .backgroundColor(Color.White)
            .borderRadius(12)

            // 3. Split Details
            Column() {
              Text('分摊详情').fontSize(16).fontWeight(FontWeight.Bold).margin({ bottom: 15 })
              
              List() {
                ForEach(this.parseSplits(this.bill), (split: BillSplitDetail) => {
                  ListItem() {
                    Row() {
                      // Avatar placeholder
                      Circle({ width: 32, height: 32 }).fill('#F5F5F5')
                        .overlay(Text(split.memberName.substring(0, 1)).fontSize(12))
                        .margin({ right: 10 })
                      
                      Text(split.memberName)
                        .fontSize(16)
                      
                      Blank()
                      
                      Column() {
                        Text(`¥${split.amount.toFixed(2)}`)
                          .fontSize(16).fontWeight(FontWeight.Medium)
                          .fontColor(Color.Black)
                        Text(`${split.percentage.toFixed(0)}%`)
                           .fontSize(12).fontColor(Color.Gray).margin({top: 2})
                      }.alignItems(HorizontalAlign.End)
                    }
                    .width('100%')
                    .padding({ top: 10, bottom: 10 })
                  }
                })
              }
            }
            .width('100%')
            .padding(20)
            .backgroundColor(Color.White)
            .borderRadius(12)

            // 4. Delete Button
            if (this.isOwnerOrAdmin) {
              Button('删除账单')
                .width('100%')
                .backgroundColor('#FFEBEE')
                .fontColor(Color.Red)
                .margin({ top: 20 })
                .onClick(() => {
                  this.deleteController.open();
                })
            }
          }
          .padding(15)
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F1F3F5')
  }

  @Builder MetaRow(label: string, value: string) {
    Row() {
      Text(label).fontColor(Color.Gray).fontSize(14)
      Blank()
      Text(value).fontSize(14)
    }
    .width('100%')
    .margin({ bottom: 10 })
  }

  getSplitMethodLabel(type: string): string {
    const map: Record<string, string> = {
      'equal': '均分',
      'percentage': '按比例',
      'custom': '自定义',
      'none': '不分摊'
    };
    return map[type] || '未知';
  }

  parseSplits(bill: SharedBill): BillSplitDetail[] {
    try {
      // Prefer splitsJson if available, fallback to legacy field if needed
      // Check interface definition: SharedBill has `splitDetailsJson` or `splitsJson`?
      // Based on previous file read: SharedBill has `splitDetails: BillSplitDetail[]` directly in json?
      // Wait, SharedBill CLASS has `splitDetailsJson: string` (Line 796) and `splitsJson: string` (Line 797).
      // Let's assume usage of `splitDetailsJson` storage as per DAO logic.
      if (bill.splitDetailsJson && bill.splitDetailsJson !== '[]') {
         return JSON.parse(bill.splitDetailsJson);
      }
      if (bill.splitsJson && bill.splitsJson !== '[]') {
         // This might be the raw splits, not details with names.
         // If names are missing, we might need to map IDs to names, but simple for now.
         return JSON.parse(bill.splitsJson);
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}

@CustomDialog
struct ConfirmDialog {
  controller: CustomDialogController;
  title: string;
  message: string;
  onConfirm: () => void = () => {};

  build() {
    Column() {
      Text(this.title).fontSize(18).fontWeight(FontWeight.Bold).margin({ bottom: 15 })
      Text(this.message).fontSize(16).margin({ bottom: 20 })
      Row() {
        Button('取消').backgroundColor('#F0F0F0').fontColor('#333')
          .onClick(() => this.controller.close()).width('40%')
        Button('确定').backgroundColor(Color.Red).fontColor(Color.White)
          .onClick(() => {
             this.controller.close();
             this.onConfirm();
          }).width('40%')
      }.justifyContent(FlexAlign.SpaceBetween).width('90%')
    }
    .padding(20).backgroundColor(Color.White).borderRadius(12).width('80%')
  }
}
