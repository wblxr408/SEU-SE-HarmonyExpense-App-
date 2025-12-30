 /**
 * OCR扫描页面 - 拍照识别小票
 *
 * 功能：
 * 1. 选择图片/拍照
 * 2. OCR识别处理
 * 3. 预览识别结果
 * 4. 确认后跳转到记账页面
 */

import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { picker } from '@kit.CoreFileKit';
import { OCRRecognitionService, OCRRecognitionResult } from '../service/OCRRecognitionService';
import { UserSessionService } from '../service/UserSessionService';

@Entry
@Component
struct OCRScanPage {
  @State isProcessing: boolean = false;
  @State hasResult: boolean = false;
  @State selectedImagePath: string = '';

  // OCR识别结果
  @State merchantName: string = '';
  @State totalAmount: number = 0;
  @State transactionDate: string = '';
  @State suggestedCategoryId: number = 0;
  @State suggestedCategoryName: string = '';
  @State confidenceScore: number = 0;
  @State errorMessage: string = '';

  // 选择图片
  async selectImage() {
    try {
      const photoPicker = new picker.PhotoViewPicker();
      const result = await photoPicker.select({
        MIMEType: picker.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: 1
      });

      if (result.photoUris && result.photoUris.length > 0) {
        this.selectedImagePath = result.photoUris[0];
        this.hasResult = false;
        this.errorMessage = '';

        // 开始识别
        await this.processOCR();
      }
    } catch (err) {
      let error = err as Error;
      console.error('[OCRScanPage] 选择图片失败:', error);
      promptAction.showToast({ message: '选择图片失败' });
    }
  }

  // 执行OCR识别
  async processOCR() {
    const userId = UserSessionService.getCurrentUserId();
    if (!userId) {
      promptAction.showToast({ message: '请先登录' });
      return;
    }

    this.isProcessing = true;
    this.errorMessage = '';

    try {
      const result: OCRRecognitionResult = await OCRRecognitionService.recognizeReceipt({
        userId: userId,
        imagePath: this.selectedImagePath,
        provider: 'huawei_ml_kit'
      });

      if (result.success) {
        this.merchantName = result.merchantName;
        this.totalAmount = result.totalAmount;
        this.transactionDate = result.transactionDate;
        this.suggestedCategoryId = result.suggestedCategoryId;
        this.suggestedCategoryName = result.suggestedCategoryName;
        this.confidenceScore = result.confidenceScore;
        this.hasResult = true;
      } else {
        this.errorMessage = result.error || '识别失败，请重试';
      }
    } catch (err) {
      let error = err as Error;
      console.error('[OCRScanPage] OCR识别失败:', error);
      this.errorMessage = '识别过程出错，请重试';
    } finally {
      this.isProcessing = false;
    }
  }

  // 使用识别结果，跳转到记账页面
  useResult() {
    router.pushUrl({
      url: 'pages/AddBill',
      params: {
        prefilledAmount: this.totalAmount.toString(),
        prefilledNote: this.merchantName,
        prefilledCategoryId: this.suggestedCategoryId,
        prefilledDate: this.transactionDate
      }
    });
  }

  // 重新选择图片
  retry() {
    this.hasResult = false;
    this.selectedImagePath = '';
    this.errorMessage = '';
  }

