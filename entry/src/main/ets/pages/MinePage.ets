import router from '@ohos.router';
import { UserSessionService, SessionInfo } from '../service/UserSessionService';
import { NotificationService } from '../service/NotificationService';
import { BillDAO } from '../dao/BillDAO';
import { promptAction } from '@kit.ArkUI';
import { AppTheme } from '../common/config/AppTheme';

@Component
struct GlassCardContainer {
  @BuilderParam content: () => void;

  build() {
    Column() {
      if (this.content) {
        this.content();
      }
    }
    .backgroundColor(AppTheme.CardBg)
    
    .borderRadius(24)
    
    .shadow(AppTheme.CardShadow)
    .margin({ left: 16, right: 16, bottom: 16 })
    .padding(24)
  }
}

@Component
export struct MinePage {
  @Prop @Watch('onRefreshTrigger') refreshTrigger: number = 0;
  @State currentUser: SessionInfo | null = null;
  @State unreadCount: number = 0;
  @State daysCount: number = 0;
  @State billsCount: number = 0;

  async aboutToAppear() {
    await this.reloadDashboardData();
  }

  onRefreshTrigger() {
    this.reloadDashboardData();
  }

  private async reloadDashboardData() {
    this.currentUser = await UserSessionService.getCurrentSession();
    await this.loadUnreadCount();
    await this.loadBillStats();
  }

  async loadUnreadCount() {
    try {
      this.unreadCount = await NotificationService.getUnreadCount();
    } catch (error) {
      console.error('[MinePage] Failed to load unread count:', error);
    }
  }

  async loadBillStats() {
    try {
      const userId = await UserSessionService.getCurrentUserId();
      if (!userId) {
        this.daysCount = 0;
        this.billsCount = 0;
        return;
      }

      const bills = await BillDAO.getByUserId(userId);
      this.billsCount = bills.length;

      const uniqueDays = new Set<string>();
      for (const bill of bills) {
        if (bill.transactionDate) {
          uniqueDays.add(bill.transactionDate.substring(0, 10));
        }
      }
      this.daysCount = uniqueDays.size;
    } catch (error) {
      console.error('[MinePage] Failed to load bill stats:', error);
      this.daysCount = 0;
      this.billsCount = 0;
    }
  }

  build() {
    Column() {
      Scroll() {
        Column() {
          Column() {
            Row() {
              Image($r('app.media.ic_user_avatar_glass'))
                .width(64)
                .height(64)
                .padding(10)
                .borderRadius(32)
                .backgroundColor(AppTheme.CardBg)
                .shadow(AppTheme.CardShadow)
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
                    .fontColor(AppTheme.TextMain)
                  Text(this.currentUser.email)
                    .fontSize('12fp')
                    .fontColor(AppTheme.TextSub)
                    .margin({ top: 4 })
                } else {
                  Text('点击登录')
                    .fontSize('18fp')
                    .fontWeight(FontWeight.Bold)
                    .fontColor(AppTheme.TextMain)
                    .onClick(() => {
                      router.pushUrl({ url: 'pages/LoginPage' });
                    })
                }
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
            }
            .width('100%')

            Row() {
              Row() {
                Text('记账天数 ')
                  .fontSize('14fp')
                  .fontColor(AppTheme.TextSub)
                Text(this.daysCount.toString())
                  .fontSize('18fp')
                  .fontWeight(FontWeight.Bolder)
                  .fontColor(AppTheme.TextMain)
              }
              .margin({ right: 24 })

              Row() {
                Text('记账笔数 ')
                  .fontSize('14fp')
                  .fontColor(AppTheme.TextSub)
                Text(this.billsCount.toString())
                  .fontSize('18fp')
                  .fontWeight(FontWeight.Bolder)
                  .fontColor(AppTheme.TextMain)
              }
            }
            .width('100%')
            .margin({ top: 20 })
          }
          .width('100%')
          .padding({ left: 24, right: 24, top: 56, bottom: 20 })
          .margin({ left: 16, right: 16, bottom: 16 })
          .backgroundColor(AppTheme.GlassBackground)
          .backdropBlur(30)
          .borderRadius(28)

          GlassCardContainer() {
            Row({ space: 12 }) {
              this.CoreActionCard($r('app.media.ic_wallet_glass'), '账户资产', () => {
                router.pushUrl({ url: 'pages/AccountManagementPage' });
              })

              this.CoreActionCard($r('app.media.ic_users_glass'), '多人共享账本', () => {
                router.pushUrl({ url: 'pages/SharedLedgerListPage' });
              })
            }
          }

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
              GridItem() {
                this.GridToolItem($r('app.media.ic_user_avatar_linear'), '我的画像', () => {
                  router.pushUrl({ url: 'pages/UserProfilePage' });
                })
              }
            }
            .columnsTemplate('1fr 1fr 1fr 1fr')
            .rowsGap(16)
            .height(160)
          }

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

          if (this.currentUser) {
            Button('退出登录')
              .width('80%')
              .height(48)
              .backgroundColor(AppTheme.HeroBg)
              .fontColor(AppTheme.TextWhite)
              .fontSize('16fp')
              .fontWeight(FontWeight.Medium)
              .shadow(AppTheme.FabShadow)
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
    .backgroundColor(AppTheme.Background)
  }

  @Builder
  CoreActionCard(icon: Resource, label: string, onClick: () => void) {
    Column() {
      Image(icon)
        .width(24)
        .height(24)
        .margin({ bottom: 8 })
      Text(label)
        .fontSize('14fp')
        .fontWeight(FontWeight.Medium)
        .fontColor(AppTheme.TextMain)
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(AppTheme.CardBg)
    .borderRadius(24)
    .padding(20)
    .shadow(AppTheme.CardShadow)
    .onClick(onClick)
  }

  @Builder
  GridToolItem(iconRes: Resource, label: string, onClick: () => void) {
    Column() {
      Image(iconRes)
        .width(28)
        .height(28)
        .fillColor(AppTheme.TextMain)
        .opacity(0.9)
        .objectFit(ImageFit.Contain)
      Text(label).fontSize('12fp').fontColor(AppTheme.TextSub).margin({ top: 8 })
    }
    .onClick(onClick)
  }

  @Builder
  ListItemRow(title: string, hasBadge: boolean, onClick: () => void, isLast: boolean = false) {
    Row() {
      Row() {
        Text(title).fontSize('14fp').fontColor(AppTheme.TextMain)
        if (hasBadge) {
          Circle({ width: 8, height: 8 }).fill(AppTheme.TextMain).margin({ left: 6 })
        }
      }
      Image($r('app.media.ic_chevron_right_glass'))
        .width(16)
        .height(16)
        .opacity(0.85)
    }
    .width('100%')
    .height(52)
    .justifyContent(FlexAlign.SpaceBetween)
    .border({
      width: { bottom: isLast ? 0 : 0.5 },
      color: AppTheme.Border
    })
    .onClick(onClick)
  }
}


