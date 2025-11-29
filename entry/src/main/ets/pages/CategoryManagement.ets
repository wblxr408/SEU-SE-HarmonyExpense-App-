// 导入
import { Category } from '../model/Category' //
import { CategoryDAO } from '../dao/CategoryDAO' //
import promptAction from '@ohos.promptAction'
import hilog from '@ohos.hilog'
import type { BusinessError } from '@ohos.base'
// ✅ 修复：删除未使用的 router 导入
// import router from '@ohos.router'

// HILOG 定义
const LOG_TAG = 'CategoryManagement'
const HILOG_DOMAIN = 0x0001


// ---------------------------------
// (C/U) 新建/编辑分类的弹窗
// ---------------------------------
@CustomDialog
struct CategoryEditDialog {
  controller: CustomDialogController
  // ✅ 修复 1 (闪退): 允许 editingCategory 为 null，以匹配父组件的类型
  @Link editingCategory: Category | null

  // onSave 默认值
  onSave: () => void = () => {}

  build() {
    // ✅ 修复 2 (闪退):
    // 必须检查 editingCategory 是否为 null。
    // 当父组件在关闭弹窗时将其设为 null，这个 if 会保护弹窗不崩溃。
    if (this.editingCategory) {
      Scroll() {
        Column({ space: 15 }) {
          Text(this.editingCategory.categoryId === 0 ? '新建分类' : '编辑分类')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .textAlign(TextAlign.Start) // 保持文本居左

          TextInput({
            placeholder: '分类名称',
            text: this.editingCategory.name
          })
            .onChange((value: string) => { // ✅ 修复：添加 (value: string)
              if (this.editingCategory) { // 再次检查，确保安全
                this.editingCategory.name = value
              }
            })

          TextInput({
            placeholder: '图标 🍽️',
            text: this.editingCategory.icon
          })
            .onChange((value: string) => { // ✅ 修复：添加 (value: string)
              if (this.editingCategory) {
                this.editingCategory.icon = value
              }
            })

          TextInput({
            placeholder: '颜色 (例如: #FF6B6B)',
            text: this.editingCategory.color
          })
            .onChange((value: string) => { // ✅ 修复：添加 (value: string)
              if (this.editingCategory) {
                this.editingCategory.color = value
              }
            })

          // ✅ 修复：barMode 是链式调用
          Tabs({
            index: this.editingCategory.type === 'expense' ? 0 : 1
          }) {
            TabContent().tabBar('支出')
            TabContent().tabBar('收入')
          }
          .barMode(BarMode.Fixed)
          .onChange((index: number) => { // ✅ 修复：添加 (index: number)
            if (this.editingCategory) {
              this.editingCategory.type = (index === 0) ? 'expense' : 'income'
            }
          })

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
      } // Scroll 结束
      .backgroundColor(Color.White)
      .borderRadius(15)
    } else {
      // 当 editingCategory 为 null 时 (例如父组件正在关闭它)
      // 渲染一个空的 Column 来避免崩溃
      Column()
    }
  }
}


//  分类管理主页面
@Entry
@Component
struct CategoryManagement {
  @State categories: Array<Category> = []
  @State currentEditingCategory: Category | null = null
  @StorageProp('currentUserId') currentUserId: number = 1;
  // 自定义弹窗控制器
  dialogController: CustomDialogController = new CustomDialogController({
    builder: CategoryEditDialog({
      editingCategory: $currentEditingCategory,
      onSave: () => {
        this.handleSave()
      }
    }),
    autoCancel: false,
    alignment: DialogAlignment.Bottom
  })

  // (R) 页面显示时加载数据
  onPageShow() {
    this.loadCategories()
  }

  async loadCategories() {
    try {
      const data = await CategoryDAO.getAll(this.currentUserId) //
      this.categories = data
      hilog.info(HILOG_DOMAIN, LOG_TAG, `成功加载 ${data.length} 条分类`)
    } catch (err) {
      const e = err as BusinessError;
      this.showToast(`加载分类失败: ${e.message}`);
    }
  }

