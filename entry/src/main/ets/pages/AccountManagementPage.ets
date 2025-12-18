import router from '@ohos.router';
import { Account } from '../model/Account';
import { AccountDAO } from '../dao/AccountDAO';
import { UserSessionService } from '../service/UserSessionService';
import promptAction from '@ohos.promptAction';
import { BusinessError } from '@kit.BasicServicesKit';

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
          Button('取消').onClick(() => this.controller.close()).layoutWeight(1).backgroundColor(Color.Gray)
          Button('保存').onClick(this.onSave).layoutWeight(1).type(ButtonType.Capsule)
        }.width('100%').margin({ top: 10 })
      }
      .padding(20)
      .backgroundColor(Color.White)
      .borderRadius(15)
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

  onPageShow() {
    if (!UserSessionService.getCurrentUserId()) {
      promptAction.showToast({ message: '登录已过期' });
      router.replaceUrl({ url: 'pages/LoginPage' });
      return;
    }
    this.loadAccounts();
  }

  async loadAccounts() {
    try {
      const userId = UserSessionService.getCurrentUserId()!;
      this.accounts = await AccountDAO.getByUserId(userId);
    } catch (e) {
      promptAction.showToast({ message: '加载账户失败' });
    }
  }

  handleCreate() {
    const userId = UserSessionService.getCurrentUserId();
    if (!userId) return;
    this.editingAccount = new Account(0, userId); // Check Account constructor signature
    this.dialogController.open();
  }

  handleEdit(acc: Account) {
    this.editingAccount = acc.clone();
    this.dialogController.open();
  }

  async handleDelete(accId: number) {
    try {
      await AccountDAO.delete(accId); // Physical delete for simplicity, or soft delete
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

  build() {
    Column() {
      // Header
      Row() {
        Image($r('app.media.back'))
          .width(24).height(24)
          .onClick(() => router.back())
        Text('账户管理')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })
      }
      .width('100%').padding(16).backgroundColor(Color.White)

      // List
      List({ space: 10 }) {
        ForEach(this.accounts, (item: Account) => {
          ListItem() {
            Row() {
              Column() {
                Text(item.name).fontSize(18).fontWeight(FontWeight.Bold)
                Text(this.formatType(item.type)).fontSize(14).fontColor(Color.Gray).margin({ top: 4 })
              }.alignItems(HorizontalAlign.Start)
              
              Blank()
              
              Text(`¥${item.balance.toFixed(2)}`)
                .fontSize(18)
                .fontColor(item.balance < 0 ? Color.Red : Color.Black)
            }
            .width('100%')
            .padding(15)
            .backgroundColor(Color.White)
            .borderRadius(8)
            .onClick(() => this.handleEdit(item))
          }
          .swipeAction({ end: this.DeleteButton(item.accountId) })
        })
      }
      .layoutWeight(1)
      .width('100%')
      .padding(15)

      Button('添加账户')
        .width('90%')
        .height(50)
        .type(ButtonType.Capsule)
        .margin(20)
        .onClick(() => this.handleCreate())
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F1F3F5')
  }

  @Builder DeleteButton(id: number) {
    Button('删除').type(ButtonType.Circle).backgroundColor(Color.Red).onClick(() => this.handleDelete(id))
  }

  formatType(type: string): string {
    const map: Record<string, string> = { 'cash': '现金', 'bank': '储蓄卡', 'credit_card': '信用卡', 'other': '其他' };
    return map[type] || type;
  }
}
