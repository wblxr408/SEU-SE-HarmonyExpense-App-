import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import hilog from '@ohos.hilog';
import { SmartCategoryService } from '../service/SmartCategoryService';
import { SmartCategoryRule } from '../model/SmartCategory';
import { UserSessionService } from '../service/UserSessionService';
import { CategoryDAO } from '../dao/CategoryDAO';
import { Category } from '../model/Category';

const HILOG_DOMAIN = 0x0001;
const LOG_TAG = 'SmartCategoryRulesPage';

@Entry
@Component
struct SmartCategoryRulesPage {
  @State rules: SmartCategoryRule[] = [];
  @State categories: Category[] = [];
  @State isLoading: boolean = true;

  // Dialog controllers
  addRuleController: CustomDialogController = new CustomDialogController({
    builder: AddRuleDialog({
      categories: this.categories,
      onConfirm: (ruleName, categoryId, categoryName, keywords) => {
        this.addRule(ruleName, categoryId, categoryName, keywords);
      }
    }),
    autoCancel: true,
    customStyle: true
  });

  editRuleController: CustomDialogController | null = null;
  @State currentEditingRule: SmartCategoryRule | null = null;

  async aboutToAppear() {
    await this.loadData();
  }

  async loadData() {
    this.isLoading = true;
    try {
      const userId = UserSessionService.getCurrentUserId();
      if (!userId) {
        router.replaceUrl({ url: 'pages/LoginPage' });
        return;
      }

      // Load rules and categories
      this.rules = await SmartCategoryService.getUserRules(userId);
      this.categories = await CategoryDAO.getAll(userId);
      
    } catch (error) {
      hilog.error(HILOG_DOMAIN, LOG_TAG, 'Failed to load data: %{public}s', JSON.stringify(error));
      promptAction.showToast({ message: '加载数据失败' });
    } finally {
      this.isLoading = false;
    }
  }

  async addRule(ruleName: string, categoryId: number, categoryName: string, keywords: string) {
    const userId = UserSessionService.getCurrentUserId();
    if (!userId) return;

    try {
      await SmartCategoryService.createCustomRule(
        userId,
        ruleName,
        categoryId,
        categoryName,
        'keyword',
        '', // pattern (not used for keywords)
        keywords
      );
      promptAction.showToast({ message: '规则添加成功' });
      this.loadData(); // Refresh list
    } catch (error) {
      hilog.error(HILOG_DOMAIN, LOG_TAG, 'Failed to add rule: %{public}s', JSON.stringify(error));
      promptAction.showToast({ message: '添加规则失败' });
    }
  }

  async deleteRule(ruleId: number) {
    try {
      await SmartCategoryService.deleteRule(ruleId);
      promptAction.showToast({ message: '规则已删除' });
      // Enhance UX: Remove from local list immediately
      this.rules = this.rules.filter(r => r.ruleId !== ruleId);
    } catch (error) {
      hilog.error(HILOG_DOMAIN, LOG_TAG, 'Failed to delete rule: %{public}s', JSON.stringify(error));
      promptAction.showToast({ message: '删除规则失败' });
    }
  }

  async toggleRuleActive(rule: SmartCategoryRule, isOn: boolean) {
    try {
      await SmartCategoryService.toggleRule(rule.ruleId, isOn);
      // Update local state is handled by the toggle switch, but good to confirm
      rule.isActive = isOn ? 1 : 0;
    } catch (error) {
      hilog.error(HILOG_DOMAIN, LOG_TAG, 'Failed to toggle rule: %{public}s', JSON.stringify(error));
      promptAction.showToast({ message: '更新状态失败' });
      // Revert if failed
      rule.isActive = isOn ? 0 : 1;
    }
  }

