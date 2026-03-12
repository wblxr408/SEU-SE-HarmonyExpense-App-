import router from '@ohos.router';
import { Category } from '../model/Category'
import { CategoryDAO } from '../dao/CategoryDAO'
import { CategoryTreeNode } from '../model/AggregationTypes'
import promptAction from '@ohos.promptAction'
import hilog from '@ohos.hilog'
import type { BusinessError } from '@ohos.base'
import { BreakPointType } from '../common/config/BreakpointSystem';
import { UserSessionService } from '../service/UserSessionService';

// HILOG 定义
const LOG_TAG = 'CategoryManagement'
const HILOG_DOMAIN = 0x0001

// 扁平化的树形节点（用于列表渲染）
interface FlatTreeItem {
  category: Category;
  level: number;       // 层级深度（0=顶级，1=一级子分类...）
  hasChildren: boolean; // 是否有子分类
  isExpanded: boolean;  // 是否展开
}

// ---------------------------------
// (C/U) 新建/编辑分类的弹窗
// ---------------------------------
@CustomDialog
struct CategoryEditDialog {
  controller: CustomDialogController
  editingCategory: Category | null = null
  // 可选父分类列表（不包含自己及其子分类）
  availableParents: Category[] = []
  onSave: () => void = () => {}

  build() {
    if (this.editingCategory) {
      Scroll() {
        Column({ space: 15 }) {
          TextInput({
            placeholder: '分类名称',
            text: this.editingCategory.name
          })
            .onChange((value: string) => {
              if (this.editingCategory) {
                this.editingCategory.name = value
              }
            })

          TextInput({
            placeholder: '图标 (如: 💪)',
            text: this.editingCategory.icon
          })
            .onChange((value: string) => {
              if (this.editingCategory) {
                this.editingCategory.icon = value
              }
            })

          TextInput({
            placeholder: '颜色 (例如: #FF6B6B)',
            text: this.editingCategory.color
          })
            .onChange((value: string) => {
              if (this.editingCategory) {
                this.editingCategory.color = value
              }
            })

          // 类型选择：支出 / 收入
          Tabs({
            index: this.editingCategory.type === 'expense' ? 0 : 1
          }) {
            TabContent().tabBar('支出')
            TabContent().tabBar('收入')
          }
          .barMode(BarMode.Fixed)
          .onChange((index: number) => {
            if (this.editingCategory) {
              this.editingCategory.type = (index === 0) ? 'expense' : 'income'
            }
          })

          // 父分类选择器
          Column({ space: 5 }) {
            Text('父分类')
              .fontSize(14)
              .fontColor('#666')
              .alignSelf(ItemAlign.Start)
            
            Select(this.buildParentOptions())
              .selected(this.getSelectedParentIndex())
              .value(this.getParentDisplayName())
              .font({ size: 16 })
              .fontColor('#333')
              .selectedOptionFont({ size: 16 })
              .optionFont({ size: 16 })
              .onSelect((index: number) => {
                if (this.editingCategory) {
                  if (index === 0) {
                    // 选择"无（顶级分类）"
                    this.editingCategory.parentCategoryId = 0
                  } else {
                    // 选择某个父分类
                    const parent = this.availableParents[index - 1]
                    this.editingCategory.parentCategoryId = parent.categoryId
                  }
                }
              })
          }
          .width('100%')

          // 操作按钮
          Row({ space: 10 }) {
            Button('取消')
              .onClick(() => {
                this.controller.close()
              })
              .layoutWeight(1)

            Button('保存')
              .onClick(() => {
                this.onSave()
              })
              .layoutWeight(1)
              .type(ButtonType.Capsule)
          }
          .width('100%')
          .margin({ top: 10 })
        }
        .padding(20)
        .width('90%')
      }
      .backgroundColor(Color.White)
      .borderRadius(15)
    } else {
      Column()
    }
  }

