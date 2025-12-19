# Pages 功能与页面流转说明

本文档详细说明了 `pages` 目录下各个页面的功能、职责以及页面之间的跳转流转关系。

## 目录结构与核心流程

应用的核心流转路径如下：

1.  **启动与身份验证**:
    - 应用启动 -> 检查登录状态 (`Index.ets`)
    - 未登录 -> 跳转至 [登录页](LoginPage.ets)
    - 登录成功 -> 进入 [主页](Index.ets)

2.  **主页 (Index) 架构**:
    `Index.ets` 是应用的入口容器，包含底部的 Tab 导航，分别对应：
    - **Tab 0: 账本 (首页)**
    - **Tab 1: 统计报表**
    - **Tab 2: 我的 (个人中心)**

---

## 页面详细说明

### 1. 核心页面 (Core Pages)

#### [Index.ets](Index.ets) (APP首页 / 账本)
- **功能**: 展示账单列表、日期筛选、分类筛选。
- **流转**:
    - 点击 "记一笔" -> 跳转 [AddBill.ets](AddBill.ets)
    - 点击 "管理分类" -> 跳转 [CategoryManagement.ets](CategoryManagement.ets)
    - 底部导航 -> 切换至 [StatisticsPage.ets](StatisticsPage.ets) 或 [MinePage.ets](MinePage.ets)

#### [LoginPage.ets](LoginPage.ets) (登录)
- **功能**: 用户登录界面，支持邮箱/密码登录。
- **流转**:
    - 登录成功 -> 跳转至 `Index.ets`
    - 点击 "立即注册" -> 跳转至 [RegisterPage.ets](RegisterPage.ets)

#### [RegisterPage.ets](RegisterPage.ets) (注册)
- **功能**: 新用户注册。
- **流转**: 注册成功 -> 返回或跳转登录。

### 2. 主要功能模块 (Function Tabs)

#### [StatisticsPage.ets](StatisticsPage.ets) (统计)
- **功能**: 提供月度收支统计。
    - 支持按月筛选。
    - 支持 "收入/支出" 视图切换。
    - 展示每日趋势柱状图。
    - 展示分类排行列表（含进度条及百分比）。
- **注意**: 这是一个 Component，嵌入在 `Index.ets` 的 TabContent 中。

#### [MinePage.ets](MinePage.ets) (我的)
- **功能**: 个人中心，展示用户信息及功能入口。
- **功能入口流转**:
    - **账户资产** -> 跳转 [AccountManagementPage.ets](AccountManagementPage.ets)
    - **数据同步** -> 跳转 [SyncSettingsPage.ets](SyncSettingsPage.ets)
    - **备份与恢复** -> 跳转 [BackupPage.ets](BackupPage.ets)
    - **提醒设置** -> 跳转 [ReminderSettingsPage.ets](ReminderSettingsPage.ets)
    - **分类管理** -> 跳转 [CategoryManagement.ets](CategoryManagement.ets)
- **退出登录**: 清除 Session 并跳转回 `LoginPage.ets`。

### 3. 功能子页面 (Sub-feature Pages)

#### [AddBill.ets](AddBill.ets) (记账)
- **功能**: 添加新的收支记录。
- **位置**: 通常由 `Index.ets` 首页的 "记一笔" 按钮触发。

#### [CategoryManagement.ets](CategoryManagement.ets) (分类管理)
- **功能**: 管理支出和收入的类别（添加、删除、排序）。
- **位置**: 可从首页或个人中心进入。

#### [AccountManagementPage.ets](AccountManagementPage.ets) (账户资产管理)
- **功能**: 查看和管理各个资产账户（如银行卡、支付宝等）的余额。
- **位置**: 由 `MinePage` 进入。
- **注意**: 目录下存在一个类似的 `AccountManagement.ets`，请留意二者区别，当前 `MinePage` 使用的是 `AccountManagementPage.ets`。

### 4. 设置与工具 (Settings & Tools)

#### [SettingsPage.ets](SettingsPage.ets) (综合设置)
- **功能**: 包含更丰富的管理选项。
    - **分类管理**: `CategoryManagement`
    - **账户管理**: 跳转至 `AccountManagement` (注意这里链接的是 `AccountManagement.ets`)
    - **预算设置**: 跳转至 [BudgetManagement.ets](BudgetManagement.ets) (设置月度预算)
    - **数据导出与导入**: 跳转至 [ExportImportPage.ets](ExportImportPage.ets)
- **说明**: 此页面整合了高级功能，但在目前的 `MinePage` 中尚未发现直接入口，可能作为独立的设置页存在。

#### [BudgetManagement.ets](BudgetManagement.ets) (预算管理)
- **功能**: 设置和监控各类别的月度预算，显示超支/剩余状态。
- **入口**: 通过 `SettingsPage` 进入。

#### [ExportImportPage.ets](ExportImportPage.ets) (导入导出)
- **功能**: 数据的导出（Excel/CSV）与导入功能。
- **入口**: 通过 `SettingsPage` 进入。

#### [SyncSettingsPage.ets](SyncSettingsPage.ets) / [BackupPage.ets](BackupPage.ets) / [ReminderSettingsPage.ets](ReminderSettingsPage.ets)
- **功能**: 分别对应云同步设置、本地备份恢复、每日提醒功能设置。
- **入口**: 均有 `MinePage` 直接进入。

