import router from '@ohos.router';
import { ReminderService, ReminderCreateOptions } from '../service/ReminderService';
import { UserSessionService } from '../service/UserSessionService';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct ReminderSettingsPage {
  @State enableDailyReminder: boolean = false;
  @State reminderTime: Date = new Date(); // 默认当天的某个时间

  build() {
    Column() {
      // 标题栏
      Row() {
        Image($r('app.media.back'))
          .width(24)
          .height(24)
          .onClick(() => router.back())
        Text('提醒管理')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })
      }
      .width('100%')
      .padding(16)
      .backgroundColor(Color.White)

      List() {
        ListItem() {
          Row() {
            Text('每日记账提醒')
              .fontSize(16)
            Blank()
            Toggle({ type: ToggleType.Switch, isOn: this.enableDailyReminder })
              .onChange((isOn: boolean) => {
                this.enableDailyReminder = isOn;
                this.updateReminder();
              })
          }
          .width('100%')
          .padding(16)
          .backgroundColor(Color.White)
        }

        if (this.enableDailyReminder) {
          ListItem() {
            Row() {
              Text('提醒时间')
                .fontSize(16)
              Blank()
              
              // 使用 TimePicker 或者 Text + TimePickerDialog
              Text(this.formatTime(this.reminderTime))
                .fontSize(18)
                .fontColor(Color.Blue)
                .onClick(() => {
                  TimePickerDialog.show({
                    selected: this.reminderTime,
                    useMilitaryTime: true,
                    onAccept: (value: TimePickerResult) => {
                      this.reminderTime.setHours(value.hour, value.minute);
                      this.updateReminder();
                    }
                  })
                })
            }
            .width('100%')
            .padding(16)
            .backgroundColor(Color.White)
            .border({ width: { top: 1 }, color: '#F0F0F0' })
          }
        }
      }
      .width('100%')
      .margin({ top: 10 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F1F3F5')
  }

  formatTime(date: Date): string {
    const hours = date.getHours().toString().padStart(2, '0');
    const minutes = date.getMinutes().toString().padStart(2, '0');
    return `${hours}:${minutes}`;
  }

  async updateReminder() {
    // 这里简单调用 ReminderService 逻辑
    // 实际需要根据 switch 状态调用 createReminder (daily) 或 deleteReminder
    const userId = UserSessionService.getCurrentUserId();
    if (!userId) {
       promptAction.showToast({ message: '请先登录' });
       return;
    }
    
    if (this.enableDailyReminder) {
      try {
        const options = new ReminderCreateOptions(
           userId,
           'bill',
           '记账提醒',
           '今天记账了吗？保持好习惯哦~',
           'daily',
           this.reminderTime.toISOString()
        );
        await ReminderService.createReminder(options);
        
        try {
          promptAction.showToast({ message: '提醒已设置' });
        } catch (e) {}

      } catch (err) {

        try {
          promptAction.showToast({ message: '设置失败' });
        } catch (e) {}
      }
    } else {
      // 应该调用 logic 查找已存在的 "记账提醒" 并删除
      try {
        promptAction.showToast({ message: '提醒已关闭' });
      } catch (e) {}
    }
  }
}