  // 构建父分类下拉选项
  buildParentOptions(): SelectOption[] {
    const options: SelectOption[] = [{ value: '无（顶级分类）' }]
    this.availableParents.forEach((cat: Category) => {
      options.push({ value: `${cat.icon} ${cat.name}` })
    })
    return options
  }

  // 获取当前选中的父分类索引
  getSelectedParentIndex(): number {
    if (!this.editingCategory || this.editingCategory.parentCategoryId === 0) {
      return 0
    }
    const idx = this.availableParents.findIndex((cat: Category) => 
      cat.categoryId === this.editingCategory!.parentCategoryId
    )
    return idx >= 0 ? idx + 1 : 0
  }

  // 获取父分类显示名称
  getParentDisplayName(): string {
    if (!this.editingCategory || this.editingCategory.parentCategoryId === 0) {
      return '无（顶级分类）'
    }
    const parent = this.availableParents.find((cat: Category) => 
      cat.categoryId === this.editingCategory!.parentCategoryId
    )
    return parent ? `${parent.icon} ${parent.name}` : '无（顶级分类）'
  }
}


// 分类管理主页面
@Entry
@Component
struct CategoryManagement {
  @State flatItems: FlatTreeItem[] = []           // 扁平化的树形列表
  @State allCategories: Category[] = []           // 所有分类（用于父分类选择）
  @State expandedIds: Set<number> = new Set()     // 展开的分类 ID
  @State currentEditingCategory: Category | null = null
  @State currentType: 'expense' | 'income' = 'expense'  // 当前显示的分类类型
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'md';
  
  // 响应式配置
  private listPadding = new BreakPointType({ xs: 8, sm: 10, md: 12, lg: 16, xl: 20, xxl: 24 });
  private itemFontSize = new BreakPointType({ xs: 14, sm: 15, md: 16, lg: 18, xl: 20, xxl: 22 });
  private buttonWidth = new BreakPointType({ xs: '95%', sm: '92%', md: '90%', lg: '80%', xl: '70%', xxl: '60%' });

  // 获取可用的父分类列表（排除自己及其子分类）
  getAvailableParents(): Category[] {
    if (!this.currentEditingCategory) return this.allCategories
    
    const editingId = this.currentEditingCategory.categoryId
    if (editingId === 0) {
      // 新建时，只能选择同类型的顶级分类
      return this.allCategories.filter((cat: Category) => 
        cat.type === this.currentEditingCategory!.type && cat.parentCategoryId === 0
      )
    }
    
    // 编辑时，排除自己和自己的子分类
    const excludeIds = new Set<number>([editingId])
    this.collectChildIds(editingId, excludeIds)
    
    return this.allCategories.filter((cat: Category) => 
      cat.type === this.currentEditingCategory!.type && 
      !excludeIds.has(cat.categoryId) &&
      cat.parentCategoryId === 0  // 只能选择顶级分类作为父分类
    )
  }

  // 递归收集子分类 ID
  collectChildIds(parentId: number, ids: Set<number>) {
    this.allCategories.forEach((cat: Category) => {
      if (cat.parentCategoryId === parentId) {
        ids.add(cat.categoryId)
        this.collectChildIds(cat.categoryId, ids)
      }
    })
  }

  // 自定义弹窗控制器
  dialogController: CustomDialogController | null = null

  onPageShow() {
    if (!UserSessionService.getCurrentUserId()) {
       promptAction.showToast({ message: '登录已过期，请重新登录' });
       setTimeout(() => {
          router.replaceUrl({ url: 'pages/LoginPage' });
       }, 500);
       return;
    }
    this.loadCategories()
  }

  async loadCategories() {
    try {
      const userId =await UserSessionService.getCurrentUserId();
      if (!userId) throw new Error('未登录');
      
      // 1. 加载所有分类（用于父分类选择）
      this.allCategories = await CategoryDAO.getAll(userId)
      
      // 2. 加载树形结构
      const tree = await CategoryDAO.getCategoryTree(userId, this.currentType)
      
      // 3. 将树形结构扁平化
      this.flatItems = this.flattenTree(tree, 0)
      
      hilog.info(HILOG_DOMAIN, LOG_TAG, `成功加载 ${this.flatItems.length} 条分类`)
    } catch (err) {
      const e = err as BusinessError;
      this.showToast(`加载分类失败: ${e.message}`);
    }
  }

