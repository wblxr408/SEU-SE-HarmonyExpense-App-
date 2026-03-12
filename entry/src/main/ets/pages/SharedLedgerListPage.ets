import router from '@ohos.router';
import { SharedLedgerService, CreateLedgerParams } from '../service/SharedLedgerService';
import { SharedLedger, LedgerInvitation } from '../model/SharedLedger';
import { UserSessionService } from '../service/UserSessionService';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct SharedLedgerListPage {
  @State ledgers: SharedLedger[] = [];
  @State invitations: LedgerInvitation[] = [];
  @State isLoading: boolean = false;
  
  // 创建账本弹窗相关状态
  @State showCreateDialog: boolean = false;
  @State newLedgerName: string = '';
  @State newLedgerType: string = 'family';
  
  // 账本类型选项
  private ledgerTypes: SelectOption[] = [
    { value: 'family', label: '家庭' },
    { value: 'couple', label: '情侣' },
    { value: 'roommate', label: '室友' },
    { value: 'trip', label: '旅行' },
    { value: 'team', label: '团队' },
    { value: 'project', label: '项目' },
    { value: 'other', label: '其他' }
  ];

  /* 
   * 自定义弹窗控制器
   */
  createDialogController: CustomDialogController = new CustomDialogController({
    builder: CreateLedgerDialog({
      name: $newLedgerName,
      type: $newLedgerType,
      onConfirm: () => { this.handleCreateLedger(); }
    }),
    alignment: DialogAlignment.Bottom,
    customStyle: true
  });

  aboutToAppear() {
    this.loadData();
  }

  onPageShow() {
    this.loadData();
  }

  async loadData() {
    this.isLoading = true;
    try {
      const userId =await UserSessionService.getCurrentUserId();
      if (!userId) {
        promptAction.showToast({ message: '请先登录' });
        return;
      }
      // Load Ledgers and Invitations in parallel
      // 并行加载账本和邀请
      const results = await Promise.all([
        SharedLedgerService.getUserLedgers(userId),
        SharedLedgerService.getUserInvitations(userId)
      ]);
      
      const ledgers = results[0];
      const invitations = results[1];
      
      this.ledgers = ledgers;
      this.invitations = invitations;
      
    } catch (error) {
      console.error('[SharedLedgerListPage] 加载失败:', error);
      promptAction.showToast({ message: '加载失败' });
    } finally {
      this.isLoading = false;
    }
  }

  async handleCreateLedger() {
    if (!this.newLedgerName.trim()) {
      promptAction.showToast({ message: '请输入账本名称' });
      return;
    }

    try {
      const userId =await UserSessionService.getCurrentUserId();
      if (!userId) return;
      const user =await UserSessionService.getCurrentSession(); // 获取用户名

      const params: CreateLedgerParams = {
        name: this.newLedgerName,
        type: this.newLedgerType as 'family' | 'roommate' | 'couple' | 'group' | 'trip' | 'project' | 'other',
        currency: 'CNY',
        color: '#2196F3', // 默认颜色
        ownerId: userId,
        ownerName: user ? user.username : 'Unknown'
      };

      await SharedLedgerService.createLedger(params);
      promptAction.showToast({ message: '创建成功' });
      this.loadData(); // 刷新列表
      
    } catch (error) {
      promptAction.showToast({ message: '创建失败: ' + error.message });
    }
  }

  async handleAccept(invitation: LedgerInvitation) {
    try {
      await SharedLedgerService.acceptInvitation(invitation.invitationId);
      promptAction.showToast({ message: '已加入账本' });
      this.loadData();
    } catch (error) {
      promptAction.showToast({ message: '操作失败: ' + error.message });
    }
  }

  async handleDecline(invitation: LedgerInvitation) {
     try {
      await SharedLedgerService.declineInvitation(invitation.invitationId);
      promptAction.showToast({ message: '已拒绝邀请' });
      this.loadData();
    } catch (error) {
      promptAction.showToast({ message: '操作失败: ' + error.message });
    }
  }

  build() {
    Stack() {
      Column() {
        // 头部
        Row() {
          Image($r('app.media.back')) // 假设有
            .width(24).height(24)
            .onClick(() => router.back())
            .margin({ right: 10 })
            
          Text('共享账本')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
          
          Blank()
          
          Text('新建') 
            .fontSize(16)
            .fontColor(Color.Blue)
            .onClick(() => {
              this.newLedgerName = '';
              this.newLedgerType = 'family';
              this.createDialogController.open();
            })
        }
        .width('100%')
        .padding(16)
        .backgroundColor(Color.White)

        if (this.isLoading) {
           Text('加载中...').margin({ top: 50 })
        } else {
           List({ space: 12 }) {
             // 1. 邀请部分
             if (this.invitations.length > 0) {
               ListItem() {
                 Text('待处理邀请')
                   .fontSize(14).fontColor(Color.Gray).margin({ bottom: 5, left: 5 })
               }
               ForEach(this.invitations, (invite: LedgerInvitation) => {
                 ListItem() {
                   this.InvitationCard(invite)
                 }
               })
               ListItem() {
                 Divider().strokeWidth(1).color('#E0E0E0').margin({top: 5, bottom: 5})
               }
             }

             // 2. 账本部分
             if (this.ledgers.length === 0 && this.invitations.length === 0) {
                 ListItem() {
                   Column() {
                     Text('📒') 
                       .fontSize(50).margin({ bottom: 20 })
                     Text('还没有共享账本\n快去创建一个吧')
                       .textAlign(TextAlign.Center)
                       .fontSize(16)
                       .fontColor(Color.Gray)
                     
                     Button('新建账本')
                       .margin({ top: 30 })
                       .onClick(() => {
                          this.newLedgerName = '';
                          this.createDialogController.open();
                       })
                   }
                   .width('100%')
                   .height(300)
                   .justifyContent(FlexAlign.Center)
                 }
             } else {
                 ForEach(this.ledgers, (item: SharedLedger) => {
                   ListItem() {
                     this.LedgerCard(item)
                   }
                   .onClick(() => {
                     // 跳转详情页，传递ID
                     router.pushUrl({
                       url: 'pages/SharedLedgerDetailPage',
                       params: { ledgerId: item.ledgerId }
                     });
                   })
                 })
             }
           }
           .width('100%')
           .layoutWeight(1)
           .padding(16)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F1F3F5')
    }
  }

  @Builder InvitationCard(invite: LedgerInvitation) {
    Row() {
       Column() {
         Text(`邀请加入: ${invite.ledgerName}`)
           .fontSize(16).fontWeight(FontWeight.Bold)
         Text(`邀请人: ${invite.inviterName}`)
           .fontSize(12).fontColor(Color.Gray).margin({top: 4})
       }
       .alignItems(HorizontalAlign.Start)
       
       Blank()
       
       Row() {
         Button('拒绝')
           .fontSize(12)
           .fontColor(Color.Red)
           .backgroundColor('#FFEBEE') // 浅红
           .height(28)
           .onClick(() => this.handleDecline(invite))
           .margin({ right: 8 })
           
         Button('接受')
           .fontSize(12)
           .fontColor(Color.Green)
           .backgroundColor('#E8F5E9') // 浅绿
           .height(28)
           .onClick(() => this.handleAccept(invite))
       }
    }
    .width('100%')
    .padding(12)
    .backgroundColor(Color.White)
    .borderRadius(10)
    .shadow({ radius: 2, color: '#E0E0E0', offsetY: 1 })
    .border({ width: 1, color: '#FF9800', style: BorderStyle.Solid }) // 橙色边框用于引起注意
  }

  @Builder LedgerCard(ledger: SharedLedger) {
    Row() {
      // 图标占位符
      Column() {
        Text(ledger.name.substring(0, 1))
          .fontSize(20)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Bold)
      }
      .width(50)
      .height(50)
      .borderRadius(25)
      .backgroundColor(ledger.color || '#2196F3')
      .justifyContent(FlexAlign.Center)
      .margin({ right: 15 })

      Column() {
        Text(ledger.name)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 5 })
        
        Row() {
           Text(this.getTypeLabel(ledger.type))
             .fontSize(12)
             .fontColor(Color.Gray)
             .backgroundColor('#F0F0F0')
             .padding({ left: 6, right: 6, top: 2, bottom: 2 })
             .borderRadius(4)
             .margin({ right: 10 })

           Text(`${ledger.memberCount} 成员`)
             .fontSize(12)
             .fontColor(Color.Gray)
        }
      }
      .alignItems(HorizontalAlign.Start)
      
      Blank()
      
      // 箭头
      Text('>')
        .fontSize(18)
        .fontColor(Color.Gray)
    }
    .width('100%')
    .padding(15)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .shadow({ radius: 2, color: '#E0E0E0', offsetY: 1 })
  }

  getTypeLabel(type: string): string {
    const map: Record<string, string> = {
      'family': '家庭', 'couple': '情侣', 'roommate': '室友', 
      'trip': '旅行', 'team': '团队', 'project': '项目'
    };
    return map[type] || '其他';
  }
}

