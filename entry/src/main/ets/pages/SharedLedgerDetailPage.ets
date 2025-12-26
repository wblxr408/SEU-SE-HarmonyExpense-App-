import router from '@ohos.router';
import { SharedLedgerService, SettlementResult } from '../service/SharedLedgerService';
import { SharedLedger, LedgerMember, SharedBill } from '../model/SharedLedger';
import { UserSessionService } from '../service/UserSessionService';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct SharedLedgerDetailPage {
  @State ledgerId: number = 0;
  @State ledger: SharedLedger | null = null;
  @State members: LedgerMember[] = [];
  @State bills: SharedBill[] = [];
  @State settlements: SettlementResult[] = [];
  @State isLoading: boolean = false;
  @State currentUserId: number = 0;

  @State inviteEmail: string = '';
  dialogController: CustomDialogController = new CustomDialogController({
    builder: InviteMemberDialog({
      email: $inviteEmail,
      onConfirm: () => this.handleInvite()
    }),
    cancel: () => {},
    autoCancel: true,
    customStyle: true
  });

  aboutToAppear() {
    const params = router.getParams() as Record<string, number>;
    if (params && params.ledgerId) {
      this.ledgerId = params.ledgerId;
      this.currentUserId = UserSessionService.getCurrentUserId() ?? 0;
    } else {
      // promptAction.showToast({ message: '参数错误' });
    }
  }

  onPageShow() {
    if (this.ledgerId) {
      this.loadData();
    }
  }

  async loadData(): Promise<void> {
    this.isLoading = true;
    try {
      this.ledger = await SharedLedgerService.getLedgerDetail(this.ledgerId);
      this.members = await SharedLedgerService.getLedgerMembers(this.ledgerId);
      this.bills = await SharedLedgerService.getLedgerBills(this.ledgerId);
      this.settlements = await SharedLedgerService.calculateSettlement(this.ledgerId);
    } catch (error) {
      console.error('[SharedLedgerDetailPage] 加载失败:', error);
      promptAction.showToast({ message: '加载失败' });
    } finally {
      this.isLoading = false;
    }
  }

  async handleInvite(): Promise<void> {
    if (!this.inviteEmail) {
      promptAction.showToast({ message: '请输入用户ID' });
      return;
    }
    const inviteeId = parseInt(this.inviteEmail);
    if (isNaN(inviteeId)) {
        promptAction.showToast({ message: 'ID无效' });
        return;
    }
    
    try {
        const currentUserMember = this.members.find(m => m.userId === this.currentUserId);
        const inviterName = currentUserMember ? currentUserMember.userName : 'Unknown';
        
        await SharedLedgerService.inviteMember(this.ledgerId, this.currentUserId, inviterName, inviteeId, `User ${inviteeId}`);
        promptAction.showToast({ message: '邀请已发送' });
        this.inviteEmail = '';
        this.loadData();
    } catch (error) {
        promptAction.showToast({ message: error.message || '邀请失败' });
    }
  }

  build() {
    Column() {
      // Header
      Row() {
        Button({ type: ButtonType.Circle, stateEffect: true }) {
           Text('<').fontSize(20).fontColor(Color.Black)
        }
        .width(40).height(40).backgroundColor(Color.Transparent)
        .onClick(() => router.back())
        
        Text(this.ledger?.name || '共享账本')
          .fontSize(20).fontWeight(FontWeight.Bold).margin({ left: 16 })
        Blank()
      }
      .width('100%').height(56).padding({ left: 16, right: 16 })
      .backgroundColor(Color.White)

      Tabs() {
        // Tab 1: 账单 (Bills)
        TabContent() {
           Stack({ alignContent: Alignment.BottomEnd }) {
             Column() {
               if (this.bills.length === 0) {
                  Text('暂无账单').fontColor(Color.Gray).margin({ top: 50 })
               } else {
                  List({ space: 10 }) {
                    ForEach(this.bills, (bill: SharedBill) => {
                      ListItem() {
                        this.BillRow(bill)
                      }
                      .onClick(() => {
                        router.pushUrl({
                          url: 'pages/SharedBillDetailPage',
                          params: { billId: bill.billId }
                        });
                      })
                    })
                  }
                  .width('100%').layoutWeight(1).padding(10)
               }
             }
             .width('100%').height('100%')

             // Add Bill FAB
             Button({ type: ButtonType.Circle, stateEffect: true }) {
                Text('+').fontSize(30).fontColor(Color.White).margin({bottom: 4}) // Slight offset for centering
             }
             .width(56).height(56)
             .backgroundColor('#2196F3')
             .margin({ bottom: 20, right: 20 })
             .shadow({ radius: 4, color: '#999999', offsetY: 2 })
             .onClick(() => {
               router.pushUrl({
                 url: 'pages/AddSharedBill',
                 params: { ledgerId: this.ledgerId }
               });
             })
           }
           .width('100%').height('100%')
        }.tabBar('账单')

        // Tab 2: 成员 (Members)
        TabContent() {
          Column() {
             List({ space: 10 }) {
               ForEach(this.members, (member: LedgerMember) => {
                 ListItem() {
                   this.MemberRow(member)
                 }
               })
             }
             .width('100%').layoutWeight(1).padding(10)

             Button('邀请新成员')
               .width('90%')
               .height(48)
               .backgroundColor('#4CAF50')
               .margin({ bottom: 20, top: 10 })
               .onClick(() => {
                 this.dialogController.open();
               })
          }
          .width('100%').height('100%')
        }.tabBar('成员')

        // Tab 3: 结算 (Settlement)
        TabContent() {
           Column() {
             if (this.settlements.length === 0) {
                if (this.bills.length === 0) {
                   Text('暂无账单，无需结算').fontColor(Color.Gray).margin({ top: 50 })
                } else {
                   Text('账平了！无需转账').fontColor(Color.Green).margin({ top: 50 }).fontSize(18)
                }
             } else {
                Text('建议转账方案 (最小化交易)').fontSize(14).fontColor(Color.Gray).margin({top: 10, bottom: 10})
                List({ space: 10 }) {
                  ForEach(this.settlements, (item: SettlementResult) => {
                    ListItem() {
                      this.SettlementRow(item)
                    }
                  })
                }
                .width('100%').layoutWeight(1).padding(10)
             }
           }
           .width('100%').height('100%')
        }.tabBar('结算')
      }
      .barMode(BarMode.Fixed)
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder SettlementRow(item: SettlementResult) {
    Row() {
      // From
      Row() {
        Text(item.from.memberName.substring(0, 1))
          .fontSize(12).fontColor(Color.White).fontWeight(FontWeight.Bold)
          .width(24).height(24).borderRadius(12).backgroundColor('#F44336').textAlign(TextAlign.Center)
        Text(item.from.memberName)
          .fontSize(16).margin({ left: 5 })
      }
      
      // Arrow & Amount
      Column() {
        Text(`支付 ¥${item.amount.toFixed(2)}`)
          .fontSize(14).fontWeight(FontWeight.Bold).fontColor('#2196F3')
        Text('---->')
          .fontSize(12).fontColor(Color.Gray)
      }
      .margin({ left: 10, right: 10 })
      
      // To
      Row() {
        Text(item.to.memberName)
          .fontSize(16).margin({ right: 5 })
        Text(item.to.memberName.substring(0, 1))
          .fontSize(12).fontColor(Color.White).fontWeight(FontWeight.Bold)
          .width(24).height(24).borderRadius(12).backgroundColor('#4CAF50').textAlign(TextAlign.Center)
      }
    }
    .width('100%')
    .padding(15)
    .backgroundColor(Color.White)
    .borderRadius(8)
    .justifyContent(FlexAlign.Center)
    .shadow({ radius: 2, color: '#E0E0E0', offsetY: 1 })
  }

  @Builder BillRow(bill: SharedBill) {
    Row() {
      Column() {
        Text(bill.description || '无描述')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
        Text(`${bill.creatorName} ${bill.transactionDate}`)
          .fontSize(12)
          .fontColor(Color.Gray)
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      
      Blank()
      
      Text(`¥${bill.amount.toFixed(2)}`)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(bill.type === 'income' ? '#4CAF50' : '#F44336')
    }
    .width('100%')
    .padding(12)
    .backgroundColor(Color.White)
    .borderRadius(8)
  }

  @Builder MemberRow(member: LedgerMember) {
    Row() {
      // Avatar placeholder
      Text(member.userName.substring(0, 1).toUpperCase())
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .width(40)
        .height(40)
        .borderRadius(20)
        .backgroundColor('#FF9800')
        .textAlign(TextAlign.Center)
        .margin({ right: 12 })
        
      Column() {
        Text(member.userName)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
        Text(member.role)
          .fontSize(12)
          .fontColor(Color.Gray)
      }
      .alignItems(HorizontalAlign.Start)
      
      Blank()
      
      if (member.userId === this.ledger?.ownerId) {
         Text('群主')
           .fontSize(12)
           .fontColor(Color.Blue)
           .backgroundColor('#E3F2FD')
           .padding(4)
           .borderRadius(4)
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor(Color.White)
    .borderRadius(8)
  }
}

@CustomDialog
struct InviteMemberDialog {
  controller: CustomDialogController;
  @Link email: string;
  onConfirm: () => void = () => {};

  build() {
    Column() {
      Text('邀请新成员')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20, top: 10 })

      TextInput({ placeholder: '请输入用户ID (演示)', text: this.email })
        .onChange((val) => this.email = val)
        .margin({ bottom: 15 })
        .width('90%')
        .type(InputType.Number) // 为了演示方便，限制只能输数字ID
      
      Text('注：演示模式下请输入对方的 User ID')
        .fontSize(12)
        .fontColor(Color.Gray)
        .margin({ bottom: 20 })

      Row() {
        Button('取消')
          .backgroundColor('#F0F0F0')
          .fontColor('#333')
          .width('40%')
          .onClick(() => this.controller.close())
        
        Button('邀请')
          .width('40%')
          .onClick(() => {
            this.controller.close();
            this.onConfirm();
          })
      }
      .justifyContent(FlexAlign.SpaceBetween)
      .width('90%')
      .margin({ bottom: 10 })
    }
    .backgroundColor(Color.White)
    .borderRadius(16)
    .width('80%')
    .padding(20)
  }
}
