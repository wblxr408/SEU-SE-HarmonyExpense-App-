import router from '@ohos.router';
import { SharedLedgerService, BillSplit } from '../service/SharedLedgerService';
import { LedgerMember } from '../model/SharedLedger';
import { UserSessionService } from '../service/UserSessionService';
import { Category } from '../model/Category';
import { CategoryDAO } from '../dao/CategoryDAO';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct AddSharedBill {
  @State ledgerId: number = 0;
  @State amount: string = '';
  @State note: string = '';
  @State selectedDate: Date = new Date();
  
  @State members: LedgerMember[] = [];
  @State selectedMemberIds: number[] = []; // 参与分摊的成员ID
  
  @State categories: Category[] = [];
  @State selectedCategoryId: number = 0;
  @State selectedCategoryName: string = '';

  @State isLoading: boolean = false;

  aboutToAppear() {
    const params = router.getParams() as Record<string, number>;
    if (params && params.ledgerId) {
      this.ledgerId = params.ledgerId;
      this.loadData();
    } else {
      promptAction.showToast({ message: '参数错误' });
      router.back();
    }
  }

  async loadData() {
    this.isLoading = true;
    try {
      const userId = UserSessionService.getCurrentUserId();
      if (!userId) return;

      // 1. 获取成员
      this.members = await SharedLedgerService.getLedgerMembers(this.ledgerId);
      // 默认全选
      this.selectedMemberIds = this.members.map(m => m.userId);

      // 2. 获取分类 (默认获取支出的)
      this.categories = await CategoryDAO.getByType(userId, 'expense');
      if (this.categories.length > 0) {
        this.selectedCategoryId = this.categories[0].categoryId;
        this.selectedCategoryName = this.categories[0].name;
      }

    } catch (error) {
      console.error('[AddSharedBill] 加载数据失败:', error);
      promptAction.showToast({ message: '加载失败' });
    } finally {
      this.isLoading = false;
    }
  }

  toggleMemberSelection(userId: number) {
    const index = this.selectedMemberIds.indexOf(userId);
    if (index !== -1) {
      this.selectedMemberIds.splice(index, 1);
    } else {
      this.selectedMemberIds.push(userId);
    }
  }

  async handleSave() {
    if (!this.amount || parseFloat(this.amount) <= 0) {
      promptAction.showToast({ message: '请输入有效金额' });
      return;
    }
    if (this.selectedMemberIds.length === 0) {
      promptAction.showToast({ message: '请选择至少一位分摊成员' });
      return;
    }
    if (!this.selectedCategoryId) {
      promptAction.showToast({ message: '请选择分类' });
      return;
    }

    this.isLoading = true;
    try {
      const currentUser = UserSessionService.getCurrentSession();
      if (!currentUser) {
        promptAction.showToast({ message: '请先登录' });
        return;
      }

      const totalAmount = parseFloat(this.amount);
      const splitCount = this.selectedMemberIds.length;
      const perAmount = parseFloat((totalAmount / splitCount).toFixed(2));
      
      // 构建分摊数据 (简单均分)
      // 注意：由于四舍五入，最后一个人可能需要承担误差，或者 Service 层会校验
      // 这里我们在前端简单处理，Service的validateSplits 允许 0.01 误差
      
      const splits: BillSplit[] = this.selectedMemberIds.map((uid): BillSplit => {
        return {
          memberId: uid,
          amount: perAmount,
          percentage: parseFloat((100 / splitCount).toFixed(2))
        } as BillSplit;
      });

      // 修正总额误差 (把余数加到第一个人)
      const currentSum = splits.reduce((sum, s) => sum + s.amount, 0);
      const diff = totalAmount - currentSum;
      if (Math.abs(diff) > 0.0001) {
        splits[0].amount += diff;
        splits[0].amount = parseFloat(splits[0].amount.toFixed(2));
      }

      await SharedLedgerService.createSharedBill(
        this.ledgerId,
        currentUser.userId,
        currentUser.username,
        totalAmount,
        this.note || this.selectedCategoryName, // 描述默认为备注或分类名
        this.selectedCategoryId,
        this.selectedCategoryName,
        'equal',
        splits
      );

      promptAction.showToast({ message: '记账成功' });
      router.back();

    } catch (error) {
      console.error('[AddSharedBill] 保存失败:', error);
      promptAction.showToast({ message: '保存失败: ' + error.message });
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Column() {
      // Header
      Row() {
        Image($r('app.media.back')) // 假设有
          .width(24).height(24)
          .onClick(() => router.back())
          .margin({ right: 10 })
        Text('记一笔 (AA)')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
      }
      .width('100%').padding(16).backgroundColor(Color.White)

      Scroll() {
        Column({ space: 15 }) {
          // Amount
          Column() {
            Text('金额').fontSize(14).fontColor(Color.Gray).margin({bottom: 5})
            TextInput({ placeholder: '0.00', text: this.amount })
              .type(InputType.Number)
              .fontSize(30)
              .fontWeight(FontWeight.Bold)
              .fontColor('#F44336')
              .backgroundColor(Color.Transparent)
              .onChange((val) => this.amount = val)
          }
          .width('100%')
          .padding(15)
          .backgroundColor(Color.White)
          .borderRadius(12)

          // Category
          Column() {
            Text('分类').fontSize(14).fontColor(Color.Gray).margin({bottom: 10})
            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(this.categories, (cat: Category) => {
                Text(cat.name)
                  .fontSize(14)
                  .fontColor(this.selectedCategoryId === cat.categoryId ? Color.White : '#333')
                  .backgroundColor(this.selectedCategoryId === cat.categoryId ? '#F44336' : '#F0F0F0')
                  .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                  .borderRadius(15)
                  .margin({ right: 8, bottom: 8 })
                  .onClick(() => {
                    this.selectedCategoryId = cat.categoryId;
                    this.selectedCategoryName = cat.name;
                  })
              })
            }
          }
          .width('100%')
          .padding(15)
          .backgroundColor(Color.White)
          .borderRadius(12)

          // Note
          Column() {
            Text('备注').fontSize(14).fontColor(Color.Gray).margin({bottom: 5})
            TextInput({ placeholder: '例如：聚餐', text: this.note })
              .onChange((val) => this.note = val)
              .backgroundColor('#F9F9F9')
          }
          .width('100%')
          .padding(15)
          .backgroundColor(Color.White)
          .borderRadius(12)

          // Members Split
          Column() {
            Row() {
              Text('分摊成员').fontSize(14).fontColor(Color.Gray)
              Blank()
              Text(this.selectedMemberIds.length === this.members.length ? '全选' : `${this.selectedMemberIds.length}人`)
                .fontSize(12).fontColor(Color.Blue)
            }.width('100%').margin({bottom: 10})

            List({ space: 8 }) {
              ForEach(this.members, (member: LedgerMember) => {
                ListItem() {
                  Row() {
                    Checkbox({ name: 'member', group: 'split' })
                      .select(this.selectedMemberIds.includes(member.userId))
                      .onChange((val) => {
                        this.toggleMemberSelection(member.userId);
                      })
                    
                    Text(member.userName)
                      .fontSize(16)
                      .margin({ left: 10 })
                    
                    Blank()
                    
                    if (this.amount && this.selectedMemberIds.includes(member.userId)) {
                       Text(`¥${(parseFloat(this.amount) / this.selectedMemberIds.length).toFixed(2)}`)
                         .fontSize(14).fontColor(Color.Gray)
                    }
                  }
                  .width('100%')
                }
              })
            }
          }
          .width('100%')
          .padding(15)
          .backgroundColor(Color.White)
          .borderRadius(12)

        }
        .padding(15)
      }
      .layoutWeight(1)

      Button('保存')
        .width('90%')
        .height(50)
        .type(ButtonType.Capsule)
        .margin({ bottom: 20, top: 10 })
        .enabled(!this.isLoading)
        .onClick(() => this.handleSave())
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F1F3F5')
  }
}
