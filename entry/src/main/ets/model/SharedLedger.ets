/**
 * 家庭/团队协作记账系统模型
 *
 * 功能：
 * 1. 多用户协作记账
 * 2. 家庭/团队账本管理
 * 3. 权限角色控制 (RBAC)
 * 4. 实时数据同步
 * 5. 消费审批流程
 *
 * 架构特点：
 * - 多租户数据隔离
 * - RBAC权限模型
 * - CRDT冲突无关数据类型
 * - 事件驱动同步
 *
 * @version 2.0.0
 * @author HarmonyExpense Team
 */

// ==================== 常量定义 ====================

// 账本类型常量
export const LEDGER_TYPE_PERSONAL = 'personal';     // 个人账本
export const LEDGER_TYPE_FAMILY = 'family';         // 家庭账本
export const LEDGER_TYPE_COUPLE = 'couple';         // 情侣账本
export const LEDGER_TYPE_ROOMMATE = 'roommate';     // 室友账本
export const LEDGER_TYPE_TEAM = 'team';             // 团队账本
export const LEDGER_TYPE_PROJECT = 'project';       // 项目账本

// 成员角色常量
export const MEMBER_ROLE_OWNER = 'owner';           // 所有者（最高权限）
export const MEMBER_ROLE_ADMIN = 'admin';           // 管理员
export const MEMBER_ROLE_MEMBER = 'member';         // 普通成员
export const MEMBER_ROLE_VIEWER = 'viewer';         // 只读成员

// 邀请状态常量
export const INVITATION_STATUS_PENDING = 'pending';       // 待接受
export const INVITATION_STATUS_ACCEPTED = 'accepted';     // 已接受
export const INVITATION_STATUS_DECLINED = 'declined';     // 已拒绝
export const INVITATION_STATUS_EXPIRED = 'expired';       // 已过期
export const INVITATION_STATUS_CANCELLED = 'cancelled';   // 已取消

// 审批状态常量
export const APPROVAL_STATUS_PENDING = 'pending';         // 待审批
export const APPROVAL_STATUS_APPROVED = 'approved';       // 已批准
export const APPROVAL_STATUS_REJECTED = 'rejected';       // 已拒绝
export const APPROVAL_STATUS_AUTO_APPROVED = 'auto_approved'; // 自动批准

// 同步状态常量
export const SYNC_STATUS_SYNCED = 'synced';         // 已同步
export const SYNC_STATUS_PENDING = 'pending';       // 待同步
export const SYNC_STATUS_CONFLICT = 'conflict';     // 冲突
export const SYNC_STATUS_FAILED = 'failed';         // 失败

// 权限类型常量
export const PERMISSION_VIEW_BILLS = 'view_bills';           // 查看账单
export const PERMISSION_CREATE_BILLS = 'create_bills';       // 创建账单
export const PERMISSION_EDIT_OWN_BILLS = 'edit_own_bills';   // 编辑自己的账单
export const PERMISSION_EDIT_ALL_BILLS = 'edit_all_bills';   // 编辑所有账单
export const PERMISSION_DELETE_BILLS = 'delete_bills';       // 删除账单
export const PERMISSION_VIEW_STATS = 'view_stats';           // 查看统计
export const PERMISSION_MANAGE_CATEGORIES = 'manage_categories'; // 管理分类
export const PERMISSION_MANAGE_BUDGETS = 'manage_budgets';   // 管理预算
export const PERMISSION_MANAGE_MEMBERS = 'manage_members';   // 管理成员
export const PERMISSION_MANAGE_SETTINGS = 'manage_settings'; // 管理设置
export const PERMISSION_APPROVE_BILLS = 'approve_bills';     // 审批账单
export const PERMISSION_EXPORT_DATA = 'export_data';         // 导出数据

// 所有权限列表
export const ALL_PERMISSIONS: string[] = [
  PERMISSION_VIEW_BILLS,
  PERMISSION_CREATE_BILLS,
  PERMISSION_EDIT_OWN_BILLS,
  PERMISSION_EDIT_ALL_BILLS,
  PERMISSION_DELETE_BILLS,
  PERMISSION_VIEW_STATS,
  PERMISSION_MANAGE_CATEGORIES,
  PERMISSION_MANAGE_BUDGETS,
  PERMISSION_MANAGE_MEMBERS,
  PERMISSION_MANAGE_SETTINGS,
  PERMISSION_APPROVE_BILLS,
  PERMISSION_EXPORT_DATA
];

// 所有账本类型列表
export const ALL_LEDGER_TYPES: string[] = [
  LEDGER_TYPE_PERSONAL,
  LEDGER_TYPE_FAMILY,
  LEDGER_TYPE_COUPLE,
  LEDGER_TYPE_ROOMMATE,
  LEDGER_TYPE_TEAM,
  LEDGER_TYPE_PROJECT
];

