# Service 层说明

应用核心业务逻辑服务层，负责数据处理、用户管理、AI 功能等。

## 服务列表

### 用户与会话

- **UserSessionService**: 用户登录、注册、会话管理
- **CloudSyncService**: 数据云端同步（增量/双向同步）

### AI 智能功能

- **LLMService**: 大语言模型 API 集成，提供 AI 对话
- **ContextBuilder**: 为 AI 构建上下文信息
- **SmartCategoryService**: 智能分类推荐
- **SmartBudgetService**: 智能预算建议
- **OCRRecognitionService**: 票据 OCR 识别

### 数据分析与监控

- **AnomalyDetectionService**: 消费异常检测
- **EventSourcingService**: 事件溯源，记录数据变更历史

### 协作与提醒

- **SharedLedgerService**: 共享账本管理
- **ReminderService**: 提醒事项管理

### 数据导入导出

- **export/ExportService**: 导出数据（CSV/JSON）
- **export/ImportService**: 导入数据
- **export/EncryptionModule**: 数据加密模块
- **export/ChecksumHelper**: 文件校验
- **export/FileHelper**: 文件操作工具

## 快速使用

### 用户登录

```typescript
import { UserSessionService } from '../service/UserSessionService';

const userId = await UserSessionService.login(email, password);
if (UserSessionService.isLoggedIn()) {
  // 登录成功
}
```

### AI 对话

```typescript
import { LLMService } from '../service/LLMService';

const messages = [
  { role: 'user', content: '帮我分析本月消费' }
];
const reply = await LLMService.chat(messages);
```

### 数据同步

```typescript
import { CloudSyncService } from '../service/CloudSyncService';

await CloudSyncService.sync({
  userId: currentUserId,
  direction: 'bidirectional'
});
```
