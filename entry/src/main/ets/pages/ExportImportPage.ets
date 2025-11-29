import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import fs from '@ohos.file.fs'; // 文件系统
import pasteboard from '@ohos.pasteboard'; // 剪贴板
import hilog from '@ohos.hilog';
import { Bill } from '../model/Bill';
import { BillDAO } from '../dao/BillDAO';
import { CategoryDAO } from '../dao/CategoryDAO';
import { AccountDAO } from '../dao/AccountDAO';


const LOG_TAG = 'ExportPage';
const HILOG_DOMAIN = 0x0001;

@Entry
@Component
struct ExportImportPage {
  @State csvContent: string = ''; // 生成的 CSV 内容
  @State importContent: string = ''; // 准备导入的内容
  @State isExporting: boolean = false;
  @State isImporting: boolean = false;
  @StorageProp('currentUserId') currentUserId: number = 1;

  // 导出逻辑
  async handleExport() {
    this.isExporting = true;
    try {
      // 1. 获取所有必要数据 (账单 + 字典数据)
      const bills = await BillDAO.getBillsByUserId(this.currentUserId);
      const categories = await CategoryDAO.getAll(this.currentUserId);
      const accounts = await AccountDAO.getByUserId(this.currentUserId);

      // 2. 创建 ID -> 名称 的查找表 (为了导出中文)
      const categoryMap = new Map<number, string>();
      categories.forEach(c => categoryMap.set(c.categoryId, c.name));

      const accountMap = new Map<number, string>();
      accounts.forEach(a => accountMap.set(a.accountId, a.name));

      // 3. 拼接 CSV 头部
      let csv = '日期,类型,金额,分类,账户,备注\n';

      // 4. 遍历拼接每一行
      bills.forEach(bill => {
        const typeStr = bill.type === 'expense' ? '支出' : '收入';
        const catName = categoryMap.get(bill.categoryId) || '未知分类';
        const accName = accountMap.get(bill.accountId) || '未知账户';
        // 处理备注中的逗号，防止破坏 CSV 格式
        const noteClean = (bill.note || '').replace(/,/g, '，');

        // CSV 格式: 2025-11-29,支出,100.00,餐饮,现金,午饭
        const line = `${bill.transactionDate},${typeStr},${bill.amount.toFixed(2)},${catName},${accName},${noteClean}\n`;
        csv += line;
      });

      this.csvContent = csv;
      promptAction.showToast({ message: `成功生成 ${bills.length} 条记录` });

    } catch (error) {
      hilog.error(HILOG_DOMAIN, LOG_TAG, '导出失败: %{public}s', JSON.stringify(error));
      promptAction.showToast({ message: '生成失败' });
    } finally {
      this.isExporting = false;
    }
  }

