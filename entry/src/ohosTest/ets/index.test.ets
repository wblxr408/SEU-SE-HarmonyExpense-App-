import { describe, it, expect } from '@ohos/hypium';

// Model 测试
import AccountTest from './test/model/Account.test';
import BillTest from './test/model/Bill.test';
import UserTest from './test/model/User.test';
import CategoryTest from './test/model/Category.test';
import BudgetTest from './test/model/Budget.test';
import StatisticsTest from './test/model/Statistics.test';

// DAO 测试
import AccountDAOTest from './test/dao/AccountDAO.test';
import BillDAOTest from './test/dao/BillDAO.test';
import UserDAOTest from './test/dao/UserDAO.test';
import CategoryDAOTest from './test/dao/CategoryDAO.test';
import BudgetDAOTest from './test/dao/BudgetDAO.test';
import StatisticsDAOTest from './test/dao/StatisticsDAO.test';

// 页面测试
import IndexPageTest from './test/pages/IndexPage.test';
import AddBillPageTest from './test/pages/AddBillPage.test';
import CategoryManagementPageTest from './test/pages/CategoryManagementPage.test';

// 业务逻辑测试
import TransactionTest from './test/services/Transaction.test';

// 基础测试用例（确保测试框架正常工作）
describe('Test Suite Entry', () => {
  it('should run basic test', 0, () => {
    console.info('✅ Basic test executed');
    expect(true).assertTrue();
  });

  it('should run number test', 0, () => {
    expect(1 + 1).assertEqual(2);
  });
});

// testsuite 函数必须在所有 import 之后
export default function testsuite(): void {
  console.info('🚀 Test Suite Starting');

  // Model 测试
  console.info('📦 Running Model Tests...');
  AccountTest();
  BillTest();
  UserTest();
  CategoryTest();
  BudgetTest();
  StatisticsTest();

  // DAO 测试
  console.info('📦 Running DAO Tests...');
  AccountDAOTest();
  BillDAOTest();
  UserDAOTest();
  CategoryDAOTest();
  BudgetDAOTest();
  StatisticsDAOTest();

  // 页面测试
  console.info('📦 Running Page Tests...');
  IndexPageTest();
  AddBillPageTest();
  CategoryManagementPageTest();

  // 业务逻辑测试
  console.info('📦 Running Service Tests...');
  TransactionTest();

  console.info('✅ All tests completed!');
}