  // 将树形结构扁平化为列表
  flattenTree(nodes: CategoryTreeNode[], level: number): FlatTreeItem[] {
    const result: FlatTreeItem[] = []
    
    nodes.forEach((node: CategoryTreeNode) => {
      const isExpanded = this.expandedIds.has(node.category.categoryId)
      const hasChildren = node.children.length > 0
      
      result.push({
        category: node.category,
        level: level,
        hasChildren: hasChildren,
        isExpanded: isExpanded
      })
      
      // 如果展开了，递归添加子分类
      if (isExpanded && hasChildren) {
        const children = this.flattenTree(node.children, level + 1)
        children.forEach((child: FlatTreeItem) => result.push(child))
      }
    })
    
    return result
  }

  // 切换展开/折叠状态
  toggleExpand(categoryId: number) {
    if (this.expandedIds.has(categoryId)) {
      this.expandedIds.delete(categoryId)
    } else {
      this.expandedIds.add(categoryId)
    }
    // 重新扁平化
    this.loadCategories()
  }

  async handleDelete(categoryId: number) {
    try {
      const userId =await UserSessionService.getCurrentUserId();
      if (!userId) throw new Error('未登录');
      await CategoryDAO.softDelete(userId, categoryId)
      this.showToast('删除成功')
      this.loadCategories()
    } catch (err) {
      const e = err as BusinessError;
      this.showToast(`删除失败: ${e.message}`);
    }
  }

  async handleSave() {
    if (!this.currentEditingCategory) return

    if (!this.currentEditingCategory.name) {
      this.showToast('分类名称不能为空')
      return
    }

    try {
      const now = new Date().toISOString()
      this.currentEditingCategory.updatedAt = now
      const userId = await UserSessionService.getCurrentUserId();
      if (!userId) throw new Error('未登录');

      if (this.currentEditingCategory.categoryId === 0) {
        // 新建
        this.currentEditingCategory.userId = userId
        this.currentEditingCategory.createdAt = now

        if (!this.currentEditingCategory.icon) {
           this.currentEditingCategory.icon = '📦';
        }
        if (!this.currentEditingCategory.color) {
           const randomColor = '#' + Math.floor(Math.random() * 16777215).toString(16).padStart(6, '0');
           this.currentEditingCategory.color = randomColor;
        }

        await CategoryDAO.insert(this.currentEditingCategory)
        this.showToast('创建成功')
      } else {
        // 更新
        await CategoryDAO.update(this.currentEditingCategory)
        this.showToast('更新成功')
      }

      if (this.dialogController) {
        this.dialogController.close();
      }
      this.currentEditingCategory = null
      this.loadCategories()

    } catch (err) {
      const e = err as BusinessError;
      this.showToast(`保存失败: ${e.message}`)
      hilog.error(HILOG_DOMAIN, LOG_TAG, '保存失败: %{public}s', `code=${e.code}, msg=${e.message}`)
    }
  }

  showToast(message: string) {
    try {
      promptAction.showToast({ message: message });
    } catch (err) {
      const e = err as BusinessError;
      hilog.error(HILOG_DOMAIN, LOG_TAG, 'showToast 失败: %{public}s', `code=${e.code}, msg=${e.message}`);
    }
  }

  // 打开新建分类弹窗
  openCreateDialog(parentId: number = 0) {
    const newCategory = new Category()
    newCategory.type = this.currentType
    newCategory.parentCategoryId = parentId
    this.currentEditingCategory = newCategory
    
    // 创建弹窗
    this.dialogController = new CustomDialogController({
      builder: CategoryEditDialog({
        editingCategory: this.currentEditingCategory,
        availableParents: this.getAvailableParents(),
        onSave: (): void => {
          this.handleSave()
        }
      }),
      autoCancel: false,
      alignment: DialogAlignment.Bottom
    })
    
    if (this.dialogController) {
      this.dialogController.open()
    }
  }