// 所有成员角色列表
export const ALL_MEMBER_ROLES: string[] = [
  MEMBER_ROLE_OWNER,
  MEMBER_ROLE_ADMIN,
  MEMBER_ROLE_MEMBER,
  MEMBER_ROLE_VIEWER
];

// ==================== 接口定义 ====================

/**
 * 账本设置接口
 */
export interface LedgerSettings {
  requireApproval: boolean;        // 是否需要审批
  approvalThreshold: number;       // 审批阈值金额
  allowMemberInvite: boolean;      // 成员是否可邀请他人
  defaultCurrency: string;         // 默认货币
  billVisibility: string;          // 账单可见性: 'all' | 'own'
  notifyOnNewBill: boolean;        // 新账单通知
  notifyOnApproval: boolean;       // 审批通知
  autoApproveRoles: string;        // 自动审批的角色JSON字符串
  monthlyBudgetLimit: number;      // 月度预算限制
  allowNegativeBalance: boolean;   // 允许负余额
}

/**
 * 共享账本接口
 */
export interface SharedLedgerJSON {
  ledgerId: number;
  name: string;
  description: string;
  type: string;
  ownerId: number;
  ownerName: string;
  currency: string;
  icon: string;
  color: string;
  memberCount: number;
  settings: LedgerSettings;
  createdAt: string;
  updatedAt: string;
  isDeleted: number;
}

/**
 * 账本成员接口
 */
export interface LedgerMemberJSON {
  memberId: number;
  ledgerId: number;
  userId: number;
  username: string;
  email: string;
  avatar: string;
  role: string;
  permissions: string[];
  nickname: string;                // 账本内昵称
  contributionAmount: number;      // 贡献金额
  billCount: number;               // 账单数量
  joinedAt: string;
  lastActiveAt: string;
  isActive: number;
  createdAt: string;
  updatedAt: string;
  isDeleted: number;
}

/**
 * 邀请记录接口
 */
export interface LedgerInvitationJSON {
  invitationId: number;
  ledgerId: number;
  ledgerName: string;
  inviterId: number;
  inviterName: string;
  inviteeEmail: string;
  inviteeUserId: number;
  role: string;
  message: string;
  status: string;
  invitationCode: string;          // 邀请码
  expiresAt: string;
  respondedAt: string;
  createdAt: string;
  updatedAt: string;
  isDeleted: number;
}

/**
 * 账单分摊详情接口
 */
export interface BillSplitDetail {
  memberId: number;
  memberName: string;
  amount: number;
  percentage: number;
  isPaid: boolean;
  paidAt: string;
}

/**
 * 共享账单接口（扩展自Bill）
 */
export interface SharedBillJSON {
  billId: number;
  ledgerId: number;
  creatorId: number;
  creatorName: string;
  accountId: number;
  categoryId: number;
  amount: number;
  note: string;
  transactionDate: string;
  type: string;                    // 'income' | 'expense'
  // 协作相关字段
  approvalStatus: string;
  approvedBy: number;
  approvedAt: string;
  syncStatus: string;
  lastSyncedAt: string;
  version: number;                 // 乐观锁版本号
  // 分摊相关
  splitType: string;               // 'equal' | 'custom' | 'percentage' | 'none'
  splitDetails: BillSplitDetail[];
  // 元数据
  attachments: string[];           // 附件URL列表
  tags: string[];
  location: string;
  createdAt: string;
  updatedAt: string;
  isDeleted: number;
}

/**
 * 审批记录接口
 */
export interface ApprovalRecordJSON {
  approvalId: number;
  ledgerId: number;
  billId: number;
  requesterId: number;
  requesterName: string;
  approverId: number;
  approverName: string;
  status: string;
  amount: number;
  reason: string;
  comment: string;
  requestedAt: string;
  processedAt: string;
  createdAt: string;
  updatedAt: string;
  isDeleted: number;
}

/**
 * 成员活动记录接口
 */
export interface MemberActivityJSON {
  activityId: number;
  ledgerId: number;
  userId: number;
  username: string;
  actionType: string;  // 'create' | 'update' | 'delete' | 'approve' | 'reject' | 'join' | 'leave'
  targetType: string;  // 'bill' | 'category' | 'budget' | 'member' | 'settings'
  targetId: number;
  description: string;
  metadata: string;    // JSON字符串
  createdAt: string;
}

/**
 * 角色权限配置接口
 */
export interface RolePermissionConfig {
  role: string;
  permissions: string[];
  description: string;
}