// 简单的 SelectOption 接口
interface SelectOption {
  value: string;
  label: string;
}

@CustomDialog
struct CreateLedgerDialog {
  controller: CustomDialogController;
  @Link name: string;
  @Link type: string;
  onConfirm: () => void = () => {};
  
  private ledgerTypes: SelectOption[] = [
    { value: 'family', label: '家庭' },
    { value: 'couple', label: '情侣' },
    { value: 'roommate', label: '室友' },
    { value: 'trip', label: '旅行' },
    { value: 'team', label: '团队' },
    { value: 'project', label: '项目' },
    { value: 'other', label: '其他' }
  ];

  build() {
    Column() {
      Text('创建共享账本')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20, top: 10 })

      TextInput({ placeholder: '给账本起个名字', text: this.name })
        .onChange((val) => this.name = val)
        .margin({ bottom: 15 })
        .width('90%')
      
      Text('选择类型')
        .fontSize(14)
        .fontColor(Color.Gray)
        .width('90%')
        .margin({ bottom: 5 })

      // 简单的类型选择 - 使用 Flex 换行
      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
        ForEach(this.ledgerTypes, (item: SelectOption) => {
          Text(item.label)
            .fontSize(14)
            .fontColor(this.type === item.value ? Color.White : '#333')
            .backgroundColor(this.type === item.value ? '#2196F3' : '#F0F0F0')
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .borderRadius(15)
            .margin({ right: 8, bottom: 8 })
            .onClick(() => {
              this.type = item.value;
            })
        })
      }
      .width('90%')
      .margin({ bottom: 20 })

      Row() {
        Button('取消')
          .backgroundColor('#F0F0F0')
          .fontColor('#333')
          .width('40%')
          .onClick(() => this.controller.close())
        
        Button('创建')
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
    .borderRadius({ topLeft: 16, topRight: 16 })
    .width('100%')
    .padding(20)
  }
}
