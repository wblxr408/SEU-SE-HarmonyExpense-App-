import router from '@ohos.router';
import { UserSessionService, SessionInfo } from '../service/UserSessionService';
import { NotificationService } from '../service/NotificationService';
import { promptAction } from '@kit.ArkUI';

// 将玻璃拟态卡片提取为独立组件，使用 @BuilderParam 解决 UI 语法冲突
@Component
struct GlassCardContainer {
  @BuilderParam content: () => void;

  build() {
    Column() {
      if (this.content) {
        this.content();
      }
    }
    .backgroundColor('rgba(255, 255, 255, 0.4)')
    .backdropBlur(20)
    .borderRadius(24)
    .border({ width: 1, color: 'rgba(255, 255, 255, 0.8)', style: BorderStyle.Solid })
    .shadow({ radius: 16, color: 'rgba(0, 0, 0, 0.04)', offsetY: 6 })
    .margin({ left: 16, right: 16, bottom: 16 })
    .padding(16)
  }
}

@Component
export struct MinePage {
  @State currentUser: SessionInfo | null = null;
  @State unreadCount: number = 0;
  @State daysCount: number = 128; // 模拟记账天数
  @State billsCount: number = 856; // 模拟记账笔数

  async aboutToAppear() {
    this.currentUser = await UserSessionService.getCurrentSession();
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
      Scroll() {
        Column() {
          // A区：头部信息与统计
          Column() {
            Row() {
              // 圆形头像
              Image(this.currentUser ? $r('app.media.icon') : $r('app.media.icon'))
                .width(64)
                .height(64)
                .borderRadius(32)
                .backgroundColor('#E0E0E0')
                .margin({ right: 16 })
                .onClick(() => {
                  if (this.currentUser) {
                    router.pushUrl({ url: 'pages/ProfileEditPage' });
                  }
                })
              
              Column() {
                if (this.currentUser) {
                  Text(this.currentUser.username)
                    .fontSize('18fp')
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#333333')
                  Text(this.currentUser.email)
                    .fontSize('12fp')
                    .fontColor('#999999')
                    .margin({ top: 4 })
                } else {
                  Text('点击登录')
                    .fontSize('18fp')
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#333333')
                    .onClick(() => {
                      router.pushUrl({ url: 'pages/LoginPage' });
                    })
                }
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
            }
            .width('100%')

            // 统计数据
            Row() {
              Row() {
                Text('记账天数 ')
                  .fontSize('14fp')
                  .fontColor('#666666')
                Text(this.daysCount.toString())
                  .fontSize('16fp')
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FFB347')
              }
              .margin({ right: 24 })

              Row() {
                Text('记账笔数 ')
                  .fontSize('14fp')
                  .fontColor('#666666')
                Text(this.billsCount.toString())
                  .fontSize('16fp')
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FFB347')
              }
            }
            .width('100%')
            .margin({ top: 20 })
          }
          .width('100%')
          .padding({ left: 24, right: 24, top: 40, bottom: 20 })

          // B区：核心卡片区 (Core Cards)
          GlassCardContainer() {
            Row({ space: 12 }) {
              // 账户资产
              Column() {
                Text('💼').fontSize(24).margin({ bottom: 8 })
                Text('账户资产').fontSize('14fp').fontWeight(FontWeight.Medium).fontColor('#333')
              }
              .layoutWeight(1)
              .backgroundColor('rgba(255,255,255,0.6)')
              .borderRadius(16)
              .padding(16)
              .onClick(() => {
                router.pushUrl({ url: 'pages/AccountManagementPage' });
              })

              // 多人共享账本
              Column() {
                Text('👥').fontSize(24).margin({ bottom: 8 })
                Text('多人共享账本').fontSize('14fp').fontWeight(FontWeight.Medium).fontColor('#333')
              }
              .layoutWeight(1)
              .backgroundColor('rgba(255,255,255,0.6)')
              .borderRadius(16)
              .padding(16)
              .onClick(() => {
                router.pushUrl({ url: 'pages/SharedLedgerListPage' });
              })
            }
          }

          // C区：宫格菜单 (Grid Tools)
          GlassCardContainer() {
            Grid() {
              GridItem() {
                this.GridToolItem($r('app.media.ic_tag_linear'), '分类管理', () => {
                  router.pushUrl({ url: 'pages/CategoryManagement' });
                })
              }
              GridItem() {
                this.GridToolItem($r('app.media.ic_ai_brain_linear'), '智能规则', () => {
                  router.pushUrl({ url: 'pages/SmartCategoryRulesPage' });
                })
              }
              GridItem() {
                this.GridToolItem($r('app.media.ic_sync_linear'), '数据同步', () => {
                  router.pushUrl({ url: 'pages/SyncSettingsPage' });
                })
              }
              GridItem() {
                this.GridToolItem($r('app.media.ic_backup_linear'), '备份恢复', () => {
                  router.pushUrl({ url: 'pages/BackupPage' });
                })
              }
            }
            .columnsTemplate('1fr 1fr 1fr 1fr')
            .rowsGap(16)
            .height(80) 
          }

          // D区：列表菜单 (List Settings)
          GlassCardContainer() {
            Column() {
              this.ListItemRow('通知中心', this.unreadCount > 0, () => {
                router.pushUrl({ url: 'pages/NotificationCenterPage' });
              })
              this.ListItemRow('提醒设置', false, () => {
                router.pushUrl({ url: 'pages/ReminderSettingsPage' });
              })
              this.ListItemRow('应用设置', false, () => {
                router.pushUrl({ url: 'pages/AppSettingsPage' });
              }, true)
            }
          }

          // 退出登录按钮
          if (this.currentUser) {
            Button('退出登录')
              .width('80%')
              .height(48)
              .backgroundColor('#FFFFFF')
              .fontColor('#FF6B6B')
              .fontSize('16fp')
              .fontWeight(FontWeight.Medium)
              .shadow({ radius: 12, color: 'rgba(0,0,0,0.03)', offsetY: 4 })
              .margin({ top: 24, bottom: 40 })
              .onClick(() => {
                UserSessionService.logout();
                this.currentUser = null;
                promptAction.showToast({ message: '已退出登录' });
                router.replaceUrl({ url: 'pages/LoginPage' });
              })
          }
        }
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
    .linearGradient({ direction: GradientDirection.Bottom, colors: [['#E0F2E9', 0.0], ['#F4F8F5', 0.3], ['#F4F8F5', 1.0]] })
  }

  @Builder
  GridToolItem(iconRes: Resource, label: string, onClick: () => void) {
    Column() {
      Image(iconRes)
        .width(28)
        .height(28)
        .fillColor('#98D8C8')
        .opacity(0.8)
        .objectFit(ImageFit.Contain)
      Text(label).fontSize('12fp').fontColor('#666666').margin({ top: 8 })
    }
    .onClick(onClick)
  }

  @Builder
  ListItemRow(title: string, hasBadge: boolean, onClick: () => void, isLast: boolean = false) {
    Row() {
      Row() {
        Text(title).fontSize('14fp').fontColor('#333333')
        if (hasBadge) {
          Circle({ width: 8, height: 8 }).fill('#FF4B2B').margin({ left: 4 })
        }
      }
      Text('>')
        .fontSize('14fp')
        .fontColor('#CCCCCC')
    }
    .width('100%')
    .height(48)
    .justifyContent(FlexAlign.SpaceBetween)
    .border({ 
      width: { bottom: isLast ? 0 : 0.5 }, 
      color: 'rgba(0,0,0,0.05)' 
    })
    .onClick(onClick)
  }
}