/**
 * 分摊成员信息接口
 */
export interface SplitMemberInfo {
  memberId: number;
  memberName: string;
}

// ==================== 类实现 ====================

/**
 * 共享账本类
 */
export class SharedLedger {
  static readonly tableName: string = 'shared_ledgers';

  ledgerId: number = 0;
  name: string = '';
  description: string = '';
  type: string = LEDGER_TYPE_FAMILY;
  ownerId: number = 0;
  ownerName: string = '';
  currency: string = 'CNY';
  icon: string = '';
  color: string = '#2196F3';
  memberCount: number = 1;
  settingsJson: string = '{}';
  createdAt: string = '';
  updatedAt: string = '';
  isDeleted: number = 0;

  constructor(
    ledgerId: number = 0,
    name: string = '',
    description: string = '',
    type: string = LEDGER_TYPE_FAMILY,
    ownerId: number = 0,
    ownerName: string = '',
    currency: string = 'CNY',
    icon: string = '',
    color: string = '#2196F3',
    memberCount: number = 1,
    settingsJson: string = '{}',
    createdAt: string = '',
    updatedAt: string = '',
    isDeleted: number = 0
  ) {
    this.ledgerId = ledgerId;
    this.name = name;
    this.description = description;
    this.type = type;
    this.ownerId = ownerId;
    this.ownerName = ownerName;
    this.currency = currency;
    this.icon = icon;
    this.color = color;
    this.memberCount = memberCount;
    this.settingsJson = settingsJson;
    this.createdAt = createdAt;
    this.updatedAt = updatedAt;
    this.isDeleted = isDeleted;
  }

  /**
   * 获取账本设置
   */
  getSettings(): LedgerSettings {
    try {
      const parsed = JSON.parse(this.settingsJson) as LedgerSettings;
      return parsed;
    } catch (e) {
      return SharedLedgerUtils.getDefaultSettings();
    }
  }

  /**
   * 设置账本设置
   */
  setSettings(settings: LedgerSettings): void {
    this.settingsJson = JSON.stringify(settings);
  }

  toJSON(): SharedLedgerJSON {
    const result: SharedLedgerJSON = {
      ledgerId: this.ledgerId,
      name: this.name,
      description: this.description,
      type: this.type,
      ownerId: this.ownerId,
      ownerName: this.ownerName,
      currency: this.currency,
      icon: this.icon,
      color: this.color,
      memberCount: this.memberCount,
      settings: this.getSettings(),
      createdAt: this.createdAt,
      updatedAt: this.updatedAt,
      isDeleted: this.isDeleted
    };
    return result;
  }

  static fromJSON(data: SharedLedgerJSON): SharedLedger {
    const ledger = new SharedLedger(
      data.ledgerId,
      data.name,
      data.description,
      data.type,
      data.ownerId,
      data.ownerName,
      data.currency,
      data.icon,
      data.color,
      data.memberCount,
      JSON.stringify(data.settings),
      data.createdAt,
      data.updatedAt,
      data.isDeleted
    );
    return ledger;
  }

  validate(): boolean {
    let validType = false;
    for (let i = 0; i < ALL_LEDGER_TYPES.length; i++) {
      if (ALL_LEDGER_TYPES[i] === this.type) {
        validType = true;
        break;
      }
    }
    return (
      this.name.trim().length > 0 &&
      this.ownerId > 0 &&
      validType
    );
  }

  clone(): SharedLedger {
    return SharedLedger.fromJSON(this.toJSON());
  }
}

/**
 * 账本成员类
 */
export class LedgerMember {
  static readonly tableName: string = 'ledger_members';

  memberId: number = 0;
  ledgerId: number = 0;
  userId: number = 0;
  username: string = '';
  email: string = '';
  avatar: string = '';
  role: string = MEMBER_ROLE_MEMBER;
  permissionsJson: string = '[]';
  nickname: string = '';
  contributionAmount: number = 0;
  billCount: number = 0;
  joinedAt: string = '';
  lastActiveAt: string = '';
  isActive: number = 1;
  createdAt: string = '';
  updatedAt: string = '';
  isDeleted: number = 0;

