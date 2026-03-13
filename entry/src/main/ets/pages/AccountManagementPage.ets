import router from '@ohos.router';
import { Account } from '../model/Account';
import { AccountDAO } from '../dao/AccountDAO';
import { UserSessionService } from '../service/UserSessionService';
import promptAction from '@ohos.promptAction';
import { BusinessError } from '@kit.BasicServicesKit';
import { AppTheme } from '../common/config/AppTheme';

@CustomDialog
struct AccountEditDialog {
  controller: CustomDialogController;
  @Link editingAccount: Account | null;
  onSave: () => void = () => {};

  build() {
    if (this.editingAccount) {
      Column({ space: 15 }) {
        Text(this.editingAccount.accountId === 0 ? '新建账户' : '编辑账户')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .width('100%')

        TextInput({ placeholder: '账户名称 (如: 招商银行)', text: this.editingAccount.name })
          .onChange((value: string) => {
            if (this.editingAccount) this.editingAccount.name = value;
          })

        Row() {
          Text('账户类型:').margin({ right: 10 })
          Select([
            { value: '现金' },
            { value: '储蓄卡' },
            { value: '信用卡' },
            { value: '其他' }
          ])
          .value(this.getTypeLabel(this.editingAccount.type))
          .onSelect((index: number) => {
            if (this.editingAccount) {
              const types = ['cash', 'bank', 'credit_card', 'other'];
              this.editingAccount.type = types[index] as 'cash' | 'bank' | 'credit_card' | 'other';
            }
          })
        }
        .width('100%')

        TextInput({ placeholder: '当前余额', text: this.editingAccount.balance.toString() })
          .type(InputType.Number)
          .onChange((value: string) => {
            if (this.editingAccount) this.editingAccount.balance = parseFloat(value) || 0;
          })

        Row({ space: 10 }) {
          Button('取消').onClick(() => this.controller.close()).layoutWeight(1).backgroundColor(AppTheme.CardBg).fontColor(AppTheme.TextMain).border({ width: 0.5, color: AppTheme.Border })
          Button('保存').onClick(this.onSave).layoutWeight(1).type(ButtonType.Capsule).backgroundColor(AppTheme.HeroBg).fontColor(AppTheme.TextWhite)
        }.width('100%').margin({ top: 10 })
      }
      .padding(24)
      .backgroundColor(AppTheme.CardBg)
      .borderRadius(24)
      .shadow(AppTheme.CardShadow)
      .width('90%')
    } else {
      Column()
    }
  }

  getTypeLabel(type: string): string {
    const map: Record<string, string> = { 'cash': '现金', 'bank': '储蓄卡', 'credit_card': '信用卡', 'other': '其他' };
    return map[type] || '现金';
  }
}

@Entry
@Component
struct AccountManagementPage {
  @State accounts: Account[] = [];
  @State editingAccount: Account | null = null;
  
  dialogController: CustomDialogController = new CustomDialogController({
    builder: AccountEditDialog({
      editingAccount: $editingAccount,
      onSave: () => { this.handleSave(); }
    }),
    autoCancel: false,
    alignment: DialogAlignment.Center
  });

  async onPageShow() {
    if (!await UserSessionService.getCurrentUserId()) {
      promptAction.showToast({ message: '登录已过期' });
      router.replaceUrl({ url: 'pages/LoginPage' });
      return;
    }
    this.loadAccounts();
  }

  async loadAccounts() {
    try {
      const userId = (await UserSessionService.getCurrentUserId())!;
      this.accounts = await AccountDAO.getByUserId(userId);
    } catch (e) {
      promptAction.showToast({ message: '加载账户失败' });
    }
  }

  async handleCreate() {
    const userId = await UserSessionService.getCurrentUserId();
    if (!userId) return;
    this.editingAccount = new Account(0, userId); // 检查 Account 构造函数签名
    this.dialogController.open();
  }

  handleEdit(acc: Account) {
    this.editingAccount = acc.clone();
    this.dialogController.open();
  }

  async handleDelete(accId: number) {
    try {
      await AccountDAO.delete(accId); // 物理删除以简化，或者使用软删除
      promptAction.showToast({ message: '删除成功' });
      this.loadAccounts();
    } catch (e) {
      promptAction.showToast({ message: '删除失败' });
    }
  }

  async handleSave() {
    if (!this.editingAccount) return;
    if (!this.editingAccount.name) {
      promptAction.showToast({ message: '请输入名称' });
      return;
    }
    try {
      if (this.editingAccount.accountId === 0) {
        await AccountDAO.insert(this.editingAccount);
      } else {
        await AccountDAO.update(this.editingAccount);
      }
      this.dialogController.close();
      this.loadAccounts();
      promptAction.showToast({ message: '保存成功' });
    } catch (e) {
      promptAction.showToast({ message: '保存失败: ' + (e as BusinessError).message });
    }
  }

  // 计算总资产（余额 > 0 的部分）
  get totalAssets(): number {
    return this.accounts.filter(acc => acc.balance > 0).reduce((sum, acc) => sum + acc.balance, 0);
  }

  // 计算总负债（余额 < 0 的部分，取绝对值）
  get totalLiabilities(): number {
    return this.accounts.filter(acc => acc.balance < 0).reduce((sum, acc) => sum + Math.abs(acc.balance), 0);
  }

  // 计算净资产
  get netAssets(): number {
    return this.totalAssets - this.totalLiabilities;
  }

