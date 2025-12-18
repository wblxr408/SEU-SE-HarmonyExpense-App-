import router from '@ohos.router';
import { CloudSyncService, SyncOptions, SyncResult } from '../service/CloudSyncService';
import { UserSessionService } from '../service/UserSessionService';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct SyncSettingsPage {
  @State lastSyncTime: string | null = null;
  @State isSyncing: boolean = false;
  @State autoSync: boolean = false; // 模拟设置，实际应持久化

  async onPageShow() {
    const userId = UserSessionService.getCurrentUserId();
    if (userId) {
      this.lastSyncTime = await CloudSyncService.getLastSyncTime(userId);
    }
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Image($r('app.media.back'))
          .width(24)
          .height(24)
          .onClick(() => router.back())
        Text('数据同步')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })
      }
      .width('100%')
      .padding(16)
      .backgroundColor(Color.White)

      // 设置列表
      List() {
        ListItem() {
          Row() {
            Column() {
              Text('自动同步')
                .fontSize(16)
              Text('仅在 Wi-Fi 环境下自动同步数据')
                .fontSize(12)
                .fontColor(Color.Gray)
                .margin({ top: 4 })
            }
            .alignItems(HorizontalAlign.Start)
            
            Blank()
            
            Toggle({ type: ToggleType.Switch, isOn: this.autoSync })
              .onChange((isOn: boolean) => {
                this.autoSync = isOn;
                // TODO: 保存设置
              })
          }
          .width('100%')
          .padding(16)
          .backgroundColor(Color.White)
        }

        ListItem() {
          Column() {
            Button(this.isSyncing ? '同步中...' : '立即同步')
              .width('90%')
              .height(50)
              .type(ButtonType.Capsule)
              .enabled(!this.isSyncing)
              .onClick(async () => {
                await this.startSync();
              })
            
            if (this.lastSyncTime) {
              Text(`上次同步: ${this.lastSyncTime.replace('T', ' ').split('.')[0]}`)
                .fontSize(12)
                .fontColor(Color.Gray)
                .margin({ top: 10 })
            }
          }
          .width('100%')
          .padding({ top: 30, bottom: 20 })
        }
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F1F3F5')
  }

  async startSync() {
    this.isSyncing = true;
    const userId = UserSessionService.getCurrentUserId();
    if (!userId) {
      promptAction.showToast({ message: '请先登录' });
      this.isSyncing = false;
      return;
    }

    try {
      const options = new SyncOptions(userId);
      const result: SyncResult = await CloudSyncService.sync(options);
      
      if (result.success) {
        promptAction.showToast({ message: `同步成功: 更新 ${result.recordCount} 条数据` });
        this.lastSyncTime = new Date().toISOString();
      } else {
        promptAction.showToast({ message: `同步失败: ${result.message}` });
      }
    } catch (error) {
       const errorMsg: string = error instanceof Error ? error.message : String(error);
      promptAction.showToast({ message: `发生错误: ${errorMsg}` });
    } finally {
      this.isSyncing = false;
    }
  }
}