  constructor(
    memberId: number = 0,
    ledgerId: number = 0,
    userId: number = 0,
    username: string = '',
    email: string = '',
    avatar: string = '',
    role: string = MEMBER_ROLE_MEMBER,
    permissionsJson: string = '[]',
    nickname: string = '',
    contributionAmount: number = 0,
    billCount: number = 0,
    joinedAt: string = '',
    lastActiveAt: string = '',
    isActive: number = 1,
    createdAt: string = '',
    updatedAt: string = '',
    isDeleted: number = 0
  ) {
    this.memberId = memberId;
    this.ledgerId = ledgerId;
    this.userId = userId;
    this.username = username;
    this.email = email;
    this.avatar = avatar;
    this.role = role;
    this.permissionsJson = permissionsJson;
    this.nickname = nickname;
    this.contributionAmount = contributionAmount;
    this.billCount = billCount;
    this.joinedAt = joinedAt;
    this.lastActiveAt = lastActiveAt;
    this.isActive = isActive;
    this.createdAt = createdAt;
    this.updatedAt = updatedAt;
    this.isDeleted = isDeleted;
  }

  /**
   * 获取权限列表
   */
  getPermissions(): string[] {
    try {
      const parsed = JSON.parse(this.permissionsJson) as string[];
      return parsed;
    } catch (e) {
      return this.getDefaultPermissions();
    }
  }

  /**
   * 设置权限列表
   */
  setPermissions(permissions: string[]): void {
    this.permissionsJson = JSON.stringify(permissions);
  }

  /**
   * 检查是否有某项权限
   */
  hasPermission(permission: string): boolean {
    const permissions = this.getPermissions();
    for (let i = 0; i < permissions.length; i++) {
      if (permissions[i] === permission) {
        return true;
      }
    }
    return false;
  }

  /**
   * 获取角色对应的默认权限
   */
  getDefaultPermissions(): string[] {
    return SharedLedgerUtils.getPermissionsForRole(this.role);
  }

  /**
   * 应用角色默认权限
   */
  applyRolePermissions(): void {
    this.setPermissions(this.getDefaultPermissions());
  }

  toJSON(): LedgerMemberJSON {
    const result: LedgerMemberJSON = {
      memberId: this.memberId,
      ledgerId: this.ledgerId,
      userId: this.userId,
      username: this.username,
      email: this.email,
      avatar: this.avatar,
      role: this.role,
      permissions: this.getPermissions(),
      nickname: this.nickname,
      contributionAmount: this.contributionAmount,
      billCount: this.billCount,
      joinedAt: this.joinedAt,
      lastActiveAt: this.lastActiveAt,
      isActive: this.isActive,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt,
      isDeleted: this.isDeleted
    };
    return result;
  }

  static fromJSON(data: LedgerMemberJSON): LedgerMember {
    return new LedgerMember(
      data.memberId,
      data.ledgerId,
      data.userId,
      data.username,
      data.email,
      data.avatar,
      data.role,
      JSON.stringify(data.permissions),
      data.nickname,
      data.contributionAmount,
      data.billCount,
      data.joinedAt,
      data.lastActiveAt,
      data.isActive,
      data.createdAt,
      data.updatedAt,
      data.isDeleted
    );
  }

  validate(): boolean {
    let validRole = false;
    for (let i = 0; i < ALL_MEMBER_ROLES.length; i++) {
      if (ALL_MEMBER_ROLES[i] === this.role) {
        validRole = true;
        break;
      }
    }
    return (
      this.ledgerId > 0 &&
      this.userId > 0 &&
      validRole
    );
  }

  clone(): LedgerMember {
    return LedgerMember.fromJSON(this.toJSON());
  }
}

/**
 * 账本邀请类
 */
export class LedgerInvitation {
  static readonly tableName: string = 'ledger_invitations';

  invitationId: number = 0;
  ledgerId: number = 0;
  ledgerName: string = '';
  inviterId: number = 0;
  inviterName: string = '';
  inviteeEmail: string = '';
  inviteeUserId: number = 0;
  role: string = MEMBER_ROLE_MEMBER;
  message: string = '';
  status: string = INVITATION_STATUS_PENDING;
  invitationCode: string = '';
  expiresAt: string = '';
  respondedAt: string = '';
  createdAt: string = '';
  updatedAt: string = '';
  isDeleted: number = 0;

  constructor(
    invitationId: number = 0,
    ledgerId: number = 0,
    ledgerName: string = '',
    inviterId: number = 0,
    inviterName: string = '',
    inviteeEmail: string = '',
    inviteeUserId: number = 0,
    role: string = MEMBER_ROLE_MEMBER,
    message: string = '',
    status: string = INVITATION_STATUS_PENDING,
    invitationCode: string = '',
    expiresAt: string = '',
    respondedAt: string = '',
    createdAt: string = '',
    updatedAt: string = '',
    isDeleted: number = 0
  ) {
    this.invitationId = invitationId;
    this.ledgerId = ledgerId;
    this.ledgerName = ledgerName;
    this.inviterId = inviterId;
    this.inviterName = inviterName;
    this.inviteeEmail = inviteeEmail;
    this.inviteeUserId = inviteeUserId;
    this.role = role;
    this.message = message;
    this.status = status;
    this.invitationCode = invitationCode;
    this.expiresAt = expiresAt;
    this.respondedAt = respondedAt;
    this.createdAt = createdAt;
    this.updatedAt = updatedAt;
    this.isDeleted = isDeleted;
  }