  // 功能 1.1: 复制到剪贴板 (最稳妥方案)
  copyToClipboard() {
    if (!this.csvContent) {
      promptAction.showToast({ message: '请先生成数据' });
      return;
    }
    const data = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.csvContent);
    const systemPasteboard = pasteboard.getSystemPasteboard();
    systemPasteboard.setData(data).then(() => {
      promptAction.showToast({ message: '已复制，可去微信粘贴' });
    });
  }

  // 功能 1.2: 保存到文件 (保存到应用沙箱)
  saveToFile() {
    if (!this.csvContent) return;
    try {
      // 获取应用沙箱路径 (用户无法直接在文件管理器看到，但适合内部备份)
      const context = getContext(this);
      const filePath = context.filesDir + '/backup_' + new Date().getTime() + '.csv';

      const file = fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      fs.writeSync(file.fd, this.csvContent);
      fs.closeSync(file);

      promptAction.showToast({ message: '保存成功: ' + filePath });
      hilog.info(HILOG_DOMAIN, LOG_TAG, '文件已保存至: ' + filePath);
    } catch (error) {
      promptAction.showToast({ message: '保存文件失败' });
    }
  }

  // --- 核心功能 2: 导入逻辑 ---
  async handleImport() {
    if (!this.importContent) {
      promptAction.showToast({ message: '请输入要导入的 CSV 内容' });
      return;
    }
    this.isImporting = true;
    let successCount = 0;

    try {
      const lines = this.importContent.trim().split('\n');
      // 1. 获取当前用户的分类和账户，用于反向查找 ID (这里简化处理：如果没有找到名字，就用默认ID)
      // 真正的导入应该比较复杂，这里做简化版：只导入金额和备注，分类/账户全部归为 "默认" (ID=1)
      // 或者你可以解析 CSV 里的分类名，去数据库查找对应的 ID

      for (let i = 1; i < lines.length; i++) { // 跳过标题行 (i=1)
        const line = lines[i];
        if (!line) continue;

        // 简单解析 CSV: 日期,类型,金额,分类,账户,备注
        const parts = line.split(',');
        if (parts.length < 3) continue;

        const date = parts[0];
        const typeStr = parts[1];
        const amount = parseFloat(parts[2]);
        const note = parts[5] || '';

        // 构建 Bill 对象
        const newBill = new Bill();
        newBill.userId = this.currentUserId;
        newBill.amount = amount;
        newBill.transactionDate = date;
        newBill.type = (typeStr === '收入') ? 'income' : 'expense';
        newBill.note = note;
        newBill.categoryId = 1; // 简化：导入的数据默认归为 ID=1 的分类
        newBill.accountId = 1;  // 简化：导入的数据默认归为 ID=1 的账户
        newBill.createdAt = new Date().toISOString();
        newBill.updatedAt = new Date().toISOString();

        await BillDAO.insert(newBill);
        successCount++;
      }

      promptAction.showToast({ message: `成功导入 ${successCount} 条记录` });
      this.importContent = ''; // 清空输入框

    } catch (error) {
      promptAction.showToast({ message: `导入出错: ${error.message}` });
    } finally {
      this.isImporting = false;
    }
  }

  build() {
    Navigation() {
      Scroll() {
        Column({ space: 20 }) {
          // --- 导出卡片 ---
          Column() {
            Text('数据导出').fontSize(18).fontWeight(FontWeight.Bold).width('100%')
            Text('将所有账单导出为 CSV 格式，可用于 Excel 查看。')
              .fontSize(14).fontColor(Color.Gray).margin({ bottom: 10 })

            Button(this.isExporting ? '生成中...' : '生成 CSV 数据')
              .onClick(() => this.handleExport())
              .width('100%')
              .enabled(!this.isExporting)

            if (this.csvContent) {
              TextArea({ text: this.csvContent })
                .height(100)
                .margin({ top: 10 })
                .fontSize(12)
                .fontColor(Color.Gray)
                .focusable(false) // 只读

              Row({ space: 10 }) {
                Button('复制到剪贴板')
                  .onClick(() => this.copyToClipboard())
                  .layoutWeight(1)
                  .backgroundColor('#4CAF50') // 绿色

                Button('保存到文件')
                  .onClick(() => this.saveToFile())
                  .layoutWeight(1)
                  .backgroundColor('#2196F3') // 蓝色
              }.margin({ top: 10 }).width('100%')
            }
          }
          .padding(15)
          .backgroundColor(Color.White)
          .borderRadius(12)

          // --- 导入卡片 ---
          Column() {
            Text('数据导入').fontSize(18).fontWeight(FontWeight.Bold).width('100%')
            Text('粘贴 CSV 内容以恢复数据（格式需与导出一致）。')
              .fontSize(14).fontColor(Color.Gray).margin({ bottom: 10 })

            TextArea({ placeholder: '在此粘贴 CSV 内容...', text: this.importContent })
              .height(100)
              .onChange((val) => this.importContent = val)
              .fontSize(12)

            Button(this.isImporting ? '导入中...' : '开始导入')
              .onClick(() => this.handleImport())
              .width('100%')
              .margin({ top: 10 })
              .enabled(!this.isImporting)
              .backgroundColor('#FF9800') // 橙色
          }
          .padding(15)
          .backgroundColor(Color.White)
          .borderRadius(12)

        }
        .padding(15)
      }
      .height('100%')
      .align(Alignment.Top)
      .backgroundColor('#F1F3F5')
    }
    .title('导出与导入')
    .titleMode(NavigationTitleMode.Mini)
  }
}