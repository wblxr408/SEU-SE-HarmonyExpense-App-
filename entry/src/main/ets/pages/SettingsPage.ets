import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { SharedLedgerService } from '../service/SharedLedgerService';
import { LedgerInvitation } from '../model/SharedLedger';

@Entry
@Component
struct SettingsPage {
  @State pendingInvitations: LedgerInvitation[] = [];

  // Dialog Controller
  // TODO: InvitationProcessingDialog is missing in the codebase.
  // invitationController: CustomDialogController = new CustomDialogController({
  //   builder: InvitationProcessingDialog({
  //     invitations: $pendingInvitations,
  //     onHandle: (invite, action) => this.handleInvitation(invite, action)
  //   }),
  //   autoCancel: false,
  //   customStyle: true
  // });

  handleInvitation(invite: LedgerInvitation, action: string) {
    // TODO: Implement handleInvitation
    console.info(`Handling invitation: ${JSON.stringify(invite)}, action: ${action}`);
  }

  // 退出登录处理函数
  handleLogout() {
    // 1. 弹出确认框 (可选，为了体验更好)
    AlertDialog.show({
      title: '提示',
      message: '确定要退出登录吗？',
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '退出',
        fontColor: Color.Red,
        action: () => {
          // 2. 清除全局用户状态
          AppStorage.SetOrCreate('currentUserId', 0); // 0 代表未登录

          // 3. 提示并跳转
          promptAction.showToast({ message: '已退出登录' });

          // 使用 replaceUrl 还是 clear + push 取决于你想不想保留历史栈
          // 这里为了简单和彻底，建议直接跳回登录页，鸿蒙会自动处理栈顶
          // 或者使用 router.clear() 清空栈（视具体API版本支持情况而定）
          router.replaceUrl({ url: 'pages/LoginPage' });
        }
      }
    })
  }

  async onPageShow() {
      // TODO: pendingInvitations = await SharedLedgerService.getPendingInvitations();
  }

  build() {
    Navigation() {
      Column() {
        List() {
          // --- 原有的功能列表 ---

          // 1. 分类管理
          ListItem() {
            this.SettingItem('分类管理', () => {
              router.pushUrl({ url: 'pages/CategoryManagement' });
            })
          }

          // 2. 账户管理
          ListItem() {
            this.SettingItem('账户管理', () => {
              router.pushUrl({ url: 'pages/AccountManagement' });
            })
          }

          // 3. 预算设置
          ListItem() {
            this.SettingItem('预算设置', () => {
              router.pushUrl({ url: 'pages/BudgetManagement' });
            })
          }

          // 4. 导出数据
          ListItem() {
            this.SettingItem('数据导出与导入', () => {
              router.pushUrl({ url: 'pages/ExportImportPage' });
            })
          }
        }
        .width('100%')
        // .layoutWeight(1) // 让列表占据中间剩余空间
        .backgroundColor('#F1F3F5')
        .divider({ strokeWidth: 1, color: '#E0E0E0', startMargin: 15, endMargin: 15 })

        // API Key 配置 (Demo)
        Column() {
          Text('AI API Key (DeepSeek/OpenAI)')
            .fontSize(14)
            .fontColor(Color.Gray)
            .margin({ top: 20, bottom: 5, left: 15 })
            .width('100%')
          
          TextInput({ placeholder: '请输入 API Key', text: AppStorage.Get('LLM_API_KEY') || '' })
            .onChange((value) => {
              AppStorage.SetOrCreate('LLM_API_KEY', value);
            })
            .width('90%')
            .height(40)
            .backgroundColor(Color.White)
            .borderRadius(8)
            .margin({ bottom: 10 })
        }
        .width('100%')

        // --- 退出登录按钮 (放在底部或者列表最后) ---
        // 这里我把它作为一个单独的按钮放在列表下方，更醒目
        Button('退出登录')
          .width('90%')
          .height(50)
          .margin({ top: 30 })
          .fontColor(Color.White)
          .backgroundColor('#FF4D4F') // 红色警示色
          .type(ButtonType.Capsule)
          .onClick(() => {
            this.handleLogout();
          })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F1F3F5')
    }
    .title('设置')
    .titleMode(NavigationTitleMode.Mini)
  }

  // 封装列表项的样式 (保持不变)
  @Builder
  SettingItem(title: string, onClick: () => void) {
    Row() {
      Text(title)
        .fontSize(16)
        .fontColor(Color.Black)
        .layoutWeight(1)

      Text('>')
        .fontSize(18)
        .fontColor(Color.Gray)
    }
    .width('100%')
    .height(56)
    .padding({ left: 15, right: 15 })
    .backgroundColor(Color.White)
    .onClick(onClick)
  }
}