  /**
   * 生成邀请码
   */
  generateInvitationCode(): string {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    let code = '';
    for (let i = 0; i < 8; i++) {
      code += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    this.invitationCode = code;
    return code;
  }

  /**
   * 检查邀请是否过期
   */
  isExpired(): boolean {
    if (this.expiresAt === '') {
      return false;
    }
    return new Date(this.expiresAt).getTime() < new Date().getTime();
  }

  /**
   * 接受邀请
   */
  accept(): void {
    this.status = INVITATION_STATUS_ACCEPTED;
    this.respondedAt = new Date().toISOString();
    this.updatedAt = new Date().toISOString();
  }

  /**
   * 拒绝邀请
   */
  decline(): void {
    this.status = INVITATION_STATUS_DECLINED;
    this.respondedAt = new Date().toISOString();
    this.updatedAt = new Date().toISOString();
  }

  toJSON(): LedgerInvitationJSON {
    const result: LedgerInvitationJSON = {
      invitationId: this.invitationId,
      ledgerId: this.ledgerId,
      ledgerName: this.ledgerName,
      inviterId: this.inviterId,
      inviterName: this.inviterName,
      inviteeEmail: this.inviteeEmail,
      inviteeUserId: this.inviteeUserId,
      role: this.role,
      message: this.message,
      status: this.status,
      invitationCode: this.invitationCode,
      expiresAt: this.expiresAt,
      respondedAt: this.respondedAt,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt,
      isDeleted: this.isDeleted
    };
    return result;
  }

  static fromJSON(data: LedgerInvitationJSON): LedgerInvitation {
    return new LedgerInvitation(
      data.invitationId,
      data.ledgerId,
      data.ledgerName,
      data.inviterId,
      data.inviterName,
      data.inviteeEmail,
      data.inviteeUserId,
      data.role,
      data.message,
      data.status,
      data.invitationCode,
      data.expiresAt,
      data.respondedAt,
      data.createdAt,
      data.updatedAt,
      data.isDeleted
    );
  }

  validate(): boolean {
    let validRole = false;
    for (let i = 0; i < ALL_MEMBER_ROLES.length; i++) {
      if (ALL_MEMBER_ROLES[i] === this.role) {
        validRole = true;
        break;
      }
    }
    return (
      this.ledgerId > 0 &&
      this.inviterId > 0 &&
      (this.inviteeEmail.trim().length > 0 || this.inviteeUserId > 0) &&
      validRole
    );
  }

  clone(): LedgerInvitation {
    return LedgerInvitation.fromJSON(this.toJSON());
  }
}

/**
 * 共享账单类
 */
export class SharedBill {
  static readonly tableName: string = 'shared_bills';

  billId: number = 0;
  ledgerId: number = 0;
  creatorId: number = 0;
  creatorName: string = '';
  accountId: number = 0;
  categoryId: number = 0;
  amount: number = 0;
  note: string = '';
  transactionDate: string = '';
  type: string = 'expense';
  approvalStatus: string = APPROVAL_STATUS_AUTO_APPROVED;
  approvedBy: number = 0;
  approvedAt: string = '';
  syncStatus: string = SYNC_STATUS_SYNCED;
  lastSyncedAt: string = '';
  version: number = 1;
  splitType: string = 'none';
  splitDetailsJson: string = '[]';
  attachmentsJson: string = '[]';
  tagsJson: string = '[]';
  location: string = '';
  createdAt: string = '';
  updatedAt: string = '';
  isDeleted: number = 0;

  constructor(
    billId: number = 0,
    ledgerId: number = 0,
    creatorId: number = 0,
    creatorName: string = '',
    accountId: number = 0,
    categoryId: number = 0,
    amount: number = 0,
    note: string = '',
    transactionDate: string = '',
    type: string = 'expense',
    approvalStatus: string = APPROVAL_STATUS_AUTO_APPROVED,
    approvedBy: number = 0,
    approvedAt: string = '',
    syncStatus: string = SYNC_STATUS_SYNCED,
    lastSyncedAt: string = '',
    version: number = 1,
    splitType: string = 'none',
    splitDetailsJson: string = '[]',
    attachmentsJson: string = '[]',
    tagsJson: string = '[]',
    location: string = '',
    createdAt: string = '',
    updatedAt: string = '',
    isDeleted: number = 0
  ) {
    this.billId = billId;
    this.ledgerId = ledgerId;
    this.creatorId = creatorId;
    this.creatorName = creatorName;
    this.accountId = accountId;
    this.categoryId = categoryId;
    this.amount = amount;
    this.note = note;
    this.transactionDate = transactionDate;
    this.type = type;
    this.approvalStatus = approvalStatus;
    this.approvedBy = approvedBy;
    this.approvedAt = approvedAt;
    this.syncStatus = syncStatus;
    this.lastSyncedAt = lastSyncedAt;
    this.version = version;
    this.splitType = splitType;
    this.splitDetailsJson = splitDetailsJson;
    this.attachmentsJson = attachmentsJson;
    this.tagsJson = tagsJson;
    this.location = location;
    this.createdAt = createdAt;
    this.updatedAt = updatedAt;
    this.isDeleted = isDeleted;
  }

