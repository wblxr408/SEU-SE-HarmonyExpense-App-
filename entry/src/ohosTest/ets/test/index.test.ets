// entry/src/ohosTest/ets/test/index.test.ets
// Hypium 测试入口文件
// 不要包在 export default function 里，顶层 import 所有测试文件即可

// ----------------- Model 测试 -----------------
import './model/Account.test';
import './model/Bill.test';
import './model/User.test';
import './model/Category.test';
import './model/Budget.test';
import './model/Statistics.test';
import './model/Tag.test';
import './model/BillTag.test';
import './model/CloudSyncRecord.test';
import './model/Reminder.test';

// ----------------- DAO 测试 -----------------
import './dao/AccountDAO.test';
import './dao/BillDAO.test';
import './dao/UserDAO.test';
import './dao/CategoryDAO.test';
import './dao/BudgetDAO.test';
import './dao/StatisticsDAO.test';
import './dao/TagDAO.test';
import './dao/CloudSyncRecordDAO.test';
import './dao/ReminderDAO.test';

// ----------------- 页面测试 -----------------
import './pages/IndexPage.test';
import './pages/AddBillPage.test';
import './pages/CategoryManagementPage.test';

// ----------------- 业务逻辑测试 -----------------
import './services/Transaction.test';
import './services/ExportService.test';
import './services/ImportService.test';
import './services/CloudSyncService.test';
import './services/ReminderService.test';
import './services/UserSessionService.test';
import './services/EncryptionModule.test';
import './services/FileHelper.test';
import './services/ChecksumHelper.test';

// ----------------- 工具类测试 -----------------
import './common/BreakpointSystem.test';
import './common/DAOHelper.test';

export default function testsuite() {

  console.info('🚀 testsuite entry function called');
}