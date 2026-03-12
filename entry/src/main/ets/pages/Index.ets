import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { AccountDAO } from '../dao/AccountDAO';
import { Bill } from '../model/Bill';
import { BillDAO, DateRangeFilter } from '../dao/BillDAO';
import hilog from '@ohos.hilog';
import { BusinessError } from '@ohos.base';
import { Category } from '../model';
import { CategoryDAO } from '../dao/CategoryDAO';
import { BreakPointType } from '../common/config/BreakpointSystem';
import { MinePage } from './MinePage';
import { StatisticsPage } from './StatisticsPage';
import { UserSessionService } from '../service/UserSessionService';
import { AppTheme } from '../common/config/AppTheme';
import { SharedLedgerService } from '../service/SharedLedgerService';
import { LedgerInvitation } from '../model/SharedLedger';
import { BillDetailDialog } from '../components/BillDetailDialog';

interface DateFilter {
  start: string;
  end: string;
}

class SelectOption {
  value: string;

  constructor(value: string) {
    this.value = value;
  }
}

class CategoryOption {
  value: ResourceStr = '';

  constructor(value: ResourceStr) {
    this.value = value;
  }
}

const HILOG_DOMAIN = 0x0001
const LOG_TAG = 'Index'

@Entry
@Component
struct Index {
  @State transactions: Array<Bill> = [];
  @State isLoading: boolean = true;
  @State allCategories: Array<Category> = [];
  @State selectedDate: Date = new Date();
  @State selectedCategoryId: number = 0;
  @State statRefreshTrigger: number = 0;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'md';
  
  // 邀请状态
  @State pendingInvitations: LedgerInvitation[] = [];
  
  // 弹窗控制器
  invitationController: CustomDialogController = new CustomDialogController({
    builder: InvitationProcessingDialog({
      invitations: $pendingInvitations,
      onHandle: (invite, action) => this.handleInvitation(invite, action)
    }),
    autoCancel: false,
    customStyle: true
  });

  @State currentSelectedBill: Bill = new Bill();
  
  detailDialogController: CustomDialogController = new CustomDialogController({
    builder: BillDetailDialog({
      bill: this.currentSelectedBill,
      categoryName: (this.allCategories.find(c => c.categoryId === this.currentSelectedBill.categoryId)?.name as string) || '',
      onDelete: () => {
        AlertDialog.show({
          title: '确认删除',
          message: '删除后金额将退回账户，确定要删除这条记录吗？',
          primaryButton: {
            value: '取消',
            action: () => {}
          },
          secondaryButton: {
            value: '删除',
            fontColor: Color.Red,
            action: () => {
              this.deleteBill(this.currentSelectedBill);
            }
          }
        });
      },
      onEdit: () => {
        promptAction.showToast({ message: '编辑功能暂未实现' });
      }
    }),
    alignment: DialogAlignment.Center,
    customStyle: true,
    autoCancel: true
  });

  private listPadding = new BreakPointType({ xs: 8, sm: 10, md: 12, lg: 16, xl: 20, xxl: 24 });
  private buttonWidth = new BreakPointType({ xs: '90%', sm: '85%', md: '80%', lg: '70%', xl: '60%', xxl: '50%' });
  private titleFontSize = new BreakPointType({ xs: 14, sm: 15, md: 16, lg: 18, xl: 20, xxl: 22 });
  private amountFontSize = new BreakPointType({ xs: 16, sm: 17, md: 18, lg: 20, xl: 22, xxl: 24 });

  async onPageShow(): Promise<void> {
    hilog.info(HILOG_DOMAIN, LOG_TAG, 'onPageShow triggered');

    if (!UserSessionService.isLoggedIn()) {
      hilog.info(HILOG_DOMAIN, LOG_TAG, 'User not logged in, redirecting to login');
      router.replaceUrl({ url: 'pages/LoginPage' });
      return;
    }

    await this.loadFilterData();
    await this.loadBills();
    
    // 检查邀请
    this.checkInvitations();
  }

  async checkInvitations(): Promise<void> {
    const userId = await UserSessionService.getCurrentUserId();
    if (userId) {
       const invites = await SharedLedgerService.getUserInvitations(userId);
       if (invites.length > 0) {
          this.pendingInvitations = invites;
          this.invitationController.open();
       }
    }
  }