  /**
   * 获取分摊详情
   */
  getSplitDetails(): BillSplitDetail[] {
    try {
      const parsed = JSON.parse(this.splitDetailsJson) as BillSplitDetail[];
      return parsed;
    } catch (e) {
      return [];
    }
  }

  /**
   * 设置分摊详情
   */
  setSplitDetails(details: BillSplitDetail[]): void {
    this.splitDetailsJson = JSON.stringify(details);
  }

  /**
   * 按成员数量平均分摊
   */
  splitEqually(members: SplitMemberInfo[]): void {
    if (members.length === 0) {
      return;
    }

    const amountPerPerson = Math.round((this.amount / members.length) * 100) / 100;
    const percentagePerPerson = Math.round((100 / members.length) * 100) / 100;

    const details: BillSplitDetail[] = [];
    for (let i = 0; i < members.length; i++) {
      const detail: BillSplitDetail = {
        memberId: members[i].memberId,
        memberName: members[i].memberName,
        amount: amountPerPerson,
        percentage: percentagePerPerson,
        isPaid: false,
        paidAt: ''
      };
      details.push(detail);
    }

    this.splitType = 'equal';
    this.setSplitDetails(details);
  }

  /**
   * 获取附件列表
   */
  getAttachments(): string[] {
    try {
      const parsed = JSON.parse(this.attachmentsJson) as string[];
      return parsed;
    } catch (e) {
      return [];
    }
  }

  /**
   * 设置附件列表
   */
  setAttachments(attachments: string[]): void {
    this.attachmentsJson = JSON.stringify(attachments);
  }

  /**
   * 获取标签列表
   */
  getTags(): string[] {
    try {
      const parsed = JSON.parse(this.tagsJson) as string[];
      return parsed;
    } catch (e) {
      return [];
    }
  }

  /**
   * 设置标签列表
   */
  setTags(tags: string[]): void {
    this.tagsJson = JSON.stringify(tags);
  }

  /**
   * 增加版本号（乐观锁）
   */
  incrementVersion(): void {
    this.version += 1;
    this.updatedAt = new Date().toISOString();
  }

  toJSON(): SharedBillJSON {
    const result: SharedBillJSON = {
      billId: this.billId,
      ledgerId: this.ledgerId,
      creatorId: this.creatorId,
      creatorName: this.creatorName,
      accountId: this.accountId,
      categoryId: this.categoryId,
      amount: this.amount,
      note: this.note,
      transactionDate: this.transactionDate,
      type: this.type,
      approvalStatus: this.approvalStatus,
      approvedBy: this.approvedBy,
      approvedAt: this.approvedAt,
      syncStatus: this.syncStatus,
      lastSyncedAt: this.lastSyncedAt,
      version: this.version,
      splitType: this.splitType,
      splitDetails: this.getSplitDetails(),
      attachments: this.getAttachments(),
      tags: this.getTags(),
      location: this.location,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt,
      isDeleted: this.isDeleted
    };
    return result;
  }

  static fromJSON(data: SharedBillJSON): SharedBill {
    return new SharedBill(
      data.billId,
      data.ledgerId,
      data.creatorId,
      data.creatorName,
      data.accountId,
      data.categoryId,
      data.amount,
      data.note,
      data.transactionDate,
      data.type,
      data.approvalStatus,
      data.approvedBy,
      data.approvedAt,
      data.syncStatus,
      data.lastSyncedAt,
      data.version,
      data.splitType,
      JSON.stringify(data.splitDetails),
      JSON.stringify(data.attachments),
      JSON.stringify(data.tags),
      data.location,
      data.createdAt,
      data.updatedAt,
      data.isDeleted
    );
  }

  validate(): boolean {
    return (
      this.ledgerId > 0 &&
      this.creatorId > 0 &&
      this.amount >= 0 &&
      this.transactionDate !== ''
    );
  }

