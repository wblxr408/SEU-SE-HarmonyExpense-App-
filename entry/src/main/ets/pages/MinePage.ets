import router from '@ohos.router';
import { UserSessionService, SessionInfo } from '../service/UserSessionService';
import promptAction from '@ohos.promptAction';

@Component
export struct MinePage {
  @State currentUser: SessionInfo | null = null;

  aboutToAppear() {
    this.currentUser = UserSessionService.getCurrentSession();
  }

  build() {
    Column() {
      // 用户信息卡片
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
      }
      .width('100%')
      .padding(24)
      .backgroundColor(Color.White)
      .margin({ bottom: 12 })

      // 功能菜单
      List() {
        // 账户管理
        ListItem() {
          this.MenuRow('账户资产', $r('app.media.icon'), () => {
             router.pushUrl({ url: 'pages/AccountManagementPage' });
          })
        }

        // 数据同步
        ListItem() {
          this.MenuRow('数据同步', $r('app.media.icon'), () => {
             router.pushUrl({ url: 'pages/SyncSettingsPage' });
          })
        }
        
        // 数据备份
        ListItem() {
          this.MenuRow('备份与恢复', $r('app.media.icon'), () => {
            router.pushUrl({ url: 'pages/BackupPage' });
          })
        }

        // 提醒设置
        ListItem() {
          this.MenuRow('提醒设置', $r('app.media.icon'), () => {
            router.pushUrl({ url: 'pages/ReminderSettingsPage' });
          })
        }

        // 分类管理
        ListItem() {
          this.MenuRow('分类管理', $r('app.media.icon'), () => {
            router.pushUrl({ url: 'pages/CategoryManagement' });
          })
        }
      }
      .width('100%')
      .backgroundColor(Color.White)
      .divider({ strokeWidth: 1, color: '#F0F0F0', startMargin: 56 })

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
  MenuRow(title: string, icon: Resource, onClick: () => void) {
    Row() {
      Image(icon) // 需要确保资源存在，或者暂时用 Text 代替图标
        .width(24)
        .height(24)
        .margin({ right: 16 })
      
      Text(title)
        .fontSize(16)
        .layoutWeight(1)
      
      // Image($r('app.media.ic_public_arrow_right')) // 箭头图标缺失，暂时隐藏
      //   .width(16)
      //   .height(16)
      //   .opacity(0.5)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .onClick(onClick)
  }
}
