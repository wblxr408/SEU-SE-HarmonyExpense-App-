import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { AccountDAO } from '../dao/AccountDAO';
import { Bill } from '../model/Bill';
import { BillDAO, DateRangeFilter } from '../dao/BillDAO';
import hilog from '@ohos.hilog';
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
  @State pendingInvitations: LedgerInvitation[] = [];
  invitationController: CustomDialogController = new CustomDialogController({
    builder: InvitationProcessingDialog({
      invitations: $pendingInvitations,
      onHandle: (invite: LedgerInvitation, action: 'accept' | 'decline') => this.handleInvitation(invite, action)
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
          title: '\u786e\u8ba4\u5220\u9664',
          message: '\u5220\u9664\u540e\u91d1\u989d\u5c06\u9000\u56de\u8d26\u6237\uff0c\u786e\u5b9a\u8981\u5220\u9664\u8fd9\u6761\u8bb0\u5f55\u5417\uff1f',
          primaryButton: {
            value: '\u53d6\u6d88',
            action: () => {}
          },
          secondaryButton: {
            value: '\u5220\u9664',
            fontColor: AppTheme.TextMain,
            action: () => {
              this.deleteBill(this.currentSelectedBill);
            }
          }
        });
      },
      onEdit: () => {
        promptAction.showToast({ message: '\u7f16\u8f91\u529f\u80fd\u6682\u672a\u5b9e\u73b0' });
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
        promptAction.showToast({ message: '\u5df2\u52a0\u5165\u8d26\u672c' });
      } else {
        await SharedLedgerService.declineInvitation(invite.invitationId);
        promptAction.showToast({ message: '\u5df2\u62d2\u7edd\u9080\u8bf7' });
      }
      this.pendingInvitations = this.pendingInvitations.filter(i => i.invitationId !== invite.invitationId);
      
      if (this.pendingInvitations.length === 0) {
        this.invitationController.close();
      }
    } catch (error) {
       promptAction.showToast({ message: '\u64cd\u4f5c\u5931\u8d25' });
    }
  }

  async loadBills(): Promise<void> {
    this.isLoading = true;
    try {
      const dateRangeObj = this.getDateRange(this.selectedDate);
      const dateRange = dateRangeObj as DateRangeFilter;
      hilog.info(HILOG_DOMAIN, LOG_TAG, `\u52a0\u8f7d\u8d26\u5355: DateRange=${JSON.stringify(dateRange)}, CategoryID=${this.selectedCategoryId}`);

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
        hilog.error(0x0000, 'Index', '\u52a0\u8f7d\u8d26\u5355\u5931\u8d25: %{public}s', JSON.stringify(error));
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
      allOption.name = '\u6240\u6709\u5206\u7c7b';
      this.allCategories = [allOption, ...categories];
    } catch (error) {
      hilog.error(HILOG_DOMAIN, LOG_TAG, '\u52a0\u8f7d\u5206\u7c7b\u5217\u8868\u5931\u8d25: %{public}s', JSON.stringify(error));
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

  showMonthPicker(): void {
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

      promptAction.showToast({ message: '\u5220\u9664\u6210\u529f\uff0c\u4f59\u989d\u5df2\u8fd8\u539f' });

    } catch (error) {
      hilog.error(HILOG_DOMAIN, LOG_TAG, '\u5220\u9664\u8d26\u5355\u5931\u8d25: %{public}s', JSON.stringify(error));
      promptAction.showToast({ message: '\u5220\u9664\u5931\u8d25\uff0c\u8bf7\u91cd\u8bd5' });
    }
  }

  @Builder
  DeleteButton(bill: Bill): void {
    Button({ type: ButtonType.Normal }) {
      Image($r('app.media.ic_public_delete'))
        .width(20)
        .height(20)
        .fillColor(Color.White)
        .objectFit(ImageFit.Contain)
    }
    .width(60)
    .height('100%')
    .backgroundColor(AppTheme.HeroBg)
    .onClick(() => {
        AlertDialog.show({
          title: '\u786e\u8ba4\u5220\u9664',
          message: '\u5220\u9664\u540e\u91d1\u989d\u5c06\u9000\u56de\u8d26\u6237\uff0c\u786e\u5b9a\u8981\u5220\u9664\u8fd9\u6761\u8bb0\u5f55\u5417\uff1f',
          primaryButton: {
            value: '\u53d6\u6d88',
            action: () => {}
          },
          secondaryButton: {
            value: '\u5220\u9664',
            fontColor: AppTheme.TextMain,
            action: () => {
              this.deleteBill(bill);
            }
          }
        })
    })
  }

  @State currentIndex: number = 0;
  private controller: TabsController = new TabsController();

  build(): void {
    Stack({ alignContent: Alignment.Bottom }) {
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
      .barHeight(0) 
      .layoutWeight(1)
      .onChange((index: number) => {
        this.currentIndex = index;
        if (index === 1) {
           this.statRefreshTrigger++;
        }
      })
      Row() {
        Column() {
          Image(this.currentIndex === 1 ? $r('app.media.ic_pie_chart_filled') : $r('app.media.ic_chart_linear'))
            .width(24).height(24)
            .fillColor(this.currentIndex === 1 ? AppTheme.TextMain : AppTheme.TextSub)
            .objectFit(ImageFit.Contain)
          Text('\u7edf\u8ba1')
            .fontColor(this.currentIndex === 1 ? AppTheme.TextMain : AppTheme.TextSub)
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
          Image(this.currentIndex === 2 ? $r('app.media.ic_user_avatar_glass') : $r('app.media.ic_user_avatar_linear'))
            .width(24).height(24)
            .fillColor(this.currentIndex === 2 ? AppTheme.TextMain : AppTheme.TextSub)
            .objectFit(ImageFit.Contain)
          Text('\u6211\u7684')
            .fontColor(this.currentIndex === 2 ? AppTheme.TextMain : AppTheme.TextSub)
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
      .height(72)
      .backgroundColor(AppTheme.GlassBackground)
      .backdropBlur(30)
      .justifyContent(FlexAlign.SpaceBetween)
      .padding({ left: 30, right: 30, bottom: 8 })
      Button() {
        Text('+')
          .fontSize('40fp')
          .fontColor(AppTheme.TextWhite)
      }
      .type(ButtonType.Circle)
      .width('64vp')
      .height('64vp')
      .backgroundColor(AppTheme.HeroBg)
      .margin({ bottom: 20 })
      .zIndex(10)
      .shadow(AppTheme.FabShadow)
      .onClick(() => {
        router.pushUrl({ url: 'pages/AddBill' })
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppTheme.Background)
  }

  @Builder
  BillListContent(): void {
    Navigation() {
      Column() {
        Scroll() {
          Column() {
            Column() {
              Row() {
                Image($r('app.media.ic_user_avatar_linear'))
                  .width(32).height(32).fillColor(AppTheme.TextMain).objectFit(ImageFit.Contain)
                Text('\u9ed8\u8ba4\u8d26\u672c \u25bc')
                  .fontSize('20fp')
                  .fontWeight(FontWeight.Bold)
                  .fontColor(AppTheme.TextMain)
                Image($r('app.media.ic_search_linear'))
                  .width(24).height(24).fillColor(AppTheme.TextMain).objectFit(ImageFit.Contain)
              }
              .width('100%')
              .justifyContent(FlexAlign.SpaceBetween)
              .padding(20)
              Row({ space: 8 }) {
                Text('<').fontSize(16).fontColor(AppTheme.TextMain).fontWeight(FontWeight.Bold)
                Text(this.formatDateToYearMonth(this.selectedDate).replace('-', '\u5e74') + '\u6708\u660e\u7ec6')
                  .fontSize(16)
                  .fontColor(AppTheme.TextMain)
                  .fontWeight(FontWeight.Medium)
                  .onClick(() => {
                    this.showMonthPicker();
                  })
                Text('>').fontSize(16).fontColor(AppTheme.TextMain).fontWeight(FontWeight.Bold)
                Text(' \uD83D\uDC41\uFE0F').fontSize(16)
              }
              .margin({ top: 10, bottom: 20 })
              .justifyContent(FlexAlign.Center)
              Row() {
                Column() {
                  Text('\u6536\u5165').fontSize('14fp').fontColor(AppTheme.TextWhite).opacity(0.85).margin({ bottom: 8 })
                  Text(this.transactions.reduce((acc, item) => item.type === 'income' ? acc + item.amount : acc, 0).toFixed(2))
                    .fontSize('26fp').fontWeight(FontWeight.Bolder).fontColor(AppTheme.TextWhite)
                }.layoutWeight(1).alignItems(HorizontalAlign.Center)

                Column() {
                  Text('\u652f\u51fa').fontSize('14fp').fontColor(AppTheme.TextWhite).opacity(0.75).margin({ bottom: 8 })
                  Text(this.transactions.reduce((acc, item) => item.type === 'expense' ? acc + item.amount : acc, 0).toFixed(2))
                    .fontSize('26fp').fontWeight(FontWeight.Medium).fontColor(AppTheme.TextWhite).opacity(0.72)
                }.layoutWeight(1).alignItems(HorizontalAlign.Center)

                Column() {
                  Text('\u7ed3\u4f59').fontSize('14fp').fontColor(AppTheme.TextWhite).opacity(0.85).margin({ bottom: 8 })
                  Text(this.transactions.reduce((acc, item) => item.type === 'income' ? acc + item.amount : acc - item.amount, 0).toFixed(2))
                    .fontSize('28fp').fontWeight(FontWeight.Bolder).fontColor(AppTheme.TextWhite)
                }.layoutWeight(1).alignItems(HorizontalAlign.Center)
              }
              .width('100%')
              .justifyContent(FlexAlign.SpaceAround)
              .margin({ bottom: 12 })
              .padding(24)
              .backgroundColor(AppTheme.HeroBg)
              .borderRadius(24)
              .shadow(AppTheme.CardShadow)
            }
            .width('100%')
            .padding({ top: 38, bottom: 20 })
            .margin({ left: 16, right: 16 })
            .backgroundColor(AppTheme.GlassBackground)
            .backdropBlur(30)
            .borderRadius(28)
            Row() {
              Column() { Image($r('app.media.ic_book_linear')).width(28).height(28).fillColor(AppTheme.TextMain).objectFit(ImageFit.Contain).margin({bottom: 4}); Text('\u8bb0\u8d26').fontSize('12fp').fontColor(AppTheme.TextMain) }.onClick(() => router.pushUrl({ url: 'pages/AddBill' }))
              Column() { Image($r('app.media.ic_ai_brain_linear')).width(28).height(28).fillColor(AppTheme.TextMain).objectFit(ImageFit.Contain).margin({bottom: 4}); Text('AI\u8bb0\u8d26').fontSize('12fp').fontColor(AppTheme.TextMain) }.onClick(() => promptAction.showToast({ message: 'AI\u8bb0\u8d26\u529f\u80fd\u5f00\u53d1\u4e2d' }))
              Column() { Image($r('app.media.ic_calendar_linear')).width(28).height(28).fillColor(AppTheme.TextMain).objectFit(ImageFit.Contain).margin({bottom: 4}); Text('\u65e5\u5386').fontSize('12fp').fontColor(AppTheme.TextMain) }.onClick(() => router.pushUrl({ url: 'pages/CalendarView' }))
              Column() { Image($r('app.media.ic_wallet_linear')).width(28).height(28).fillColor(AppTheme.TextMain).objectFit(ImageFit.Contain).margin({bottom: 4}); Text('\u8d44\u4ea7').fontSize('12fp').fontColor(AppTheme.TextMain) }.onClick(() => promptAction.showToast({ message: '\u8d44\u4ea7\u7ba1\u7406\u529f\u80fd\u5f00\u53d1\u4e2d' }))
              Column() { Image($r('app.media.ic_chart_linear')).width(28).height(28).fillColor(AppTheme.TextMain).objectFit(ImageFit.Contain).margin({bottom: 4}); Text('\u9884\u7b97').fontSize('12fp').fontColor(AppTheme.TextMain) }.onClick(() => router.pushUrl({ url: 'pages/BudgetManagement' }))
            }
            .width('calc(100% - 32vp)')
            .margin({ top: -20, left: 16, right: 16 })
            .backgroundColor(AppTheme.CardBg)
            .borderRadius(24)
            .padding({ left: 20, right: 20, top: 20, bottom: 20 })
            .shadow(AppTheme.CardShadow)
            .justifyContent(FlexAlign.SpaceBetween)
            Row() {
              Stack({ alignContent: Alignment.Bottom }) {
                Text('\u6536\u652f\u8bb0\u5f55').fontSize('18fp').fontWeight(FontWeight.Bold).fontColor(AppTheme.TextMain)
              }.width(76)

              Row() {
                Text('\u7b5b\u9009 \u25bc').fontSize('12fp').fontColor(AppTheme.TextMain)
              }
              .backgroundColor(AppTheme.CardBg)
              .borderRadius(16)
              .padding({ left: 12, right: 12, top: 4, bottom: 4 })
              .border({ width: 0.5, color: AppTheme.Border })
            }
            .width('100%')
            .padding(20)
            .justifyContent(FlexAlign.SpaceBetween)
            if (this.transactions.length === 0) {
              Column() {
                Image($r('app.media.ill_empty_state_glass'))
                  .width(120).height(120).opacity(0.4).objectFit(ImageFit.Contain).margin({ bottom: 10, top: 40 })
                Text('\u54ce\u5440\uff0c\u5f53\u524d\u65f6\u95f4\u6ca1\u6709\u8bb0\u5f55\u5462~').fontColor(AppTheme.TextSub).fontSize(14)
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
                  .backgroundColor(AppTheme.CardBg)
                  .borderRadius(24)
                  .shadow(AppTheme.CardShadow)
                }, (item: Bill, index: number) => index + JSON.stringify(item))
              }
              .padding({ left: 20, right: 20, bottom: 120 }) 
            }
          }
        }
        .width('100%')
        .height('100%')
      }
      .width('100%')
      .height('100%')
      .backgroundColor(AppTheme.Background)
    }
    .width('100%')
    .height('100%')
    .titleMode(NavigationTitleMode.Mini)
    .hideTitleBar(true)
    .hideBackButton(true)
  }

  pageTransition(): void {
    PageTransitionEnter({ duration: 200 })
      .slide(SlideEffect.Right)
    PageTransitionExit({ duration: 200 })
      .slide(SlideEffect.Left)
  }

  @Builder
  TransactionRow(item: Bill): void {
    Row() {
      /*
      Image(item.type=='expense'?$r('app.media.ic_expense_default'):$r('app.media.ic_income_default'))
        .width(40)
        .height(40)
        .margin({right:10})
        .objectFit(ImageFit.Contain)
      */
      Column() {
        Text(this.allCategories.find(c => c.categoryId === item.categoryId)?.name || (item.type === 'expense' ? '\u652f\u51fa' : '\u6536\u5165'))
          .fontSize(this.titleFontSize.getValue(this.currentBreakpoint) as number)
          .fontWeight(FontWeight.Bold)
        
        Row() {
           Text(item.transactionDate.replace('T', ' ').substring(5, 16))
            .fontSize(12)
            .fontColor(AppTheme.TextSub)
            .margin({ right: 8 })
           if (item.note) {
             Text(item.note)
               .fontSize((this.titleFontSize.getValue(this.currentBreakpoint) as number) - 2)
               .fontColor(AppTheme.TextSub)
           }
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text(item.type === 'expense' ? `-${item.amount.toFixed(2)}` : `+${item.amount.toFixed(2)}`)
        .fontSize((this.amountFontSize.getValue(this.currentBreakpoint) as number) + 2)
        .fontWeight(item.type === 'expense' ? FontWeight.Medium : FontWeight.Bolder)
        .fontColor(item.type === 'expense' ? AppTheme.Expense : AppTheme.Income)
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 24, bottom: 24 })
    .backgroundColor(AppTheme.CardBg)
    .borderRadius(24)
    .border({
      width: { bottom: 0.5 },
      color: { bottom: AppTheme.Border }
    })
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

  build(): void {
    Column() {
      Text('\u6536\u5230\u65b0\u7684\u8d26\u672c\u9080\u8bf7')
        .fontSize(18).fontWeight(FontWeight.Bold).margin({ top: 20, bottom: 10 })
      
      List() {
        ForEach(this.invitations, (invite: LedgerInvitation) => {
          ListItem() {
             Column() {
               Text(`\u9080\u8bf7\u4eba: ${invite.inviterName}`)
                 .fontSize(14).fontColor(AppTheme.TextSub)
               Text(`\u8d26\u672c: ${invite.ledgerName}`)
                 .fontSize(16).fontWeight(FontWeight.Medium).fontColor(AppTheme.TextMain).margin({top: 4, bottom: 8})
               
               Row() {
                 Button('\u62d2\u7edd')
                   .fontColor(AppTheme.TextMain).backgroundColor(AppTheme.CardBg)
                   .height(30).fontSize(12)
                   .border({ width: 0.5, color: AppTheme.Border })
                   .onClick(() => this.onHandle(invite, 'decline'))
                   .margin({ right: 10 })
                   
                 Button('\u63a5\u53d7')
                   .fontColor(AppTheme.TextWhite).backgroundColor(AppTheme.HeroBg)
                   .height(30).fontSize(12)
                   .onClick(() => this.onHandle(invite, 'accept'))
               }
               .width('100%').justifyContent(FlexAlign.End)
             }
             .width('100%')
             .padding(20)
             .backgroundColor(AppTheme.CardBg)
             .borderRadius(24)
             .shadow(AppTheme.CardShadow)
             .margin({ bottom: 10 })
          }
        })
      }
      .width('100%')
      .constraintSize({ maxHeight: 300 })
      .padding(10)

      Button('\u5173\u95ed')
        .width('40%').margin({ top: 10, bottom: 20 })
        .backgroundColor(AppTheme.HeroBg)
        .fontColor(AppTheme.TextWhite)
        .onClick(() => this.controller.close())
    }
    .width('80%')
    .backgroundColor(AppTheme.CardBg)
    .borderRadius(24)
  }
}