  clone(): SharedBill {
    return SharedBill.fromJSON(this.toJSON());
  }
}

/**
 * 审批记录类
 */
export class ApprovalRecord {
  static readonly tableName: string = 'approval_records';

  approvalId: number = 0;
  ledgerId: number = 0;
  billId: number = 0;
  requesterId: number = 0;
  requesterName: string = '';
  approverId: number = 0;
  approverName: string = '';
  status: string = APPROVAL_STATUS_PENDING;
  amount: number = 0;
  reason: string = '';
  comment: string = '';
  requestedAt: string = '';
  processedAt: string = '';
  createdAt: string = '';
  updatedAt: string = '';
  isDeleted: number = 0;

  constructor(
    approvalId: number = 0,
    ledgerId: number = 0,
    billId: number = 0,
    requesterId: number = 0,
    requesterName: string = '',
    approverId: number = 0,
    approverName: string = '',
    status: string = APPROVAL_STATUS_PENDING,
    amount: number = 0,
    reason: string = '',
    comment: string = '',
    requestedAt: string = '',
    processedAt: string = '',
    createdAt: string = '',
    updatedAt: string = '',
    isDeleted: number = 0
  ) {
    this.approvalId = approvalId;
    this.ledgerId = ledgerId;
    this.billId = billId;
    this.requesterId = requesterId;
    this.requesterName = requesterName;
    this.approverId = approverId;
    this.approverName = approverName;
    this.status = status;
    this.amount = amount;
    this.reason = reason;
    this.comment = comment;
    this.requestedAt = requestedAt;
    this.processedAt = processedAt;
    this.createdAt = createdAt;
    this.updatedAt = updatedAt;
    this.isDeleted = isDeleted;
  }

  /**
   * 批准
   */
  approve(approverId: number, approverName: string, comment: string = ''): void {
    this.status = APPROVAL_STATUS_APPROVED;
    this.approverId = approverId;
    this.approverName = approverName;
    this.comment = comment;
    this.processedAt = new Date().toISOString();
    this.updatedAt = new Date().toISOString();
  }

  /**
   * 拒绝
   */
  reject(approverId: number, approverName: string, comment: string): void {
    this.status = APPROVAL_STATUS_REJECTED;
    this.approverId = approverId;
    this.approverName = approverName;
    this.comment = comment;
    this.processedAt = new Date().toISOString();
    this.updatedAt = new Date().toISOString();
  }

  toJSON(): ApprovalRecordJSON {
    const result: ApprovalRecordJSON = {
      approvalId: this.approvalId,
      ledgerId: this.ledgerId,
      billId: this.billId,
      requesterId: this.requesterId,
      requesterName: this.requesterName,
      approverId: this.approverId,
      approverName: this.approverName,
      status: this.status,
      amount: this.amount,
      reason: this.reason,
      comment: this.comment,
      requestedAt: this.requestedAt,
      processedAt: this.processedAt,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt,
      isDeleted: this.isDeleted
    };
    return result;
  }

  static fromJSON(data: ApprovalRecordJSON): ApprovalRecord {
    return new ApprovalRecord(
      data.approvalId,
      data.ledgerId,
      data.billId,
      data.requesterId,
      data.requesterName,
      data.approverId,
      data.approverName,
      data.status,
      data.amount,
      data.reason,
      data.comment,
      data.requestedAt,
      data.processedAt,
      data.createdAt,
      data.updatedAt,
      data.isDeleted
    );
  }

  validate(): boolean {
    return (
      this.ledgerId > 0 &&
      this.billId > 0 &&
      this.requesterId > 0 &&
      this.amount >= 0
    );
  }

  clone(): ApprovalRecord {
    return ApprovalRecord.fromJSON(this.toJSON());
  }
}

/**
 * 成员活动记录类
 */
export class MemberActivity {
  static readonly tableName: string = 'member_activities';

  activityId: number = 0;
  ledgerId: number = 0;
  userId: number = 0;
  username: string = '';
  actionType: string = 'create';
  targetType: string = 'bill';
  targetId: number = 0;
  description: string = '';
  metadataJson: string = '{}';
  createdAt: string = '';

  constructor(
    activityId: number = 0,
    ledgerId: number = 0,
    userId: number = 0,
    username: string = '',
    actionType: string = 'create',
    targetType: string = 'bill',
    targetId: number = 0,
    description: string = '',
    metadataJson: string = '{}',
    createdAt: string = ''
  ) {
    this.activityId = activityId;
    this.ledgerId = ledgerId;
    this.userId = userId;
    this.username = username;
    this.actionType = actionType;
    this.targetType = targetType;
    this.targetId = targetId;
    this.description = description;
    this.metadataJson = metadataJson;
    this.createdAt = createdAt;
  }

