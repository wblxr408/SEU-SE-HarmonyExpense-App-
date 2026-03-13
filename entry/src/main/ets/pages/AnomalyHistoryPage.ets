
import router from '@ohos.router';
import { AnomalyDetectionService, AnomalyDetectionResult } from '../service/AnomalyDetectionService';
import { AnomalyRecord } from '../model/AnomalyDetection';
import { UserSessionService } from '../service/UserSessionService';
import promptAction from '@ohos.promptAction';
import { AppTheme } from '../common/config/AppTheme';

@Entry
@Component
struct AnomalyHistoryPage {
  @State anomalies: AnomalyRecord[] = [];
  @State isLoading: boolean = false;
  @State totalCount: number = 0;
  @State highRiskCount: number = 0;

  async aboutToAppear(): Promise<void> {
    await this.loadData();
  }

  async loadData(): Promise<void> {
    this.isLoading = true;
    try {
      const userId = await UserSessionService.getCurrentUserId();
      if (!userId) {
        promptAction.showToast({ message: '璇峰厛鐧诲綍' });
        return;
      }

      // 鑾峰彇鎵€鏈夊紓甯歌褰曪紙杩欓噷鏆傛椂鑾峰彇鏈‘璁ょ殑浣滀负婕旂ず锛屽疄闄呭彲鑳介渶瑕佹墍鏈夎褰曠殑API锛?
      // 鐢变簬Service涓洰鍓嶆毚闇蹭簡getUnacknowledgedAnomalies锛屾垜浠厛鐢ㄨ繖涓紝鎴栬€呮垜浠彲浠ユ墿灞昐ervice
      // 鍋囪鎴戜滑鎯宠鏄剧ず鎵€鏈夎褰曪紝鍙互鍏堢敤 getUnacknowledgedAnomalies 妯℃嫙锛屾垨鑰呮煡鐪婦AO鏄惁鏈?getAll
      // 鏌ョ湅DAO鍙戠幇鏈?getByUserId锛屾垜浠彲浠ョ洿鎺ュ湪Service鍔犱竴涓?getAll锛屾垨鑰呯洿鎺ヨ皟鐢―AO锛堜笉鎺ㄨ崘鐩存帴璋冪敤DAO锛?
      // 绠€鍗曡捣瑙侊紝鎴戜滑淇敼Service鎴栬€呬娇鐢ㄧ幇鏈夌殑 getUnacknowledgedAnomalies
      // 淇锛氭煡鐪嬩箣鍓嶇殑Service浠ｇ爜锛屽彂鐜板彧鏈?getUnacknowledgedAnomalies 鍜?getStatistics
      // 鎴戜滑鐢?getStatistics 鑾峰彇鎬绘暟锛岀敤 getUnacknowledgedAnomalies 鑾峰彇鍒楄〃
      // 鎴栬€呬负浜嗘洿濂界殑浣撻獙锛屾垜浠湪Service鍔犱竴涓?getAllAnomalies (濡傛灉鎴戞湁鏉冮檺鏀筍ervice)
      // 閴翠簬鎴戞槸鍓嶇浠诲姟锛屾垜鍏堢敤 getUnacknowledgedAnomalies 灞曠ず鈥滄湭澶勭悊椋庨櫓鈥濓紝杩欎篃寰堝悎鐞嗐€?
      
      const records = await AnomalyDetectionService.getUnacknowledgedAnomalies(userId);
      console.info(`[AnomalyHistoryDebug] Records fetched: ${records.length}`);
      this.anomalies = records;
      
      this.totalCount = records.length;
      console.info(`[AnomalyHistoryDebug] totalCount set to: ${this.totalCount}`);

      this.highRiskCount = records.filter(r => r.severity === 'high' || r.severity === 'critical').length;
      console.info(`[AnomalyHistoryDebug] highRiskCount set to: ${this.highRiskCount}`);

    } catch (error) {
      console.error('[AnomalyHistoryPage] 鍔犺浇澶辫触:', error);
      promptAction.showToast({ message: '鍔犺浇澶辫触' });
    } finally {
      this.isLoading = false;
    }
  }