  async handleInvitation(invite: LedgerInvitation, action: 'accept' | 'decline'): Promise<void> {
    try {
      if (action === 'accept') {
        await SharedLedgerService.acceptInvitation(invite.invitationId);
        promptAction.showToast({ message: '已加入账本' });
      } else {
        await SharedLedgerService.declineInvitation(invite.invitationId);
        promptAction.showToast({ message: '已拒绝邀请' });
      }
      this.pendingInvitations = this.pendingInvitations.filter(i => i.invitationId !== invite.invitationId);
      
      if (this.pendingInvitations.length === 0) {
        this.invitationController.close();
      }
    } catch (error) {
       promptAction.showToast({ message: '操作失败' });
    }
  }

  async loadBills(): Promise<void> {
    this.isLoading = true;
    try {
      const dateRangeObj = this.getDateRange(this.selectedDate);
      const dateRange = dateRangeObj as DateRangeFilter;
      hilog.info(HILOG_DOMAIN, LOG_TAG, `加载账单: DateRange=${JSON.stringify(dateRange)}, CategoryID=${this.selectedCategoryId}`);

      const userId = await UserSessionService.getCurrentUserId();
      if (!userId) { 
        hilog.warn(HILOG_DOMAIN, LOG_TAG, 'loadBills skipped: No user logged in');
        return; 
      }
      const billsFromDB = await BillDAO.getBillsByFilters(
        userId,
        dateRange,
        this.selectedCategoryId
      );
      this.transactions = billsFromDB;
      this.isLoading = false;
    } catch (error) {
        hilog.error(0x0000, 'Index','加载账单失败: %{public}s', JSON.stringify(error));
    }  finally{
      this.isLoading = false;
    }
  }

  async loadFilterData(): Promise<void> {
    try {
      const userId = await UserSessionService.getCurrentUserId();
      if (!userId) return;
      const categories: Category[]= await CategoryDAO.getAll(userId);
      const allOption = new Category();
      allOption.categoryId = 0;
      allOption.name = '所有分类';
      this.allCategories = [allOption, ...categories];
    } catch (error) {
      hilog.error(HILOG_DOMAIN, LOG_TAG, '加载分类列表失败: %{public}s', JSON.stringify(error));
    }
  }

  private getDateRange(date: Date): DateFilter{
    const year = date.getFullYear();
    const month = date.getMonth() + 1;
    const startDate = `${year}-${month.toString().padStart(2, '0')}-01`;
    const lastDay = new Date(year, month, 0).getDate();
    const endDate = `${year}-${month.toString().padStart(2, '0')}-${lastDay.toString().padStart(2, '0')}`;
    return { start: startDate, end: endDate };
  }

  showMonthPicker() {
    DatePickerDialog.show({
      selected: this.selectedDate,
      onAccept: (value: DatePickerResult) => {
        const year = value.year ?? new Date().getFullYear();
        const month = value.month ?? new Date().getMonth();
        this.selectedDate = new Date(year, month);
        this.loadBills();
      }
    })
  }

  async deleteBill(bill: Bill): Promise<void> {
    try {
      const userId = await UserSessionService.getCurrentUserId();
      if (!userId) return;

      const account = await AccountDAO.getById(bill.accountId);
      if (account) {
        if (bill.type === 'expense') {
          account.balance += bill.amount;
        } else {
          account.balance -= bill.amount;
        }
        await AccountDAO.update(account);
      }

      await BillDAO.delete(bill.billId, userId);

      this.transactions = this.transactions.filter(item => item.billId !== bill.billId);
      
      this.statRefreshTrigger++;

      promptAction.showToast({ message: '删除成功，余额已还原' });

    } catch (error) {
      hilog.error(HILOG_DOMAIN, LOG_TAG, '删除账单失败: %{public}s', JSON.stringify(error));
      promptAction.showToast({ message: '删除失败，请重试' });
    }
  }

  @Builder
  DeleteButton(bill: Bill) {
    Button({ type: ButtonType.Normal }) {
      Image($r('app.media.ic_public_delete'))
        .width(20)
        .height(20)
        .fillColor(Color.White)
        .objectFit(ImageFit.Contain)
    }
    .width(60)
    .height('100%')
    .backgroundColor(Color.Red)
    .onClick(() => {
        AlertDialog.show({
          title: '确认删除',
          message: '删除后金额将退回账户，确定要删除这条记录吗？',
          primaryButton: {
            value: '取消',
            action: () => {}
          },
          secondaryButton: {
            value: '删除',
            fontColor: Color.Red,
            action: () => {
              this.deleteBill(bill);
            }
          }
        })
    })
  }

