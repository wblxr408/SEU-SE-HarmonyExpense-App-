/**
 * 通知中心页面
 * 显示系统通知列表，支持筛选和全部已读
 */

import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { NotificationService } from '../service/NotificationService';
import { Notification, NotificationType } from '../model/Notification';
import { AppTheme } from '../common/config/AppTheme';

@Entry
@Component
struct NotificationCenterPage {
  @State notifications: Notification[] = [];
  @State selectedTab: number = 0;
  @State isLoading: boolean = true;
  @State unreadCount: number = 0;

  private tabs: string[] = ['全部', '系统', '预算', '同步', '提醒'];
  private tabTypes: (NotificationType | null)[] = [
    null,
    NotificationType.SYSTEM,
    NotificationType.BUDGET_ALERT,
    NotificationType.SYNC_STATUS,
    NotificationType.REMINDER
  ];

  async aboutToAppear() {
    await this.loadNotifications();
  }

  async loadNotifications() {
    this.isLoading = true;
    try {
      const type = this.tabTypes[this.selectedTab];
      if (type === null) {
        this.notifications = await NotificationService.getNotifications(100);
      } else {
        this.notifications = await NotificationService.getByType(type);
      }
      this.unreadCount = await NotificationService.getUnreadCount();
    } catch (error) {
      console.error('[NotificationCenterPage] 加载通知失败:', error);
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Navigation() {
      Column() {
        // Tab 筛选
        Row() {
          ForEach(this.tabs, (tab: string, index: number) => {
            Text(tab)
              .fontSize(14)
              .fontColor(this.selectedTab === index ? AppTheme.TextMain : AppTheme.TextSub)
              .fontWeight(this.selectedTab === index ? FontWeight.Bold : FontWeight.Normal)
              .padding({ left: 12, right: 12, top: 8, bottom: 8 })
              .backgroundColor(this.selectedTab === index ? AppTheme.GlassBackground : Color.Transparent)
              .borderRadius(16)
              .onClick(() => {
                this.selectedTab = index;
                this.loadNotifications();
              })
          })
        }
        .width('100%')
        .padding(12)
        .justifyContent(FlexAlign.SpaceAround)

        // 全部已读按钮
        if (this.unreadCount > 0) {
          Row() {
            Text(`${this.unreadCount} 条未读`)
              .fontSize(14)
              .fontColor(AppTheme.TextSub)
              .layoutWeight(1)
            Text('全部已读')
              .fontSize(14)
              .fontColor(AppTheme.TextMain)
              .onClick(() => this.markAllAsRead())
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .backgroundColor(AppTheme.CardBg)
        }

        // 通知列表
        if (this.isLoading) {
          LoadingProgress()
            .width(50)
            .height(50)
            .margin({ top: 100 })
        } else if (this.notifications.length === 0) {
          // 空状态
          Column() {
            Text('🔔')
              .fontSize(60)
              .margin({ bottom: 16 })
            Text('暂无通知')
              .fontSize(16)
              .fontColor(AppTheme.TextSub)
          }
          .width('100%')
          .margin({ top: 100 })
        } else {
          List() {
            ForEach(this.notifications, (notification: Notification) => {
              ListItem() {
                this.NotificationItem(notification)
              }
            })
          }
          .width('100%')
          .layoutWeight(1)
          .divider({ strokeWidth: 1, color: AppTheme.Border, startMargin: 16 })
          .backgroundColor(AppTheme.CardBg)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(AppTheme.Background)
    }
    .title('通知中心')
    .titleMode(NavigationTitleMode.Mini)
  }

  @Builder
  NotificationItem(notification: Notification) {
    Row() {
      // 类型图标
      Text(this.getTypeIcon(notification.type))
        .fontSize(24)
        .width(40)
        .height(40)
        .textAlign(TextAlign.Center)
        .backgroundColor(notification.isRead === 0 ? AppTheme.GlassBackground : AppTheme.Background)
        .borderRadius(20)
        .margin({ right: 12 })

      Column() {
        Row() {
          Text(notification.title)
            .fontSize(16)
            .fontColor(AppTheme.TextMain)
            .fontWeight(notification.isRead === 0 ? FontWeight.Bold : FontWeight.Normal)
            .layoutWeight(1)
          if (notification.isRead === 0) {
            Circle()
              .width(8)
              .height(8)
              .fill(AppTheme.TextMain)
          }
        }
        .width('100%')

        Text(notification.content)
          .fontSize(14)
          .fontColor(AppTheme.TextSub)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 4 })

        Text(this.formatTime(notification.createdAt))
          .fontSize(12)
          .fontColor(AppTheme.TextSub)
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(20)
    .backgroundColor(AppTheme.CardBg)
    .onClick(() => this.markAsRead(notification))
  }

  getTypeIcon(type: NotificationType): string {
    switch (type) {
      case NotificationType.SYSTEM: return '📢';
      case NotificationType.BUDGET_ALERT: return '💰';
      case NotificationType.SYNC_STATUS: return '🔄';
      case NotificationType.REMINDER: return '⏰';
      default: return '🔔';
    }
  }

  formatTime(dateStr: string): string {
    if (!dateStr) return '';
    const date = new Date(dateStr);
    const now = new Date();
    const diff = now.getTime() - date.getTime();
    const minutes = Math.floor(diff / 60000);
    const hours = Math.floor(diff / 3600000);
    const days = Math.floor(diff / 86400000);

    if (minutes < 1) return '刚刚';
    if (minutes < 60) return `${minutes}分钟前`;
    if (hours < 24) return `${hours}小时前`;
    if (days < 7) return `${days}天前`;
    return `${date.getMonth() + 1}月${date.getDate()}日`;
  }

  async markAsRead(notification: Notification) {
    if (notification.isRead === 0) {
      await NotificationService.markAsRead(notification.notificationId);
      notification.isRead = 1;
      this.unreadCount = Math.max(0, this.unreadCount - 1);
    }
  }

  async markAllAsRead() {
    await NotificationService.markAllAsRead();
    this.notifications.forEach(n => n.isRead = 1);
    this.unreadCount = 0;
    promptAction.showToast({ message: '已全部标记为已读' });
  }
}