  // 打开编辑分类弹窗
  openEditDialog(category: Category) {
    this.currentEditingCategory = category.clone()
    
    // 创建弹窗
    this.dialogController = new CustomDialogController({
      builder: CategoryEditDialog({
        editingCategory: this.currentEditingCategory,
        availableParents: this.getAvailableParents(),
        onSave: (): void => {
          this.handleSave()
        }
      }),
      autoCancel: false,
      alignment: DialogAlignment.Bottom
    })
    
    if (this.dialogController) {
      this.dialogController.open()
    }
  }

  build() {
    Navigation() {
      Column() {
        // 类型切换标签
        Tabs({ index: this.currentType === 'expense' ? 0 : 1 }) {
          TabContent() {
            this.CategoryList()
          }.tabBar('支出分类')
          
          TabContent() {
            this.CategoryList()
          }.tabBar('收入分类')
        }
        .barMode(BarMode.Fixed)
        .onChange((index: number) => {
          this.currentType = index === 0 ? 'expense' : 'income'
          this.loadCategories()
        })
        .layoutWeight(1)

        // 新建按钮
        Button('新建分类')
          .width(this.buttonWidth.getValue(this.currentBreakpoint) as string)
          .height(50)
          .type(ButtonType.Capsule)
          .margin(15)
          .onClick(() => {
            this.openCreateDialog(0)
          })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F1F3F5')
    }
    .title('分类管理')
    .titleMode(NavigationTitleMode.Mini)
  }

  @Builder
  CategoryList() {
    List({ space: 8 }) {
      ForEach(this.flatItems, (item: FlatTreeItem, index: number) => {
        ListItem() {
          Row() {
            // 缩进（根据层级）
            if (item.level > 0) {
              Blank()
                .width(item.level * 24)
            }
            
            // 展开/折叠按钮
            if (item.hasChildren) {
              Text(item.isExpanded ? '▼' : '▶')
                .fontSize(12)
                .fontColor('#666')
                .width(20)
                .textAlign(TextAlign.Center)
                .margin({ right: 8 })
                .onClick(() => {
                  this.toggleExpand(item.category.categoryId)
                })
            } else {
              // 占位，保持对齐
              Blank()
                .width(28)
            }
            
            // 分类名称
            Text(item.category.name)
              .fontSize(this.itemFontSize.getValue(this.currentBreakpoint) as number)
              .layoutWeight(1)
            
            // 添加子分类按钮（仅顶级分类显示）
            if (item.level === 0) {
              Button({ type: ButtonType.Circle, stateEffect: true }) {
                Text('+')
                  .fontSize(18)
                  .fontColor('#666')
              }
              .width(28)
              .height(28)
              .backgroundColor('#E8E8E8')
              .margin({ right: 8 })
              .onClick(() => {
                this.openCreateDialog(item.category.categoryId)
              })
            }
          }
          .padding({ left: 12, right: 12, top: 12, bottom: 12 })
          .backgroundColor(Color.White)
          .borderRadius(8)
          .onClick(() => {
            this.openEditDialog(item.category)
          })
        }
        .swipeAction({ end: this.SwipeDeleteButton(item.category.categoryId) })
      })
    }
    .width('100%')
    .layoutWeight(1)
    .padding({ 
      left: this.listPadding.getValue(this.currentBreakpoint) as number, 
      right: this.listPadding.getValue(this.currentBreakpoint) as number,
      top: 10
    })
  }

  @Builder
  SwipeDeleteButton(categoryId: number) {
    Button('删除')
      .type(ButtonType.Circle)
      .backgroundColor(Color.Red)
      .onClick(() => {
        this.handleDelete(categoryId)
      })
  }
}