# 待迭代part简要说明

## ✅ 已完成 - v1.2.0更新

### common\Constants.ets
- ~~目前只是单例系统，后期接入真实登陆系统时应该替换成实际ID~~
- **已完成**: 实现了 `UserSessionService` 用户会话管理服务
- **状态**: `CURRENT_USER_ID` 已标记为 `@deprecated`，建议使用 `UserSessionService.getCurrentUserId()`
- **迁移指南**: 详见 `README说明/高级功能实现文档.md`

### 高级功能实现
- **已完成**: 定期账单/预算提醒功能
  - 模型: `model/Reminder.ets`
  - DAO: `dao/ReminderDAO.ets`
  - 服务: `service/ReminderService.ets`
  - 支持多种频率: once, daily, weekly, monthly, yearly
  - 集成HarmonyOS通知管理器

- **已完成**: 数据云端同步功能
  - 模型: `model/CloudSyncRecord.ets`
  - DAO: `dao/CloudSyncRecordDAO.ets`
  - 服务: `service/CloudSyncService.ets`
  - 支持上传、下载、双向同步
  - 支持全量和增量同步
  - 预留云端API接口（需实际集成）

### 数据库更新
- **已完成**: 新增 `reminders` 表及索引
- **已完成**: 新增 `cloud_sync_records` 表及索引
- **已完成**: 更新 `DatabaseManager` 创建新表

---

## 待优化项

### common\DAOHelper.ets
- 对于事务处理函数的异步与否的警告处理
- 建议: 统一异步事务处理模式

### 高级功能待完善

#### 用户会话管理
- [ ] 多设备登录管理
- [ ] 记住密码功能
- [ ] 第三方登录（微信、华为账号等）
- [ ] 密码找回功能
- [ ] 更安全的密码加密方案（PBKDF2或bcrypt）

#### 提醒功能
- [ ] 提醒声音和振动设置
- [ ] 提醒延后功能
- [ ] 提醒历史记录
- [ ] 智能提醒（根据用户习惯）
- [ ] 后台任务定期检查提醒

#### 云端同步
- [ ] 真实云端API集成（当前为模拟实现）
- [ ] 冲突解决策略实现
- [ ] 同步进度显示
- [ ] 断点续传
- [ ] 数据压缩
- [ ] 网络状态检查
- [ ] 同步队列管理

---

## 前端UI待实现

### 用户相关页面
- [ ] 登录页面
- [ ] 注册页面
- [ ] 用户设置页面
- [ ] 会话管理页面

### 提醒相关页面
- [ ] 提醒列表页面
- [ ] 创建/编辑提醒页面
- [ ] 提醒详情页面
- [ ] 提醒统计页面

### 云端同步相关页面
- [ ] 同步设置页面
- [ ] 同步历史页面
- [ ] 同步状态显示
- [ ] 冲突解决界面

---

## 测试待完善

### 单元测试
- [ ] UserSessionService 测试
- [ ] ReminderService 测试
- [ ] CloudSyncService 测试
- [ ] ReminderDAO 测试
- [ ] CloudSyncRecordDAO 测试

### 集成测试
- [ ] 登录流程测试
- [ ] 提醒触发测试
- [ ] 云端同步流程测试

---

## 文档更新

### 已完成
- ✅ 高级功能实现文档
- ✅ 用户会话管理说明
- ✅ 提醒功能使用指南
- ✅ 云端同步集成指南

### 待完善
- [ ] API文档更新
- [ ] 用户使用手册
- [ ] 开发者指南更新
- [ ] 部署文档（云端API部署）

