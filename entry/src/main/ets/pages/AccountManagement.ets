// entry/src/main/ets/pages/AccountManagement.ets

import { Account } from '../model/Account';
import { AccountDAO } from '../dao/AccountDAO';
import { promptAction } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import hilog from '@ohos.hilog';

const LOG_TAG = 'AccountManagement';
const HILOG_DOMAIN = 0x0001;


@CustomDialog
struct AccountEditDialog {
  controller: CustomDialogController;
  @Link editingAccount: Account | null;
  onSave: () => void = () => {};

  // 账户类型选项
  accountTypes: SelectOption[] = [
    { value: '现金' },
    { value: '银行卡' },
    { value: '信用卡' },
    { value: '其他' }
  ];
  typeValues: string[] = ['cash', 'bank', 'credit_card', 'other'];
  getLabelByValue(val: string): string {
    const index = this.typeValues.indexOf(val);
    return index >= 0 ? this.accountTypes[index].value as string : '现金';
  }
  build() {
    if (this.editingAccount) {
      Column({ space: 15 }) {
        Text(this.editingAccount.accountId === 0 ? '新建账户' : '编辑账户')
          .fontSize(20).fontWeight(FontWeight.Bold).width('100%')

        // 1. 账户名称
        TextInput({ placeholder: '账户名称 (如: 招商银行)', text: this.editingAccount.name })
          .onChange((value) => { if(this.editingAccount) this.editingAccount.name = value })

        // 2. 初始余额 (核心差异点)
        TextInput({ placeholder: '当前余额', text: this.editingAccount.balance.toString() })
          .type(InputType.Number) // 数字键盘
          .onChange((value) => {
            if(this.editingAccount) {
              // 处理空字符串，避免 NaN
              this.editingAccount.balance = parseFloat(value) || 0;
            }
          })

        // 3. 账户类型
        Row() {
          Text('类型: ').fontSize(16)
          Select(this.accountTypes)
            .value(this.getLabelByValue(this.editingAccount.type))
            .onSelect((index, value) => {
              if (this.editingAccount) {
                this.editingAccount.type = this.typeValues[index] as 'cash' | 'bank' | 'credit_card' | 'other';
              }
            })
        }.width('100%').justifyContent(FlexAlign.Start)


        TextInput({ placeholder: '颜色代码 (如: #1E90FF)', text: this.editingAccount.color })
          .onChange((value) => { if(this.editingAccount) this.editingAccount.color = value })

        // 按钮组
        Row({ space: 10 }) {
          Button('取消').onClick(() => this.controller.close()).backgroundColor('#E5E5EA').fontColor(Color.Black).layoutWeight(1)
          Button('保存').onClick(() => this.onSave()).layoutWeight(1)
        }.margin({ top: 10 })
      }
      .padding(20)
      .backgroundColor(Color.White)
      .borderRadius(16)
    } else {
      Column()
    }
  }
}

@Entry
@Component
struct AccountManagement {
  @StorageProp('currentUserId') currentUserId: number = 1;
  @State accounts: Array<Account> = [];
  @State currentEditingAccount: Account | null = null;

  dialogController: CustomDialogController = new CustomDialogController({
    builder: AccountEditDialog({
      editingAccount: $currentEditingAccount,
      onSave: (): Promise<void> => this.handleSave()
    }),
    alignment: DialogAlignment.Bottom,
    autoCancel: false
  });

  onPageShow() {
    this.loadAccounts();
  }

  async loadAccounts() {
    try {
      // 获取该用户的所有账户
      const data = await AccountDAO.getByUserId(this.currentUserId);
      this.accounts = data;
    } catch (err) {
      const e = err as BusinessError;
      promptAction.showToast({ message: '加载失败: ' + e.message });
    }
  }

  async handleSave() {
    if (!this.currentEditingAccount) return;
    if (!this.currentEditingAccount.name) {
      promptAction.showToast({ message: '请输入账户名称' });
      return;
    }

    try {
      if (this.currentEditingAccount.accountId === 0) {
        // 新增
        this.currentEditingAccount.userId = this.currentUserId;
        this.currentEditingAccount.createdAt = new Date().toISOString();
        await AccountDAO.insert(this.currentEditingAccount);
      } else {
        // 更新
        await AccountDAO.update(this.currentEditingAccount);
      }
      this.dialogController.close();
      this.currentEditingAccount = null;
      this.loadAccounts(); // 刷新列表
      promptAction.showToast({ message: '保存成功' });
    } catch (err) {
      const e = err as BusinessError;
      hilog.error(HILOG_DOMAIN, LOG_TAG, '保存失败: %{public}s', e.message);
      promptAction.showToast({ message: '保存失败' });
    }
  }

  async handleDelete(id: number) {
    try {
      await AccountDAO.softDelete(id); // 使用软删除
      this.loadAccounts();
      promptAction.showToast({ message: '已删除' });
    } catch (err) {
      const e = err as BusinessError;
      promptAction.showToast({ message: '删除失败: ' + e.message });
    }
  }

  // 辅助函数：根据类型获取图标或名称
  getTypeLabel(type: string): string {
    const map: Record<string, string> = {
      'cash': '现金', 'bank': '银行卡', 'credit_card': '信用卡', 'other': '其他'
    };
    return map[type] || type;
  }

  @Builder SwipeDeleteButton(id: number) {
    Button('删除')
      .type(ButtonType.Normal)
      .backgroundColor(Color.Red)
      .fontColor(Color.White)
      .height('100%')
      .width(80)
      .onClick(() => this.handleDelete(id))
  }

  build() {
    Navigation() {
      Column() {
        if (this.accounts.length === 0) {
          // 空状态
          Column({ space: 10 }) {
            Image($r('app.media.norecord')).width(100).height(100).opacity(0.5)
            Text('还没有账户，新建一个吧').fontColor(Color.Gray)
          }.margin({ top: 100 })
        } else {
          List({ space: 10 }) {
            ForEach(this.accounts, (item: Account) => {
              ListItem() {
                Row() {
                  // 左侧色块条
                  Column().width(5).height(40).backgroundColor(item.color || '#1890FF').borderRadius(2).margin({ right: 10 })

                  Column() {
                    Text(item.name).fontSize(16).fontWeight(FontWeight.Bold)
                    Text(this.getTypeLabel(item.type)).fontSize(12).fontColor(Color.Gray).margin({ top: 4 })
                  }.alignItems(HorizontalAlign.Start).layoutWeight(1)

                  Text(`¥${item.balance.toFixed(2)}`)
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(Color.Black)
                }
                .padding(15)
                .backgroundColor(Color.White)
                .borderRadius(12)
                .width('100%')
                .onClick(() => {
                  this.currentEditingAccount = item.clone();
                  this.dialogController.open();
                })
              }
              .swipeAction({ end: this.SwipeDeleteButton(item.accountId) })
            })
          }
          .layoutWeight(1)
          .width('100%')
          .padding(12)
        }

        // 底部悬浮添加按钮
        Button('+ 新建账户')
          .width('90%')
          .height(50)
          .type(ButtonType.Capsule)
          .margin({ bottom: 20 })
          .onClick(() => {
            this.currentEditingAccount = new Account();
            this.dialogController.open();
          })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F1F3F5')
    }
    .title('账户管理')
    .titleMode(NavigationTitleMode.Mini)
  }
}