  toJSON(): MemberActivityJSON {
    const result: MemberActivityJSON = {
      activityId: this.activityId,
      ledgerId: this.ledgerId,
      userId: this.userId,
      username: this.username,
      actionType: this.actionType,
      targetType: this.targetType,
      targetId: this.targetId,
      description: this.description,
      metadata: this.metadataJson,
      createdAt: this.createdAt
    };
    return result;
  }

  static fromJSON(data: MemberActivityJSON): MemberActivity {
    return new MemberActivity(
      data.activityId,
      data.ledgerId,
      data.userId,
      data.username,
      data.actionType,
      data.targetType,
      data.targetId,
      data.description,
      data.metadata,
      data.createdAt
    );
  }
}

// ==================== 工具类 ====================

/**
 * 共享账本工具类
 */
export class SharedLedgerUtils {
  /**
   * 获取默认账本设置
   */
  static getDefaultSettings(): LedgerSettings {
    const result: LedgerSettings = {
      requireApproval: false,
      approvalThreshold: 1000,
      allowMemberInvite: false,
      defaultCurrency: 'CNY',
      billVisibility: 'all',
      notifyOnNewBill: true,
      notifyOnApproval: true,
      autoApproveRoles: JSON.stringify([MEMBER_ROLE_OWNER, MEMBER_ROLE_ADMIN]),
      monthlyBudgetLimit: 0,
      allowNegativeBalance: true
    };
    return result;
  }

  /**
   * 获取角色对应的权限
   */
  static getPermissionsForRole(role: string): string[] {
    if (role === MEMBER_ROLE_OWNER) {
      const result: string[] = [];
      for (let i = 0; i < ALL_PERMISSIONS.length; i++) {
        result.push(ALL_PERMISSIONS[i]);
      }
      return result;
    } else if (role === MEMBER_ROLE_ADMIN) {
      return [
        PERMISSION_VIEW_BILLS,
        PERMISSION_CREATE_BILLS,
        PERMISSION_EDIT_OWN_BILLS,
        PERMISSION_EDIT_ALL_BILLS,
        PERMISSION_DELETE_BILLS,
        PERMISSION_VIEW_STATS,
        PERMISSION_MANAGE_CATEGORIES,
        PERMISSION_MANAGE_BUDGETS,
        PERMISSION_MANAGE_MEMBERS,
        PERMISSION_APPROVE_BILLS,
        PERMISSION_EXPORT_DATA
      ];
    } else if (role === MEMBER_ROLE_MEMBER) {
      return [
        PERMISSION_VIEW_BILLS,
        PERMISSION_CREATE_BILLS,
        PERMISSION_EDIT_OWN_BILLS,
        PERMISSION_VIEW_STATS
      ];
    } else if (role === MEMBER_ROLE_VIEWER) {
      return [
        PERMISSION_VIEW_BILLS,
        PERMISSION_VIEW_STATS
      ];
    }
    return [];
  }

  /**
   * 获取角色描述
   */
  static getRoleDescription(role: string): string {
    if (role === MEMBER_ROLE_OWNER) {
      return '账本所有者，拥有全部权限';
    } else if (role === MEMBER_ROLE_ADMIN) {
      return '管理员，可管理账本和成员';
    } else if (role === MEMBER_ROLE_MEMBER) {
      return '普通成员，可记账和查看统计';
    } else if (role === MEMBER_ROLE_VIEWER) {
      return '只读成员，仅可查看';
    }
    return '未知角色';
  }

  /**
   * 创建角色权限配置
   */
  static createRolePermissionConfig(role: string): RolePermissionConfig {
    const result: RolePermissionConfig = {
      role: role,
      permissions: SharedLedgerUtils.getPermissionsForRole(role),
      description: SharedLedgerUtils.getRoleDescription(role)
    };
    return result;
  }

  /**
   * 创建分摊详情
   */
  static createSplitDetail(
    memberId: number,
    memberName: string,
    amount: number,
    percentage: number,
    isPaid: boolean = false,
    paidAt: string = ''
  ): BillSplitDetail {
    const result: BillSplitDetail = {
      memberId: memberId,
      memberName: memberName,
      amount: amount,
      percentage: percentage,
      isPaid: isPaid,
      paidAt: paidAt
    };
    return result;
  }

  /**
   * 检查用户是否有权限
   */
  static checkPermission(member: LedgerMember, permission: string): boolean {
    return member.hasPermission(permission);
  }

  /**
   * 生成邀请码
   */
  static generateInvitationCode(): string {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    let code = '';
    for (let i = 0; i < 8; i++) {
      code += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return code;
  }
}
