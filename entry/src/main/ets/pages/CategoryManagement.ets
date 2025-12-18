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
const EMPTY_CALLBACK = () => {};

@CustomDialog
struct CategoryEditDialog {
  controller: CustomDialogController
  @Link editingCategory: Category | null


  // onSave 默认值
  onSave: () => void = EMPTY_CALLBACK

  build() {

    if (this.editingCategory) {
      Scroll() {
        Column({ space: 10 }) {
          Text(this.editingCategory.categoryId === 0 ? '新建分类' : '编辑分类')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .textAlign(TextAlign.Start)

          TextInput({
            placeholder: '分类名称',
            text: this.editingCategory.name
          })
            .onChange((value: string) => { 
              if (this.editingCategory) {
                this.editingCategory.name = value
              }
            })



          //
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
          .margin({ top: 5 })
        }
        .padding(15)
        .width('90%')
      } // Scroll 结束
      .backgroundColor(Color.White)
      .borderRadius(15)
    } else {
      // 当 editingCategory 为 null 时
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

  // 页面显示时加载数据
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

  // 删除逻辑
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

  //  保存逻辑
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
        // Create 新建 
        this.currentEditingCategory.userId = this.currentUserId
        this.currentEditingCategory.createdAt = now

        // 默认值处理
        if (!this.currentEditingCategory.icon) {
           this.currentEditingCategory.icon = ''; // 不需要图标
        }
        if (!this.currentEditingCategory.color) {
           // 生成随机颜色
           const randomColor = '#' + Math.floor(Math.random() * 16777215).toString(16).padStart(6, '0');
           this.currentEditingCategory.color = randomColor;
        }

        await CategoryDAO.insert(this.currentEditingCategory) //
        this.showToast('创建成功')
      } else {
        //Update 更新
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

  // 封装一个安全的 showToast 函数
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
            //  修复：使用 .swipeAction 属性，而不是 SwipeAction() 组件
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
        .width('100%') // 修复：添加 width 消除 List 警告
        .padding({ left: 12, right: 12 })

        // 新建按钮
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

  //
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