  build() {
    Column() {
      // 1. 顶部导航栏
      Row() {
        Image($r('app.media.ic_back_glass'))
          .width(24)
          .height(24)
          .fillColor(AppTheme.TextMain)
          .onClick(() => router.back())
        Text('资产')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppTheme.TextMain)
          .margin({ left: 16 })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 20, bottom: 12 })
      .backgroundColor(AppTheme.GlassBackground)
      .backdropBlur(30)

      // 2. 顶部总览卡片 (Summary Card) - 玻璃拟态
      Column() {
        // 上半部分：净资产
        Column() {
          Text('净资产')
            .fontSize(14)
            .fontColor(AppTheme.TextWhite)
            .opacity(0.8)
          Text(`¥${(this.netAssets ?? 0).toFixed(2)}`)
            .fontSize(38)
            .fontWeight(FontWeight.Bolder)
            .fontColor(AppTheme.TextWhite)
            .margin({ top: 8 })
        }
        .alignItems(HorizontalAlign.Center)
        .width('100%')

        // 分割线
        Divider()
          .color('rgba(255, 255, 255, 0.28)')
          .strokeWidth(1)
          .margin({ top: 16, bottom: 16 })

        // 下半部分：资产与负债
        Row() {
          Column() {
            Text('总资产')
              .fontSize(12)
              .fontColor(AppTheme.TextWhite)
              .opacity(0.78)
            Text(`¥${(this.totalAssets ?? 0).toFixed(2)}`)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppTheme.TextWhite)
              .margin({ top: 4 })
          }
          .alignItems(HorizontalAlign.Start)

          Column() {
            Text('总负债')
              .fontSize(12)
              .fontColor(AppTheme.TextWhite)
              .opacity(0.78)
            Text(`¥${(this.totalLiabilities ?? 0).toFixed(2)}`)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(AppTheme.TextWhite)
              .opacity(0.72)
              .margin({ top: 4 })
          }
          .alignItems(HorizontalAlign.End)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
      }
      .width('calc(100% - 32vp)')
      .margin({ left: 16, right: 16, top: 16 })
      .padding(24)
      .borderRadius(24)
      .backgroundColor(AppTheme.HeroBg)
      .shadow(AppTheme.CardShadow)

      // 3. 标题与操作区 (Title & Action Area)
      Row() {
        // 左侧标题 - 马克笔高亮效果
        Stack({ alignContent: Alignment.BottomStart }) {
          Row()
            .width('100%')
            .height(8)
            .backgroundColor(AppTheme.CardBg)
            .margin({ bottom: 2 })
          Text('资产账户')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppTheme.TextMain)
            // 为了让高亮跨越文字宽度的设置
            .padding({ left: 4, right: 4 })
        }
        // 由于Stack的width如果设为100%会占满，这里让内部自己撑开
        .align(Alignment.Start)

        // 右侧操作按钮
        Button('+ 添加账户')
          .height(32)
          .fontSize(14)
          .fontColor(AppTheme.TextWhite)
          .backgroundColor(AppTheme.HeroBg)
          .borderRadius(16)
          .shadow(AppTheme.FabShadow)
          .onClick(() => this.handleCreate())
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 24, bottom: 12 })
      .justifyContent(FlexAlign.SpaceBetween)

      // 4. 账户列表区与空状态
      if (this.accounts.length === 0) {
        Column() {
          Text('💳')
            .fontSize(64)
          Text('哎呀，还没有资产账户呢~')
            .fontSize(14)
            .fontColor(AppTheme.TextSub)
            .margin({ top: 16 })
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        List({ space: 12 }) {
          ForEach(this.accounts, (item: Account) => {
            ListItem() {
              Row() {
                Column() {
                  Text(item.name)
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(AppTheme.TextMain)
                  Text(this.formatType(item.type))
                    .fontSize(12)
                    .fontColor(AppTheme.TextSub)
                    .margin({ top: 4 })
                }
                .alignItems(HorizontalAlign.Start)

                Blank()

                Text(`${item.balance >= 0 ? '+' : ''}${(item.balance ?? 0).toFixed(2)}`)
                  .fontSize(22)
                  .fontWeight(item.balance < 0 ? FontWeight.Medium : FontWeight.Bolder)
                  .fontColor(item.balance < 0 ? AppTheme.Expense : AppTheme.Income)
              }
              .width('100%')
              .padding(24)
              .borderRadius(24)
              .backgroundColor(AppTheme.CardBg)
              .shadow(AppTheme.CardShadow)
              .border({
                width: { bottom: 0.5 },
                color: { bottom: AppTheme.Border }
              })
              .onClick(() => this.handleEdit(item))
            }
            .swipeAction({ end: this.DeleteButton(item.accountId) })
          })
        }
        .layoutWeight(1)
        .width('100%')
        .padding({ left: 20, right: 20, bottom: 30 })
      }
    }
    .width('100%')
    .height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
    .backgroundColor(AppTheme.Background)
  }

  @Builder DeleteButton(id: number) {
    Button('删除')
      .type(ButtonType.Circle)
      .backgroundColor(AppTheme.HeroBg)
      .fontColor(AppTheme.TextWhite)
      .onClick(() => this.handleDelete(id))
  }

  formatType(type: string): string {
    const map: Record<string, string> = { 'cash': '现金', 'bank': '储蓄卡', 'credit_card': '信用卡', 'other': '其他' };
    return map[type] || type;
  }
}