  build() {
    Navigation() {
      Column() {
        if (this.isLoading) {
           LoadingProgress().width(50).height(50).margin({ top: 100 })
        } else if (this.rules.length === 0) {
           Column() {
             Text('暂无智能分类规则').fontSize(16).fontColor(Color.Gray).margin({ top: 100 })
             Text('添加规则后，记账时将自动推荐分类').fontSize(14).fontColor('#CCC').margin({ top: 10 })
           }.width('100%')
        } else {
           List() {
             ForEach(this.rules, (rule: SmartCategoryRule) => {
               ListItem() {
                 this.RuleItem(rule)
               }
               .swipeAction({ end: this.DeleteButton(rule.ruleId) })
             })
           }
           .width('100%')
           .layoutWeight(1)
           .padding({ left: 15, right: 15, top: 10 })
        }

        // Add Button
        Button('+ 添加规则')
          .width('90%')
          .height(50)
          .type(ButtonType.Capsule)
          .margin({ bottom: 20, top: 10 })
          .onClick(() => {
            this.addRuleController.open();
          })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F1F3F5')
    }
    .title('智能分类规则')
    .titleMode(NavigationTitleMode.Mini)
  }

  @Builder
  RuleItem(rule: SmartCategoryRule) {
    Row() {
      Column() {
        Row() {
          Text(rule.ruleName)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333')
          
          Text(rule.categoryName)
            .fontSize(12)
            .fontColor(Color.White)
            .backgroundColor('#4A90E2')
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            .borderRadius(10)
            .margin({ left: 10 })
        }
        .width('100%')
        
        Text(`关键词: ${rule.keywords}`)
          .fontSize(14)
          .fontColor(Color.Gray)
          .margin({ top: 5 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Toggle({ type: ToggleType.Switch, isOn: rule.isActive === 1 })
        .onChange((isOn: boolean) => {
          this.toggleRuleActive(rule, isOn);
        })
    }
    .width('100%')
    .padding(15)
    .backgroundColor(Color.White)
    .borderRadius(10)
    .margin({ bottom: 10 })
  }

  @Builder
  DeleteButton(ruleId: number) {
    Button({ type: ButtonType.Normal }) {
      Image($r('app.media.ic_public_delete'))
        .width(20)
        .height(20)
        .fillColor(Color.White)
    }
    .width(60)
    .height('100%')
    .backgroundColor(Color.Red)
    .onClick(() => {
      this.deleteRule(ruleId);
    })
  }
}

@CustomDialog
struct AddRuleDialog {
  controller: CustomDialogController;
  categories: Category[] = [];
  onConfirm: (ruleName: string, categoryId: number, categoryName: string, keywords: string) => void = () => {};

  @State ruleName: string = '';
  @State keywords: string = '';
  @State selectedIndex: number = 0;

  build() {
    Column() {
      Text('添加智能分类规则')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 })

      // Rule Name
      TextInput({ placeholder: '规则名称（如：打车规则）' })
        .onChange((value) => { this.ruleName = value; })
        .width('90%')
        .margin({ bottom: 15 })

      // Category Selection
      Row() {
        Text('分类：').fontSize(16)
        Select(this.categories.map(c => ({ value: c.name } as SelectOption)))
          .selected(this.selectedIndex)
          .value(this.categories.length > 0 ? this.categories[this.selectedIndex].name : '无分类')
          .onSelect((index) => {
            this.selectedIndex = index;
          })
          .font({ size: 16 })
          .layoutWeight(1)
      }
      .width('90%')
      .margin({ bottom: 15 })
      .padding({ left: 5 })

      // Keywords
      TextInput({ placeholder: '关键词（用空格分隔，如：滴滴 出租车）' })
        .onChange((value) => { this.keywords = value; })
        .width('90%')
        .margin({ bottom: 15 })
      
      Text('当账单备注包含上述关键词时，将自动推荐该分类')
        .fontSize(12)
        .fontColor(Color.Gray)
        .width('90%')
        .margin({ bottom: 20 })

      Row() {
        Button('取消')
          .onClick(() => { this.controller.close(); })
          .backgroundColor('#F5F5F5')
          .fontColor('#666')
          .width('40%')
          .margin({ right: 10 })
        
        Button('保存')
          .onClick(() => {
            if (!this.ruleName.trim() || !this.keywords.trim()) {
              promptAction.showToast({ message: '请填写完整' });
              return;
            }
            if (this.categories.length === 0) {
              promptAction.showToast({ message: '暂无分类可选' });
              return;
            }
            const selectedCategory = this.categories[this.selectedIndex];
            this.onConfirm(this.ruleName, selectedCategory.categoryId, selectedCategory.name, this.keywords);
            this.controller.close();
          })
          .width('40%')
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ bottom: 20 })
    }
    .width('85%')
    .borderRadius(12)
    .backgroundColor(Color.White)
  }
}
