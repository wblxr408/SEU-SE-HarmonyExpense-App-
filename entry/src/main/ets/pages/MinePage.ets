import router from '@ohos.router';
import { UserSessionService, SessionInfo } from '../service/UserSessionService';
import { NotificationService } from '../service/NotificationService';
import promptAction from '@ohos.promptAction';

@Component
export struct MinePage {
  @State currentUser: SessionInfo | null = null;
  @State unreadCount: number = 0;

  aboutToAppear() {
    this.currentUser = UserSessionService.getCurrentSession();
    this.loadUnreadCount();
  }

  async loadUnreadCount() {
    try {
      this.unreadCount = await NotificationService.getUnreadCount();
    } catch (error) {
      console.error('[MinePage] 加载未读数量失败:', error);
    }
  }

  build() {
    Column() {
      // 用户信息卡片 - 可点击编辑
      Row() {
        Image($r('app.media.icon')) // 默认头像
          .width(60)
          .height(60)
          .margin({ right: 16 })
          .borderRadius(30)
          .backgroundColor('#E0E0E0')
        
        Column() {
          if (this.currentUser) {
            Text(this.currentUser.username)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
            Text(this.currentUser.email)
              .fontSize(14)
              .fontColor(Color.Gray)
              .margin({ top: 4 })
          } else {
            Text('未登录')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .onClick(() => {
                router.pushUrl({ url: 'pages/LoginPage' });
              })
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        // 编辑按钮
        if (this.currentUser) {
          Text('编辑')
            .fontSize(14)
            .fontColor('#2E65F3')
        }
      }
      .width('100%')
      .padding(24)
      .backgroundColor(Color.White)
      .margin({ bottom: 12 })
      .onClick(() => {
        if (this.currentUser) {
          router.pushUrl({ url: 'pages/ProfileEditPage' });
        }
      })

      // 功能菜单
      List() {
        // 通知中心 - 带未读角标
        ListItem() {
          this.MenuRowWithBadge('通知中心', this.unreadCount, () => {
             router.pushUrl({ url: 'pages/NotificationCenterPage' });
          })
        }

        // 应用设置
        ListItem() {
          this.MenuRow('应用设置', () => {
             router.pushUrl({ url: 'pages/AppSettingsPage' });
          })
        }

        // 账户管理
        ListItem() {
          this.MenuRow('账户资产', () => {
             router.pushUrl({ url: 'pages/AccountManagementPage' });
          })
        }

        // 共享账本
        ListItem() {
          this.MenuRow('多人共享账本', () => {
             router.pushUrl({ url: 'pages/SharedLedgerListPage' });
          })
        }

        // 数据同步
        ListItem() {
          this.MenuRow('数据同步', () => {
             router.pushUrl({ url: 'pages/SyncSettingsPage' });
          })
        }
        
        // 数据备份
        ListItem() {
          this.MenuRow('备份与恢复', () => {
            router.pushUrl({ url: 'pages/BackupPage' });
          })
        }

        // 提醒设置
        ListItem() {
          this.MenuRow('提醒设置', () => {
            router.pushUrl({ url: 'pages/ReminderSettingsPage' });
          })
        }

        // 分类管理
        ListItem() {
          this.MenuRow('分类管理', () => {
            router.pushUrl({ url: 'pages/CategoryManagement' });
          })
        }
      }
      .width('100%')
      .backgroundColor(Color.White)
      .divider({ strokeWidth: 1, color: '#F0F0F0', startMargin: 16 })

      // 退出登录按钮
      if (this.currentUser) {
        Button('退出登录')
          .width('90%')
          .height(50)
          .fontColor(Color.Red)
          .backgroundColor(Color.White)
          .margin({ top: 40 })
          .onClick(() => {
            UserSessionService.logout();
            this.currentUser = null;
            promptAction.showToast({ message: '已退出登录' });
            router.replaceUrl({ url: 'pages/LoginPage' });
          })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F1F3F5')
  }

  @Builder
  MenuRow(title: string, onClick: () => void) {
    Row() {
      Text(title)
        .fontSize(16)
        .layoutWeight(1)
      Text('>')
        .fontSize(16)
        .fontColor('#8395A7')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .onClick(onClick)
  }

  @Builder
  MenuRowWithBadge(title: string, badge: number, onClick: () => void) {
    Row() {
      Text(title)
        .fontSize(16)
        .layoutWeight(1)
      if (badge > 0) {
        Text(badge > 99 ? '99+' : badge.toString())
          .fontSize(12)
          .fontColor(Color.White)
          .backgroundColor('#FF4D4F')
          .borderRadius(10)
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .margin({ right: 8 })
      }
      Text('>')
        .fontSize(16)
        .fontColor('#8395A7')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .onClick(onClick)
  }
}