  @State currentIndex: number = 0;
  private controller: TabsController = new TabsController();

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      // 1. 业务内容区
      Tabs({ barPosition: BarPosition.End, controller: this.controller }) {
        TabContent() {
          this.BillListContent()
        }
        TabContent() {
          StatisticsPage({ refreshTrigger: this.statRefreshTrigger })
        }
        TabContent() {
          MinePage()
        }
      }
      .barHeight(0) // 完全隐藏系统自带的底部 Tab 栏
      .layoutWeight(1)
      .onChange((index: number) => {
        this.currentIndex = index;
        if (index === 1) {
           this.statRefreshTrigger++;
        }
      })

      // 2. 自定义绿色底部栏
      Row() {
        Column() {
          Image(this.currentIndex === 1 ? $r('app.media.ic_pie_chart_filled') : $r('app.media.ic_pie_chart_linear'))
            .width(24).height(24)
            .fillColor(this.currentIndex === 1 ? '#7FB069' : '#999999')
            .objectFit(ImageFit.Contain)
          Text('统计')
            .fontColor(this.currentIndex === 1 ? '#7FB069' : '#999999')
            .fontSize(10)
            .margin({ top: 4 })
        }
        .width(60)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.currentIndex = 1;
          this.controller.changeIndex(1);
        })

        Blank()

        Column() {
          Image(this.currentIndex === 2 ? $r('app.media.ic_user_filled') : $r('app.media.ic_user_linear'))
            .width(24).height(24)
            .fillColor(this.currentIndex === 2 ? '#7FB069' : '#999999')
            .objectFit(ImageFit.Contain)
          Text('我的')
            .fontColor(this.currentIndex === 2 ? '#7FB069' : '#999999')
            .fontSize(10)
            .margin({ top: 4 })
        }
        .width(60)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.currentIndex = 2;
          this.controller.changeIndex(2);
        })
      }
      .width('100%')
      .height(60)
      .backgroundColor('#7FB069')
      .justifyContent(FlexAlign.SpaceBetween)
      .padding({ left: 30, right: 30 })

      // 3. 居中巨型 FAB
      Button() {
        Text('+')
          .fontSize('40fp')
          .fontColor(Color.White)
      }
      .type(ButtonType.Circle)
      .width('64vp')
      .height('64vp')
      .backgroundColor('#FF7F50')
      .margin({ bottom: 20 })
      .zIndex(10)
      .shadow({ radius: 12, color: 'rgba(255, 127, 80, 0.4)', offsetY: 4 })
      .onClick(() => {
        router.pushUrl({ url: 'pages/AddBill' })
      })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  BillListContent() {
    Navigation() {
      Column() {
        // 沉浸式首页结构背景直接铺满
        Scroll() {
          Column() {
            // 1. 顶部自定义导航与日期 (Top Header) - 避让沉浸式状态栏
            Column() {
              // 第一行：猪猪头像、默认账本、搜索
              Row() {
                Image($r('app.media.ic_user_avatar_linear'))
                  .width(32).height(32).fillColor('#388E3C').objectFit(ImageFit.Contain)
                Text('默认账本 ▼')
                  .fontSize('20fp')
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#388E3C')
                Image($r('app.media.ic_search_linear'))
                  .width(24).height(24).fillColor('#388E3C').objectFit(ImageFit.Contain)
              }
              .width('100%')
              .justifyContent(FlexAlign.SpaceBetween)
              .padding(16)

              // 第二行：带箭头的日期选择、隐显图标
              Row({ space: 8 }) {
                Text('<').fontSize(16).fontColor('#388E3C').fontWeight(FontWeight.Bold)
                Text(this.formatDateToYearMonth(this.selectedDate).replace('-', '年') + '月明细')
                  .fontSize(16)
                  .fontColor('#388E3C')
                  .fontWeight(FontWeight.Medium)
                  .onClick(() => {
                    this.showMonthPicker();
                  })
                Text('>').fontSize(16).fontColor('#388E3C').fontWeight(FontWeight.Bold)
                Text(' 👁️').fontSize(16) // 隐显图标
              }
              .margin({ top: 10, bottom: 20 })
              .justifyContent(FlexAlign.Center)

              // 第三行：核心财务数据
              Row() {
                Column() {
                  Text('收入').fontSize('14fp').fontColor('#666666').margin({ bottom: 8 })
                  Text(this.transactions.reduce((acc, item) => item.type === 'income' ? acc + item.amount : acc, 0).toFixed(2))
                    .fontSize('24fp').fontWeight(FontWeight.Bold).fontColor('#388E3C')
                }.layoutWeight(1).alignItems(HorizontalAlign.Center)

                Column() {
                  Text('支出').fontSize('14fp').fontColor('#666666').margin({ bottom: 8 })
                  Text(this.transactions.reduce((acc, item) => item.type === 'expense' ? acc + item.amount : acc, 0).toFixed(2))
                    .fontSize('24fp').fontWeight(FontWeight.Bold).fontColor('#388E3C')
                }.layoutWeight(1).alignItems(HorizontalAlign.Center)

                Column() {
                  Text('结余').fontSize('14fp').fontColor('#666666').margin({ bottom: 8 })
                  Text(this.transactions.reduce((acc, item) => item.type === 'income' ? acc + item.amount : acc - item.amount, 0).toFixed(2))
                    .fontSize('24fp').fontWeight(FontWeight.Bold).fontColor('#388E3C')
                }.layoutWeight(1).alignItems(HorizontalAlign.Center)
              }
              .width('100%')
              .justifyContent(FlexAlign.SpaceAround)
              .margin({ bottom: 40 })
            }
            .width('100%')
            .padding({ top: 38 })

            // 2. 悬浮胶囊工具栏 (Floating Pill Bar)
            Row() {
              Column() { Image($r('app.media.ic_book_linear')).width(28).height(28).fillColor('#7FB069').objectFit(ImageFit.Contain).margin({bottom: 4}); Text('记账').fontSize('12fp').fontColor('#333') }.onClick(() => router.pushUrl({ url: 'pages/AddBill' }))
              Column() { Image($r('app.media.ic_ai_stars_linear')).width(28).height(28).fillColor('#7FB069').objectFit(ImageFit.Contain).margin({bottom: 4}); Text('AI记账').fontSize('12fp').fontColor('#333') }.onClick(() => promptAction.showToast({ message: 'AI记账功能开发中' }))
              Column() { Image($r('app.media.ic_calendar_linear')).width(28).height(28).fillColor('#7FB069').objectFit(ImageFit.Contain).margin({bottom: 4}); Text('日历').fontSize('12fp').fontColor('#333') }.onClick(() => router.pushUrl({ url: 'pages/CalendarView' }))
              Column() { Image($r('app.media.ic_wallet_linear')).width(28).height(28).fillColor('#7FB069').objectFit(ImageFit.Contain).margin({bottom: 4}); Text('资产').fontSize('12fp').fontColor('#333') }.onClick(() => promptAction.showToast({ message: '资产管理功能开发中' }))
              Column() { Image($r('app.media.ic_chart_linear')).width(28).height(28).fillColor('#7FB069').objectFit(ImageFit.Contain).margin({bottom: 4}); Text('预算').fontSize('12fp').fontColor('#333') }.onClick(() => router.pushUrl({ url: 'pages/BudgetManagement' }))
            }
            .width('calc(100% - 32vp)')
            .margin({ top: -20, left: 16, right: 16 })
            .backgroundColor('#FFFFFF')
            .borderRadius(24)
            .padding({ left: 16, right: 16, top: 12, bottom: 12 })
            .shadow({ radius: 12, color: 'rgba(0,0,0,0.05)', offsetY: 4 })
            .justifyContent(FlexAlign.SpaceBetween)

            // 3. 马克笔高亮标题与筛选按钮
            Row() {
              Stack({ alignContent: Alignment.Bottom }) {
                Row().width('100%').height(10).backgroundColor('#FFF68F').margin({ bottom: 2 })
                Text('收支记录').fontSize('18fp').fontWeight(FontWeight.Bold)
              }.width(76)

              Row() {
                Text('筛选 ▼').fontSize('12fp').fontColor('#388E3C')
              }
              .backgroundColor('#E8F5E9')
              .borderRadius(16)
              .padding({ left: 12, right: 12, top: 4, bottom: 4 })
            }
            .width('100%')
            .padding(16)
            .justifyContent(FlexAlign.SpaceBetween)

            // 4. 账单明细列表
            if (this.transactions.length === 0) {
              Column() {
                Image($r('app.media.ic_empty_book'))
                  .width(120).height(120).opacity(0.4).objectFit(ImageFit.Contain).margin({ bottom: 10, top: 40 })
                Text('哎呀，当前时间没有记录呢~').fontColor('#999999').fontSize(14)
              }.width('100%').alignItems(HorizontalAlign.Center)
            } else {
              List({ space: 10 }) {
                ForEach(this.transactions, (item: Bill) => {
                  ListItem() {
                    this.TransactionRow(item)
                  }
                  .onClick(() => {
                    this.currentSelectedBill = item;
                    this.detailDialogController.open();
                  })
                  .swipeAction({ end: this.DeleteButton(item) })
                  .backgroundColor('#FFFFFF')
                  .borderRadius(12)
                }, (item: Bill, index: number) => index + JSON.stringify(item))
              }
              .padding({ left: 16, right: 16, bottom: 120 }) // 避让底部空间
            }
          }
        }
        .width('100%')
        .height('100%')
      }
      .width('100%')
      .height('100%')
      .linearGradient({ direction: GradientDirection.Bottom, colors: [['#E0F2E9', 0.0], ['#F4F6F9', 0.4], ['#F4F6F9', 1.0]] })
    }
    .width('100%')
    .height('100%')
    .titleMode(NavigationTitleMode.Mini)
    .hideTitleBar(true)
    .hideBackButton(true)
  }

  pageTransition() {
    PageTransitionEnter({ duration: 200 })
      .slide(SlideEffect.Right)
    PageTransitionExit({ duration: 200 })
      .slide(SlideEffect.Left)
  }

  @Builder
  TransactionRow(item: Bill) {
    Row() {
      /*
      Image(item.type=='expense'?$r('app.media.ic_expense_default'):$r('app.media.ic_income_default'))
        .width(40)
        .height(40)
        .margin({right:10})
        .objectFit(ImageFit.Contain)
      */
      Column() {
        Text(this.allCategories.find(c => c.categoryId === item.categoryId)?.name || (item.type === 'expense' ? '支出' : '收入'))
          .fontSize(this.titleFontSize.getValue(this.currentBreakpoint) as number)
          .fontWeight(FontWeight.Bold)
        
        Row() {
           Text(item.transactionDate.replace('T', ' ').substring(5, 16))
            .fontSize(12)
            .fontColor(Color.Gray)
            .margin({ right: 8 })
           if (item.note) {
             Text(item.note)
               .fontSize((this.titleFontSize.getValue(this.currentBreakpoint) as number) - 2)
               .fontColor(Color.Gray)
           }
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text(item.type === 'expense' ? `-${item.amount.toFixed(2)}` : `+${item.amount.toFixed(2)}`)
        .fontSize(this.amountFontSize.getValue(this.currentBreakpoint) as number)
        .fontWeight(FontWeight.Bold)
        .fontColor(item.type === 'expense' ? Color.Red : Color.Green)
    }
    .width('100%')
    .padding(12)
    .backgroundColor(Color.White)
    .borderRadius(8)
    }
  formatDateToYearMonth(date: Date): string {
    const year = date.getFullYear();
    const month = (date.getMonth() + 1).toString().padStart(2, '0');
    return `${year}-${month}`;
  }

}

@CustomDialog
struct InvitationProcessingDialog {
  controller: CustomDialogController;
  @Link invitations: LedgerInvitation[];
  onHandle: (invite: LedgerInvitation, action: 'accept' | 'decline') => void = () => {};

  build() {
    Column() {
      Text('收到新的账本邀请!')
        .fontSize(18).fontWeight(FontWeight.Bold).margin({ top: 20, bottom: 10 })
      
      List() {
        ForEach(this.invitations, (invite: LedgerInvitation) => {
          ListItem() {
             Column() {
               Text(`邀请人: ${invite.inviterName}`)
                 .fontSize(14).fontColor(Color.Gray)
               Text(`账本: ${invite.ledgerName}`)
                 .fontSize(16).fontWeight(FontWeight.Medium).margin({top: 4, bottom: 8})
               
               Row() {
                 Button('拒绝')
                   .fontColor(Color.Red).backgroundColor('#FFEBEE')
                   .height(30).fontSize(12)
                   .onClick(() => this.onHandle(invite, 'decline'))
                   .margin({ right: 10 })
                   
                 Button('接受')
                   .fontColor(Color.Green).backgroundColor('#E8F5E9')
                   .height(30).fontSize(12)
                   .onClick(() => this.onHandle(invite, 'accept'))
               }
               .width('100%').justifyContent(FlexAlign.End)
             }
             .width('100%')
             .padding(10)
             .backgroundColor('#F5F5F5')
             .borderRadius(8)
             .margin({ bottom: 10 })
          }
        })
      }
      .width('100%')
      .constraintSize({ maxHeight: 300 })
      .padding(10)

      Button('关闭')
        .width('40%').margin({ top: 10, bottom: 20 })
        .backgroundColor(Color.Gray)
        .onClick(() => this.controller.close())
    }
    .width('80%')
    .backgroundColor(Color.White)
    .borderRadius(16)
  }
}