  build() {
    Navigation() {
      Column() {
        // 主内容区域
        if (this.isProcessing) {
          // 加载中状态
          Column() {
            LoadingProgress()
              .width(80)
              .height(80)
              .color('#4A90E2')

            Text('正在识别小票...')
              .fontSize(16)
              .fontColor('#666')
              .margin({ top: 20 })
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)

        } else if (this.hasResult) {
          // 识别结果预览
          Column({ space: 15 }) {
            Text('识别结果')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 10 })

            // 结果卡片
            Column({ space: 12 }) {
              // 商家
              Row() {
                Text('商家')
                  .fontSize(14)
                  .fontColor('#888')
                  .width(80)
                Text(this.merchantName || '未识别')
                  .fontSize(16)
                  .fontColor('#333')
                  .layoutWeight(1)
              }
              .width('100%')

              Divider()

              // 金额
              Row() {
                Text('金额')
                  .fontSize(14)
                  .fontColor('#888')
                  .width(80)
                Text(`¥ ${this.totalAmount.toFixed(2)}`)
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#E74C3C')
                  .layoutWeight(1)
              }
              .width('100%')

              Divider()

              // 日期
              Row() {
                Text('日期')
                  .fontSize(14)
                  .fontColor('#888')
                  .width(80)
                Text(this.transactionDate || '今天')
                  .fontSize(16)
                  .fontColor('#333')
                  .layoutWeight(1)
              }
              .width('100%')

              Divider()

              // 推荐分类
              Row() {
                Text('分类')
                  .fontSize(14)
                  .fontColor('#888')
                  .width(80)
                Text(this.suggestedCategoryName || '其他')
                  .fontSize(16)
                  .fontColor('#4A90E2')
                  .layoutWeight(1)
              }
              .width('100%')

              // 置信度
              Row() {
                Text('置信度')
                  .fontSize(14)
                  .fontColor('#888')
                  .width(80)
                Progress({ value: this.confidenceScore * 100, total: 100, type: ProgressType.Linear })
                  .width(150)
                  .height(8)
                Text(`${(this.confidenceScore * 100).toFixed(0)}%`)
                  .fontSize(12)
                  .fontColor('#888')
                  .margin({ left: 10 })
              }
              .width('100%')
            }
            .width('100%')
            .padding(20)
            .backgroundColor(Color.White)
            .borderRadius(12)
            .shadow({ radius: 4, color: '#1A000000', offsetX: 0, offsetY: 2 })

            // 操作按钮
            Row({ space: 15 }) {
              Button('重新选择')
                .type(ButtonType.Normal)
                .width('45%')
                .height(50)
                .backgroundColor('#F0F0F0')
                .fontColor('#333')
                .borderRadius(25)
                .onClick(() => this.retry())

              Button('使用结果')
                .type(ButtonType.Normal)
                .width('45%')
                .height(50)
                .backgroundColor('#4A90E2')
                .fontColor(Color.White)
                .borderRadius(25)
                .onClick(() => this.useResult())
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .margin({ top: 30 })
          }
          .width('100%')
          .padding(20)
          .layoutWeight(1)

        } else if (this.errorMessage) {
          // 错误状态
          Column({ space: 20 }) {
            Text('😕')
              .fontSize(60)

            Text(this.errorMessage)
              .fontSize(16)
              .fontColor('#E74C3C')
              .textAlign(TextAlign.Center)

            Button('重新选择图片')
              .type(ButtonType.Capsule)
              .width('60%')
              .height(45)
              .backgroundColor('#4A90E2')
              .onClick(() => this.selectImage())
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)

        } else {
          // 初始状态 - 引导选择图片
          Column({ space: 30 }) {
            // 图标
            Text('📷')
              .fontSize(80)

            Text('扫描小票')
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333')

            Text('拍照或选择小票图片，自动识别金额和商家信息')
              .fontSize(14)
              .fontColor('#888')
              .textAlign(TextAlign.Center)
              .padding({ left: 40, right: 40 })

            // 选择图片按钮
            Button('选择图片')
              .type(ButtonType.Capsule)
              .width('70%')
              .height(50)
              .fontSize(18)
              .backgroundColor('#4A90E2')
              .margin({ top: 20 })
              .onClick(() => this.selectImage())

            // 提示
            Text('支持超市小票、餐饮发票等常见票据')
              .fontSize(12)
              .fontColor('#AAA')
              .margin({ top: 30 })
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F5F5')
    }
    .title('扫描小票')
    .titleMode(NavigationTitleMode.Mini)
  }
}