  // (D) 删除逻辑
  async handleDelete(categoryId: number) {
    try {
      await CategoryDAO.softDelete(this.currentUserId, categoryId) //
      this.showToast('删除成功')
      this.loadCategories()
    } catch (err) {
      const e = err as BusinessError;
      this.showToast(`删除失败: ${e.message}`);
    }
  }

  // (C / U) 保存逻辑
  async handleSave() {
    if (!this.currentEditingCategory) return

    // 简单校验
    if (!this.currentEditingCategory.name) {
      this.showToast('分类名称不能为空')
      return // 验证失败，不关闭弹窗
    }

    try {
      const now = new Date().toISOString()
      this.currentEditingCategory.updatedAt = now

      if (this.currentEditingCategory.categoryId === 0) {
        // --- (C) Create 新建 ---
        this.currentEditingCategory.userId = this.currentUserId
        this.currentEditingCategory.createdAt = now
        await CategoryDAO.insert(this.currentEditingCategory) //
        this.showToast('创建成功')
      } else {
        // --- (U) Update 更新 ---
        await CategoryDAO.update(this.currentEditingCategory) //
        this.showToast('更新成功')
      }

      // 关键：在所有 await 操作成功后，才在这里关闭弹窗！
      this.dialogController.close();

      // 在关闭后才清空状态
      this.currentEditingCategory = null
      this.loadCategories()

    } catch (err) { //
      const e = err as BusinessError;
      this.showToast(`保存失败: ${e.message}`)
      hilog.error(HILOG_DOMAIN, LOG_TAG, '保存失败: %{public}s', `code=${e.code}, msg=${e.message}`)
      // 失败时不关闭弹窗
    }
  }

  // ✅ 修复：封装一个安全的 showToast 函数
  showToast(message: string) {
    try {
      promptAction.showToast({ message: message });
    } catch (err) {
      const e = err as BusinessError;
      hilog.error(HILOG_DOMAIN, LOG_TAG, 'showToast 失败: %{public}s', `code=${e.code}, msg=${e.message}`);
    }
  }

  build() {
    Navigation() {
      Column() {
        // (R) 列表展示
        List({ space: 10 }) {
          ForEach(this.categories, (item: Category) => {
            // ✅ 修复：使用 .swipeAction 属性，而不是 SwipeAction() 组件
            ListItem() {
              // (U) 列表项
              Row() {
                Text(item.icon).fontSize(20).width(30)
                Text(item.name).fontSize(16).layoutWeight(1)
                Text(item.type === 'expense' ? '支出' : '收入')
                  .fontSize(14)
                  .fontColor(item.type === 'expense' ? Color.Red : Color.Green)
              }
              .padding(15)
              .backgroundColor(Color.White)
              .borderRadius(8)
              .onClick(() => {
                // (U) 点击时，弹出编辑窗口
                this.currentEditingCategory = item.clone() // 关键：使用 clone() 避免直接修改列表
                this.dialogController.open()
              })
            } // ListItem 结束
            .swipeAction({ end: this.SwipeDeleteButton(item.categoryId) })
          })
        }
        .layoutWeight(1)
        .width('100%') // ✅ 修复：添加 width 消除 List 警告
        .padding({ left: 12, right: 12 })

        // (C) 新建按钮
        Button('新建分类')
          .width('90%')
          .height(50)
          .type(ButtonType.Capsule)
          .margin(15)
          .onClick(() => {
            // (C) 点击时，弹出新建窗口
            this.currentEditingCategory = new Category() // 关键：传入一个空对象
            this.dialogController.open()
          })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F1F3F5')
    }
    .title('分类管理')
    .titleMode(NavigationTitleMode.Mini)
  }

  // (D) 滑动删除的按钮
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