  getSeverityColor(severity: string): string {
    switch (severity) {
      case 'critical': return AppTheme.TextMain;
      case 'high': return '#3A3A3C';
      case 'medium': return AppTheme.TextSub;
      default: return '#B0B0B5';
    }
  }

  getSeverityLabel(severity: string): string {
    switch (severity) {
      case 'critical': return '涓ラ噸';
      case 'high': return '楂橀闄?';
      case 'medium': return '涓闄?';
      default: return '浣庨闄?';
    }
  }

  getAnomalyTitle(type: string): string {
    const map: Record<string, string> = {
      'high_amount': '閲戦杩囬珮',
      'low_amount': '閲戦寮傚父',
      'frequency_spike': '浜ゆ槗棰戠箒',
      'unusual_category': '鍒嗙被寮傚父',
      'pattern_break': '娑堣垂涔犳儻鏀瑰彉'
    };
    return map[type] || '妫€娴嬪埌寮傚父';
  }

  async handleAcknowledge(record: AnomalyRecord): Promise<void> {
     try {
       await AnomalyDetectionService.acknowledgeAnomaly(record.anomalyId);
       promptAction.showToast({ message: '宸叉爣璁颁负宸茶' });
       this.loadData(); // Reload
     } catch (e) {
       promptAction.showToast({ message: '鎿嶄綔澶辫触' });
     }
  }

  build() {
    Column() {
      // Header
      Row() {
        Image($r('app.media.ic_back_glass')) // 鍋囪鏈塨ack鍥炬爣锛屾垨鑰呯敤Text
          .width(24).height(24)
          .onClick(() => router.back())
        Text('椋庨櫓閫氱煡涓績')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })
      }
      .width('100%').padding(20).backgroundColor(AppTheme.CardBg)

      // Summary Cards
      Row({ space: 15 }) {
        SummaryCard({ title: '寰呭鐞嗛闄?', count: this.totalCount, color: AppTheme.TextSub })
        SummaryCard({ title: '楂樺嵄棰勮', count: this.highRiskCount, color: AppTheme.TextMain })
      }
      .width('100%')
      .padding(20)

      // List
      List({ space: 10 }) {
        if (this.anomalies.length === 0) {
           ListItem() {
             Column() {
               Text('鏆傛棤鏈鐞嗙殑椋庨櫓閫氱煡').fontSize(16).fontColor(AppTheme.TextSub).margin({top: 50})
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
                    .fontColor(AppTheme.TextWhite)
                    .backgroundColor(this.getSeverityColor(item.severity))
                    .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                    .borderRadius(24)
                }
                .width('100%')
                .margin({ bottom: 8 })

                Text(item.description)
                  .fontSize(14)
                  .fontColor(AppTheme.TextMain)
                  .margin({ bottom: 8 })

                Row() {
                  Text(item.createdAt.substring(0, 10))
                    .fontSize(12)
                    .fontColor(AppTheme.TextSub)
                  Blank()
                  Button('鎴戠煡閬撲簡')
                    .type(ButtonType.Normal)
                    .fontSize(12)
                    .fontColor(AppTheme.TextMain)
                    .backgroundColor(Color.Transparent)
                    .onClick(() => this.handleAcknowledge(item))
                }
                .width('100%')
              }
              .padding(20)
              .backgroundColor(AppTheme.CardBg)
              .borderRadius(24)
              .shadow({ radius: 2, color: AppTheme.Border, offsetY: 2 })
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
    .backgroundColor(AppTheme.Background)
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
        .fontColor(AppTheme.TextSub)
    }
    .layoutWeight(1)
    .height(80)
    .backgroundColor(AppTheme.CardBg)
    .borderRadius(24)
    .justifyContent(FlexAlign.Center)
    .shadow({ radius: 2, color: AppTheme.Border, offsetY: 2 })
  }
}

