import router from '@ohos.router';
import { AnomalyDetectionService, AnomalyDetectionResult } from '../service/AnomalyDetectionService';
import { AnomalyRecord } from '../model/AnomalyDetection';
import { UserSessionService } from '../service/UserSessionService';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct AnomalyHistoryPage {
  @State anomalies: AnomalyRecord[] = [];
  @State isLoading: boolean = false;
  @State totalCount: number = 0;
  @State highRiskCount: number = 0;

  aboutToAppear() {
    this.loadData();
  }

  async loadData() {
    this.isLoading = true;
    try {
      const userId = UserSessionService.getCurrentUserId();
      if (!userId) {
        promptAction.showToast({ message: '请先登录' });
        return;
      }

      // 获取所有异常记录（这里暂时获取未确认的作为演示，实际可能需要所有记录的API）
      // 由于Service中目前暴露了getUnacknowledgedAnomalies，我们先用这个，或者我们可以扩展Service
      // 假设我们想要显示所有记录，可以先用 getUnacknowledgedAnomalies 模拟，或者查看DAO是否有 getAll
      // 查看DAO发现有 getByUserId，我们可以直接在Service加一个 getAll，或者直接调用DAO（不推荐直接调用DAO）
      // 简单起见，我们修改Service或者使用现有的 getUnacknowledgedAnomalies
      // 修正：查看之前的Service代码，发现只有 getUnacknowledgedAnomalies 和 getStatistics
      // 我们用 getStatistics 获取总数，用 getUnacknowledgedAnomalies 获取列表
      // 或者为了更好的体验，我们在Service加一个 getAllAnomalies (如果我有权限改Service)
      // 鉴于我是前端任务，我先用 getUnacknowledgedAnomalies 展示“未处理风险”，这也很合理。
      
      const records = await AnomalyDetectionService.getUnacknowledgedAnomalies(userId);
      console.info(`[AnomalyHistoryDebug] Records fetched: ${records.length}`);
      this.anomalies = records;
      
      this.totalCount = records.length;
      console.info(`[AnomalyHistoryDebug] totalCount set to: ${this.totalCount}`);

      this.highRiskCount = records.filter(r => r.severity === 'high' || r.severity === 'critical').length;
      console.info(`[AnomalyHistoryDebug] highRiskCount set to: ${this.highRiskCount}`);

    } catch (error) {
      console.error('[AnomalyHistoryPage] 加载失败:', error);
      promptAction.showToast({ message: '加载失败' });
    } finally {
      this.isLoading = false;
    }
  }

  getSeverityColor(severity: string): string {
    switch (severity) {
      case 'critical': return '#F44336'; // Red
      case 'high': return '#FF5722';    // Deep Orange
      case 'medium': return '#FF9800';  // Orange
      default: return '#4CAF50';        // Green
    }
  }

  getSeverityLabel(severity: string): string {
    switch (severity) {
      case 'critical': return '严重';
      case 'high': return '高风险';
      case 'medium': return '中风险';
      default: return '低风险';
    }
  }

  getAnomalyTitle(type: string): string {
    const map: Record<string, string> = {
      'high_amount': '金额过高',
      'low_amount': '金额异常',
      'frequency_spike': '交易频繁',
      'unusual_category': '分类异常',
      'pattern_break': '消费习惯改变'
    };
    return map[type] || '检测到异常';
  }

  async handleAcknowledge(record: AnomalyRecord) {
     try {
       await AnomalyDetectionService.acknowledgeAnomaly(record.anomalyId);
       promptAction.showToast({ message: '已标记为已读' });
       this.loadData(); // Reload
     } catch (e) {
       promptAction.showToast({ message: '操作失败' });
     }
  }

  build() {
    Column() {
      // Header
      Row() {
        Image($r('app.media.back')) // 假设有back图标，或者用Text
          .width(24).height(24)
          .onClick(() => router.back())
        Text('风险通知中心')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })
      }
      .width('100%').padding(16).backgroundColor(Color.White)

      // Summary Cards
      Row({ space: 15 }) {
        SummaryCard({ title: '待处理风险', count: this.totalCount, color: '#FF9800' })
        SummaryCard({ title: '高危预警', count: this.highRiskCount, color: '#F44336' })
      }
      .width('100%')
      .padding(15)

      // List
      List({ space: 10 }) {
        if (this.anomalies.length === 0) {
           ListItem() {
             Column() {
               Text('暂无未处理的风险通知').fontSize(16).fontColor(Color.Gray).margin({top: 50})
             }.width('100%').alignItems(HorizontalAlign.Center)
           }
        } else {
          ForEach(this.anomalies, (item: AnomalyRecord) => {
            ListItem() {
              Column() {
                Row() {
                  Text(this.getAnomalyTitle(item.anomalyType))
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                  Blank()
                  Text(this.getSeverityLabel(item.severity))
                    .fontSize(12)
                    .fontColor(Color.White)
                    .backgroundColor(this.getSeverityColor(item.severity))
                    .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                    .borderRadius(10)
                }
                .width('100%')
                .margin({ bottom: 8 })

                Text(item.description)
                  .fontSize(14)
                  .fontColor('#333')
                  .margin({ bottom: 8 })

                Row() {
                  Text(item.createdAt.substring(0, 10))
                    .fontSize(12)
                    .fontColor(Color.Gray)
                  Blank()
                  Button('我知道了')
                    .type(ButtonType.Normal)
                    .fontSize(12)
                    .fontColor(Color.Blue)
                    .backgroundColor(Color.Transparent)
                    .onClick(() => this.handleAcknowledge(item))
                }
                .width('100%')
              }
              .padding(15)
              .backgroundColor(Color.White)
              .borderRadius(10)
              .shadow({ radius: 2, color: '#E0E0E0', offsetY: 2 })
            }
          })
        }
      }
      .layoutWeight(1)
      .width('100%')
      .padding({ left: 15, right: 15, bottom: 15 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F1F3F5')
  }
}

@Component
struct SummaryCard {
  @Prop title: string;
  @Prop count: number;
  @Prop color: string;

  build() {
    Column() {
      Text(this.count.toString())
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.color)
        .margin({ bottom: 5 })
      Text(this.title)
        .fontSize(14)
        .fontColor(Color.Gray)
    }
    .layoutWeight(1)
    .height(80)
    .backgroundColor(Color.White)
    .borderRadius(10)
    .justifyContent(FlexAlign.Center)
    .shadow({ radius: 2, color: '#E0E0E0', offsetY: 2 })
  }
}
