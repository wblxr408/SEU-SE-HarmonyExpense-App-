# Service 层文档 - 业务逻辑与服务封装

本目录包含应用程序的核心业务逻辑和服务层封装。这些服务处理数据流、用户会话、云端同步以及智能功能。

## 文件列表

### 核心服务
- **UserSessionService.ets** - 用户会话管理（登录、注册、注销）
- **DatabaseManager.ets** - 数据库管理（初始化、事务、优化）
- **NotificationService.ets** - 通知服务
- **AppSettingsService.ets** - 应用设置服务

### 数据服务
- **CloudSyncService.ets** - 数据云端同步服务
- **ReminderService.ets** - 提醒事项管理服务
- **DemoDataService.ets** - 演示数据服务（一键生成测试数据）

### 智能功能服务（v2.0.0新增）
- **SmartCategoryService.ets** - 智能分类服务（关键词匹配、习惯学习）
- **AnomalyDetectionService.ets** - 异常消费检测服务
- **SmartBudgetService.ets** - 智能预算分析服务
- **OCRRecognitionService.ets** - OCR票据识别服务
- **SharedLedgerService.ets** - 共享账本服务
- **EventSourcingService.ets** - 事件溯源服务

### 辅助服务
- **ContextBuilder.ets** - 上下文构建器
- **export/** - 数据导出与导入相关服务
  - **ExportService.ets** - 导出数据为 CSV/JSON
  - **ImportService.ets** - 从文件导入数据
  - **EncryptionModule.ets** - 数据加密模块
  - **FileHelper.ets** - 文件操作助手
  - **ChecksumHelper.ets** - 校验和计算

### 模块导出
- **index.ets** - 统一导出

---

## 核心服务说明

### 1. 用户会话服务 (UserSessionService)

管理用户的登录状态和会话信息。

**主要功能：**
- `login(email, password)` - 用户登录
- `register(username, email, password)` - 用户注册
- `logout()` - 注销当前用户
- `getCurrentUserId()` - 获取当前登录用户的 ID
- `isLoggedIn()` - 检查当前是否已登录
- `hashPassword(password)` - SHA-256 密码哈希

**会话管理：**
- 会话有效期：24 小时
- Token 格式：`{userId}_{timestamp}_{randomString}`

### 2. 云端同步服务 (CloudSyncService)

负责将本地数据库的数据同步到云端，支持增量同步和双向同步。

**主要功能：**
- `sync(options)` - 执行同步任务
- `getSyncHistory(userId)` - 获取同步历史记录
- `cancelSync(userId)` - 取消正在进行的同步
- `getLastSyncTime(userId)` - 获取上次同步时间

**同步选项：**
- 同步类型：全量 / 增量
- 同步方向：上传 / 下载 / 双向
- 冲突解决：最后写入获胜（Last-Write-Wins）

### 3. 提醒服务 (ReminderService)

管理用户的定时提醒，如每日记账提醒、预算超支提醒等。

**主要功能：**
- `createReminder(reminder)` - 创建提醒
- `updateReminder(reminder)` - 更新提醒
- `deleteReminder(reminderId)` - 删除提醒
- `checkAndTriggerReminders()` - 检查并触发到期提醒
- `calculateNextReminderDate(frequency)` - 计算下次提醒时间

**提醒频率：**
- once - 仅一次
- daily - 每天
- weekly - 每周
- monthly - 每月
- yearly - 每年

### 4. 演示数据服务 (DemoDataService)

一键生成完整的演示数据，用于功能展示。

**生成内容：**
- 多级分类（含子分类）
- 多个账户
- 历史账单（多月份）
- 标签数据
- 预算配置
- 提醒设置
- 智能分类规则
- 异常检测记录

---

## 智能功能服务

### 5. 智能分类服务 (SmartCategoryService)

基于关键词匹配和用户习惯学习，自动推荐账单分类。

**主要功能：**
- `recommendCategory(note)` - 根据备注推荐分类
- `learnFromBill(bill)` - 从账单中学习用户习惯
- `addKeywordRule(keyword, categoryId)` - 添加关键词规则
- `getRecommendations(userId, note)` - 获取分类推荐列表

**推荐策略：**
1. 精确关键词匹配
2. 商家名称匹配
3. 金额范围匹配
4. 历史习惯推荐

### 6. 异常消费检测服务 (AnomalyDetectionService)

检测用户账单中的异常消费模式。

**主要功能：**
- `detectAnomalies(bill)` - 检测账单异常
- `updateBaseline(userId)` - 更新消费基准线
- `getAnomalyHistory(userId)` - 获取异常历史
- `markAsRead(anomalyId)` - 标记异常为已读

**检测类型：**
- 高额支出（high_amount）
- 低额异常（low_amount）
- 频率激增（frequency_spike）
- 异常时间（unusual_time）
- 异常分类（unusual_category）
- 模式突变（pattern_break）

**检测算法：**
- 3σ法则
- Z-Score
- IQR（四分位距）
- 移动平均
- 集成算法（Ensemble）

### 7. 智能预算服务 (SmartBudgetService)

提供智能预算分析和消费预测。

**主要功能：**
- `calculateHealthScore(userId)` - 计算预算健康度
- `forecastSpending(userId, months)` - 预测未来消费
- `generateBudgetAdvice(userId)` - 生成预算建议
- `analyzeTrends(userId)` - 分析消费趋势

**预测算法：**
- 简单移动平均（SMA）
- 加权移动平均（WMA）
- 指数平滑（ETS）
- Holt-Winters
- 线性回归
- 集成预测（Ensemble）

### 8. OCR识别服务 (OCRRecognitionService)

票据图片识别，自动提取消费信息。

**主要功能：**
- `recognizeReceipt(imagePath)` - 识别票据
- `extractBillData(ocrResult)` - 提取账单数据
- `suggestCategory(merchantName)` - 推荐分类

**识别内容：**
- 商家名称
- 交易金额
- 交易日期
- 票据类型
- 明细列表

**支持票据类型：**
- 超市小票
- 餐饮发票
- 交通票据
- 加油票
- 医疗票据
- 酒店账单
- 网购订单
- 银行回单

### 9. 共享账本服务 (SharedLedgerService)

多人协作记账功能。

**账本管理：**
- `createLedger(ledger)` - 创建账本
- `updateLedger(ledger)` - 更新账本
- `deleteLedger(ledgerId)` - 删除账本
- `getLedgersByUser(userId)` - 获取用户账本

**成员管理：**
- `inviteMember(ledgerId, email)` - 邀请成员
- `acceptInvitation(invitationId)` - 接受邀请
- `declineInvitation(invitationId)` - 拒绝邀请
- `removeMember(memberId)` - 移除成员
- `updateMemberRole(memberId, role)` - 更新角色

**共享账单：**
- `addSharedBill(bill)` - 添加共享账单
- `splitBill(billId, splitDetails)` - 账单分摊
- `getSettlementStatus(ledgerId)` - 结算状态

**账本类型：**
- personal - 个人
- family - 家庭
- couple - 情侣
- roommate - 室友
- team - 团队
- project - 项目

### 10. 事件溯源服务 (EventSourcingService)

基于 CQRS 架构的事件溯源实现。

**事件管理：**
- `publishEvent(event)` - 发布事件
- `replayEvents(aggregateId)` - 重放事件
- `getEventHistory(aggregateId)` - 获取事件历史

**快照管理：**
- `createSnapshot(aggregate)` - 创建快照
- `loadFromSnapshot(snapshotId)` - 从快照恢复

**读模型：**
- `updateReadModel(event)` - 更新读模型
- `queryReadModel(query)` - 查询读模型

---

## 导入导出服务 (export/)

### ExportService - 导出服务

- `exportData(userId, options)` - 导出数据
- 支持格式：JSON、CSV、Excel
- 支持加密导出

### ImportService - 导入服务

- `importData(filePath, password)` - 导入数据
- 数据验证和冲突处理
- 事务化导入

### EncryptionModule - 加密模块

- AES-256-GCM 加密算法
- PBKDF2 密钥派生（100,000 次迭代）
- 16 字节随机盐值

---

## 使用示例

### 检查登录状态
```typescript
import { UserSessionService } from '../service/UserSessionService';

if (UserSessionService.isLoggedIn()) {
  const userId = UserSessionService.getCurrentUserId();
  console.log('当前用户ID:', userId);
} else {
  router.pushUrl({ url: 'pages/LoginPage' });
}
```

### 智能分类推荐
```typescript
import { SmartCategoryService } from '../service/SmartCategoryService';

const recommendations = await SmartCategoryService.getRecommendations(
  userId, 
  '肯德基早餐'
);
if (recommendations.length > 0) {
  console.log('推荐分类:', recommendations[0].categoryName);
}
```

### 异常检测
```typescript
import { AnomalyDetectionService } from '../service/AnomalyDetectionService';

const result = await AnomalyDetectionService.detectAnomalies(bill);
if (result.isAnomaly) {
  console.log('检测到异常:', result.anomalyType, result.severity);
}
```

---

## 注意事项

1. **异步操作**：大多数服务方法都是异步的（`Promise`），调用时请使用 `await`
2. **单例模式**：部分服务内部维护了静态状态，在应用生命周期内保持一致
3. **数据安全**：`CloudSyncService` 和 `UserSessionService` 中包含加密逻辑
4. **错误处理**：所有服务都会抛出详细的错误信息

---

*文档最后更新：2025年12月27日*
