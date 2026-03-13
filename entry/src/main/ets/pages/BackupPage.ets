
import router from '@ohos.router';
import { ExportService } from '../service/export/services/ExportService';
import { ImportService } from '../service/export/services/ImportService';
import { ExportOptions } from '../service/export/types/ExportTypes';
import { UserSessionService } from '../service/UserSessionService';
import promptAction from '@ohos.promptAction';
import picker from '@ohos.file.picker';
import fs from '@ohos.file.fs';
import { AppTheme } from '../common/config/AppTheme';

@Entry
@Component
struct BackupPage {
  @State isProcessing: boolean = false;

  build(): void {
    Column() {
      Row() {
        Image($r('app.media.ic_back_glass'))
          .width(24)
          .height(24)
          .onClick(() => router.back())
        Text('数据备份与恢复')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppTheme.TextMain)
          .margin({ left: 16 })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 20, bottom: 12 })

      Column({ space: 20 }) {
        this.ActionCard(
          $r('app.media.ill_backup_export_glass'),
          '导出数据',
          '将账户、分类和账单打包为 JSON 文件，方便你做本地备份。',
          this.isProcessing ? '处理中...' : '导出备份',
          AppTheme.HeroBg,
          AppTheme.TextWhite,
          (): void => {
            void this.handleExport();
          }
        )

        this.ActionCard(
          $r('app.media.ill_backup_import_glass'),
          '恢复数据',
          '从备份文件恢复内容。恢复前请确认文件来源，避免覆盖当前数据。',
          this.isProcessing ? '处理中...' : '导入备份',
          AppTheme.HeroBg,
          AppTheme.TextWhite,
          (): void => {
            void this.handleImport();
          }
        )
      }
      .width('100%')
      .padding({ top: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppTheme.Background)
  }

  @Builder
  ActionCard(
    illustration: Resource,
    title: string,
    description: string,
    buttonLabel: string,
    buttonColor: string,
    buttonTextColor: string,
    onClick: () => void
  ): void {
    Column() {
      Image(illustration)
        .width(72)
        .height(72)
        .margin({ bottom: 12 })

      Text(title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppTheme.TextMain)

      Text(description)
        .fontSize(14)
        .fontColor(AppTheme.TextSub)
        .textAlign(TextAlign.Center)
        .margin({ top: 6, bottom: 20 })

      Button(buttonLabel)
        .type(ButtonType.Capsule)
        .width('80%')
        .height(48)
        .enabled(!this.isProcessing)
        .backgroundColor(buttonColor)
        .fontColor(buttonTextColor)
        .onClick(onClick)
    }
    .width('90%')
    .padding(24)
    .backgroundColor(AppTheme.CardBg)
    
    .border({ width: 0.5, color: AppTheme.Border })
    .borderRadius(24)
    .shadow(AppTheme.CardShadow)
  }

  async handleExport(): Promise<void> {
    this.isProcessing = true;
    const userId = await UserSessionService.getCurrentUserId();
    if (!userId) {
      promptAction.showToast({ message: '请先登录' });
      this.isProcessing = false;
      return;
    }

    try {
      const options: ExportOptions = {
        format: 'json',
        encrypt: false,
        includeDeleted: false
      };

      const filePath = await ExportService.exportUserData(userId, options);

      AlertDialog.show({
        title: '导出成功',
        message: `备份文件已生成\n${filePath}\n\n建议你将文件复制到安全位置保存。`,
        confirm: {
          value: '知道了',
          action: () => {}
        }
      });
    } catch (error) {
      const errorMsg: string = error instanceof Error ? error.message : String(error);
      promptAction.showToast({ message: `导出失败: ${errorMsg}` });
    } finally {
      this.isProcessing = false;
    }
  }

  async handleImport(): Promise<void> {
    this.isProcessing = true;
    try {
      const documentSelectOptions = new picker.DocumentSelectOptions();
      documentSelectOptions.maxSelectNumber = 1;
      documentSelectOptions.fileSuffixFilters = ['.json', '.enc'];

      const documentViewPicker = new picker.DocumentViewPicker();
      const documentSelectResult = await documentViewPicker.select(documentSelectOptions);

      if (documentSelectResult && documentSelectResult.length > 0) {
        const selectedUri = documentSelectResult[0];
        promptAction.showToast({ message: '开始导入...' });

        const result = await ImportService.importUserData(selectedUri);
        if (result.success) {
          AlertDialog.show({
            title: '导入成功',
            message: `成功恢复:\n账户: ${result.imported.accounts}\n分类: ${result.imported.categories}\n账单: ${result.imported.bills}`,
            confirm: { value: '好的', action: () => {} }
          });
        } else {
          AlertDialog.show({
            title: '导入包含错误',
            message: `主要数据已导入，但有 ${result.errors.length} 个错误，请查看日志。`,
            confirm: { value: '确定', action: () => {} }
          });
        }
      }
    } catch (error) {
      const errorMsg: string = error instanceof Error ? error.message : String(error);
      promptAction.showToast({ message: `导入失败: ${errorMsg}` });
    } finally {
      this.isProcessing = false;
    }
  }
}
