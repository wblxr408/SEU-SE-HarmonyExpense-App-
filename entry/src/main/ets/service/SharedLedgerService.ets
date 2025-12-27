
/**
 * 共享账本服务 - 业务逻辑层
 *
 * 功能：
 * 1. 共享账本创建与管理
 * 2. 成员邀请与权限管理
 * 3. 共享账单分摊与结算
 * 4. 审批流程管理
 * 5. 活动日志记录
 *
 * @version 2.0.0
 * @author HarmonyExpense Team
 */

import {
  SharedLedgerDAO,
  LedgerMemberDAO,
  LedgerInvitationDAO,
  SharedBillDAO,
  ApprovalRecordDAO,
  MemberActivityDAO,
  SharedBillStatistics
} from '../dao/SharedLedgerDAO';
import {
  SharedLedger,
  LedgerMember,
  LedgerInvitation,
  SharedBill,
  ApprovalRecord,
  MemberActivity
} from '../model/SharedLedger';
import { NotificationService } from './NotificationService';

/**
 * 账本创建参数接口
 */
export interface CreateLedgerParams {
  name: string;
  description?: string;
  type: 'family' | 'roommate' | 'couple' | 'group' | 'trip' | 'project' | 'other';
  currency: string;
  icon?: string;
  color: string;
  ownerId: number;
  ownerName: string;
  settings?: LedgerSettingsParam;
}

/**
 * 账本设置参数接口
 */
export interface LedgerSettingsParam {
  allowMemberInvite: boolean;
  requireApproval: boolean;
  autoSplit: boolean;
  defaultSplitMethod: string;
}

/**
 * 账单分摊接口
 */
export interface BillSplit {
  memberId: number;
  amount: number;
  percentage: number;
}

/**
 * 活动元数据接口
 */
export interface ActivityMetadata {
  inviteeId?: number;
  inviteeName?: string;
  role?: string;
  billId?: number;
  amount?: number;
  splitMethod?: string;
  memberId?: number;
  memberName?: string;
  newRole?: string;
  version?: number;
  comments?: string;
}

/**
 * 更新账本参数接口
 */
export interface UpdateLedgerParams {
  name?: string;
  description?: string;
  type?: string;
  currency?: string;
  icon?: string;
  color?: string;
  settingsJson?: string;
}

/**
 * 更新账单参数接口
 */
export interface UpdateSharedBillParams {
  amount?: number;
  description?: string;
  categoryId?: number;
  categoryName?: string;
  splitMethod?: string;
  splitsJson?: string;
  attachments?: string;
  status?: string;
}

/**
 * 账单分摊结果接口
 */
export interface SplitResult {
  memberId: number;
  memberName: string;
  amountOwed: number;
  percentage: number;
}

/**
 * 成员信息接口
 */
export interface MemberInfo {
  memberId: number;
  memberName: string;
}

/**
 * 结算结果接口
 */
export interface SettlementResult {
  from: MemberInfo;
  to: MemberInfo;
  amount: number;
}

/**
 * 账本设置解析结果接口
 */
export interface ParsedLedgerSettings {
  allowMemberInvite: boolean;
  requireApproval: boolean;
  autoSplit: boolean;
  defaultSplitMethod: string;
}

/**
 * 共享账本服务类
 */
export class SharedLedgerService {

  // ==================== 账本管理 ====================

  /**
   * 创建共享账本
   */
  static async createLedger(params: CreateLedgerParams): Promise<number> {
    try {
      const ledger = new SharedLedger();
      ledger.name = params.name;
      ledger.description = params.description || '';
      ledger.type = params.type;
      ledger.ownerId = params.ownerId;
      ledger.ownerName = params.ownerName;
      ledger.currency = params.currency;
      ledger.icon = params.icon || '';
      ledger.color = params.color;
      ledger.memberCount = 1; // 创建者自己
      const defaultSettings: LedgerSettingsParam = {
        allowMemberInvite: true,
        requireApproval: false,
        autoSplit: true,
        defaultSplitMethod: 'equal'
      };
      ledger.settingsJson = JSON.stringify(params.settings || defaultSettings);

      // 创建账本
      const ledgerId = await SharedLedgerDAO.insert(ledger);

      // 添加创建者为成员（所有者角色）
      const ownerMember = new LedgerMember();
      ownerMember.ledgerId = ledgerId;
      ownerMember.userId = params.ownerId;
      ownerMember.userName = params.ownerName;
      ownerMember.role = 'owner';
      ownerMember.joinedAt = new Date().toISOString();

      await LedgerMemberDAO.insert(ownerMember);

      // 记录活动
      const metadata: ActivityMetadata = {};
      await SharedLedgerService.logActivity(
        ledgerId,
        params.ownerId,
        params.ownerName,
        'ledger_created',
        `创建了账本「${params.name}」`,
        metadata
      );

      return ledgerId;
    } catch (error) {
      console.error('[SharedLedgerService] 创建账本失败:', error);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 更新账本信息
   */
  static async updateLedger(ledgerId: number, updates: UpdateLedgerParams): Promise<boolean> {
    try {
      const ledger = await SharedLedgerDAO.getById(ledgerId);
      if (!ledger) {
        throw new Error('账本不存在');
      }

      // 手动更新字段
      if (updates.name !== undefined) ledger.name = updates.name;
      if (updates.description !== undefined) ledger.description = updates.description;
      if (updates.type !== undefined) ledger.type = updates.type;
      if (updates.currency !== undefined) ledger.currency = updates.currency;
      if (updates.icon !== undefined) ledger.icon = updates.icon;
      if (updates.color !== undefined) ledger.color = updates.color;
      if (updates.settingsJson !== undefined) ledger.settingsJson = updates.settingsJson;

      return await SharedLedgerDAO.update(ledger);
    } catch (error) {
      console.error('[SharedLedgerService] 更新账本失败:', error);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 获取用户的所有账本
   */
  static async getUserLedgers(userId: number): Promise<SharedLedger[]> {
    try {
      return await SharedLedgerDAO.getByUserId(userId);
    } catch (error) {
      console.error('[SharedLedgerService] 获取用户账本失败:', error);
      return [];
    }
  }

  /**
   * 获取账本详情
   */
  static async getLedgerDetail(ledgerId: number): Promise<SharedLedger | null> {
    try {
      return await SharedLedgerDAO.getById(ledgerId);
    } catch (error) {
      console.error('[SharedLedgerService] 获取账本详情失败:', error);
      return null;
    }
  }

  /**
   * 删除账本（软删除）
   */
  static async deleteLedger(ledgerId: number, userId: number): Promise<boolean> {
    try {
      // 检查权限
      const hasPermission = await SharedLedgerService.checkPermission(ledgerId, userId, 'owner');
      if (!hasPermission) {
        throw new Error('无权限删除账本');
      }

      const success = await SharedLedgerDAO.softDelete(ledgerId);

      if (success) {
        const ledger = await SharedLedgerDAO.getById(ledgerId);
        const metadata: ActivityMetadata = {};
        if (ledger) {
          await SharedLedgerService.logActivity(
            ledgerId,
            userId,
            ledger.ownerName,
            'ledger_deleted',
            `删除了账本「${ledger.name}」`,
            metadata
          );
        }
      }

      return success;
    } catch (error) {
      console.error('[SharedLedgerService] 删除账本失败:', error);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  // ==================== 成员管理 ====================

  /**
   * 邀请成员
   */
  static async inviteMember(
    ledgerId: number,
    inviterId: number,
    inviterName: string,
    inviteeId: number,
    inviteeName: string,
    role: 'admin' | 'member' | 'viewer' = 'member'
  ): Promise<number> {
    try {
      // 检查邀请者权限
      const canInvite = await SharedLedgerService.checkPermission(ledgerId, inviterId, 'admin');
      if (!canInvite) {
        throw new Error('无权限邀请成员');
      }

      // 检查是否已是成员
      const existingMember = await LedgerMemberDAO.getMember(ledgerId, inviteeId);
      if (existingMember) {
        throw new Error('该用户已是账本成员');
      }

      // 创建邀请
      const invitation = new LedgerInvitation();
      invitation.ledgerId = ledgerId;
      invitation.inviterId = inviterId;
      invitation.inviterName = inviterName;
      invitation.inviteeId = inviteeId;
      invitation.inviteeName = inviteeName;
      invitation.role = role;
      invitation.status = 'pending';

      // 设置过期时间（7天后）
      const expiresAt = new Date();
      expiresAt.setDate(expiresAt.getDate() + 7);
      invitation.expiresAt = expiresAt.toISOString();

      const invitationId = await LedgerInvitationDAO.insert(invitation);

      // 记录活动
      const ledger = await SharedLedgerDAO.getById(ledgerId);
      if (ledger) {
        const metadata: ActivityMetadata = { inviteeId, inviteeName, role };
        await SharedLedgerService.logActivity(
          ledgerId,
          inviterId,
          inviterName,
          'member_invited',
          `邀请 ${inviteeName} 加入账本`,
          metadata
        );

        // 发送共享账本通知给被邀请者
        try {
          await NotificationService.sendSharedLedgerNotification(
            inviteeId,
            ledgerId,
            '账本邀请',
            `${inviterName} 邀请您加入账本"${ledger.name}"`
          );
        } catch (notifyError) {
          console.error('[SharedLedgerService] 发送邀请通知失败:', notifyError);
        }
      }

      return invitationId;
    } catch (error) {
      console.error('[SharedLedgerService] 邀请成员失败:', error);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 接受邀请
   */
  static async acceptInvitation(invitationId: number): Promise<boolean> {
    try {
      const invitation = await LedgerInvitationDAO.getById(invitationId);
      if (!invitation) {
        throw new Error('邀请不存在');
      }

      if (invitation.status !== 'pending') {
        throw new Error('邀请已处理');
      }

      // 检查是否过期
      if (new Date(invitation.expiresAt) < new Date()) {
        await LedgerInvitationDAO.updateStatus(invitationId, 'expired');
        throw new Error('邀请已过期');
      }

      // 添加为成员
      const member = new LedgerMember();
      member.ledgerId = invitation.ledgerId;
      member.userId = invitation.inviteeId;
      member.userName = invitation.inviteeName;
      member.role = invitation.role;
      member.joinedAt = new Date().toISOString();

      await LedgerMemberDAO.insert(member);

      // 更新邀请状态
      await LedgerInvitationDAO.updateStatus(invitationId, 'accepted');

      // 更新账本成员数
      await SharedLedgerDAO.updateMemberCount(invitation.ledgerId);

      // 记录活动
      const metadata: ActivityMetadata = { role: invitation.role };
      await SharedLedgerService.logActivity(
        invitation.ledgerId,
        invitation.inviteeId,
        invitation.inviteeName,
        'member_joined',
        `${invitation.inviteeName} 加入了账本`,
        metadata
      );

      // 通知邀请者：被邀请人已接受
      try {
        const ledger = await SharedLedgerDAO.getById(invitation.ledgerId);
        if (ledger) {
          await NotificationService.sendSharedLedgerNotification(
            invitation.inviterId,
            invitation.ledgerId,
            '邀请已接受',
            `${invitation.inviteeName} 已加入账本"${ledger.name}"`
          );
        }
      } catch (notifyError) {
        console.error('[SharedLedgerService] 发送接受通知失败:', notifyError);
      }

      return true;
    } catch (error) {
      console.error('[SharedLedgerService] 接受邀请失败:', error);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 拒绝邀请
   */
  static async declineInvitation(invitationId: number): Promise<boolean> {
    try {
      return await LedgerInvitationDAO.updateStatus(invitationId, 'declined');
    } catch (error) {
      console.error('[SharedLedgerService] 拒绝邀请失败:', error);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 移除成员
   */
  static async removeMember(
    ledgerId: number,
    memberId: number,
    operatorId: number
  ): Promise<boolean> {
    try {
      // 检查操作者权限
      const hasPermission = await SharedLedgerService.checkPermission(ledgerId, operatorId, 'admin');
      if (!hasPermission) {
        throw new Error('无权限移除成员');
      }

      // 不能移除所有者
      const member = await LedgerMemberDAO.getMember(ledgerId, memberId);
      if (member && member.role === 'owner') {
        throw new Error('不能移除账本所有者');
      }

      const success = await LedgerMemberDAO.softDelete(ledgerId, memberId);

      if (success) {
        // 更新账本成员数
        await SharedLedgerDAO.updateMemberCount(ledgerId);

        // 记录活动
        if (member) {
          const metadata: ActivityMetadata = { memberId, memberName: member.userName };
          await SharedLedgerService.logActivity(
            ledgerId,
            operatorId,
            '',
            'member_removed',
            `${member.userName} 被移出账本`,
            metadata
          );
        }
      }

      return success;
    } catch (error) {
      console.error('[SharedLedgerService] 移除成员失败:', error);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 更新成员角色
   */
  static async updateMemberRole(
    ledgerId: number,
    memberId: number,
    newRole: 'admin' | 'member' | 'viewer',
    operatorId: number
  ): Promise<boolean> {
    try {
      // 检查操作者权限
      const hasPermission = await SharedLedgerService.checkPermission(ledgerId, operatorId, 'owner');
      if (!hasPermission) {
        throw new Error('无权限修改成员角色');
      }

      const success = await LedgerMemberDAO.updateRole(ledgerId, memberId, newRole);

      if (success) {
        const member = await LedgerMemberDAO.getMember(ledgerId, memberId);
        if (member) {
          const metadata: ActivityMetadata = { memberId, newRole };
          await SharedLedgerService.logActivity(
            ledgerId,
            operatorId,
            '',
            'member_role_changed',
            `${member.userName} 的角色变更为 ${newRole}`,
            metadata
          );
        }
      }

      return success;
    } catch (error) {
      console.error('[SharedLedgerService] 更新成员角色失败:', error);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 获取账本成员列表
   */
  static async getLedgerMembers(ledgerId: number): Promise<LedgerMember[]> {
    try {
      return await LedgerMemberDAO.getByLedgerId(ledgerId);
    } catch (error) {
      console.error('[SharedLedgerService] 获取成员列表失败:', error);
      return [];
    }
  }

  // ==================== 共享账单管理 ====================

  /**
   * 创建共享账单
   */
  static async createSharedBill(
    ledgerId: number,
    creatorId: number,
    creatorName: string,
    amount: number,
    description: string,
    categoryId: number,
    categoryName: string,
    splitMethod: 'equal' | 'by_amount' | 'by_percentage' | 'custom',
    splits: BillSplit[],
    attachments?: string
  ): Promise<number> {
    try {
      // 检查权限
      const canCreate = await SharedLedgerService.checkPermission(ledgerId, creatorId, 'member');
      if (!canCreate) {
        throw new Error('无权限创建账单');
      }

      // 验证分摊总和
      if (!SharedLedgerService.validateSplits(amount, splitMethod, splits)) {
        throw new Error('账单分摊金额不正确');
      }

      // 获取账本设置
      const ledger = await SharedLedgerDAO.getById(ledgerId);
      if (!ledger) {
        throw new Error('账本不存在');
      }

      const settingsObj = JSON.parse(ledger.settingsJson) as ParsedLedgerSettings;
      const requireApproval = settingsObj.requireApproval || false;

      // 创建账单
      const bill = new SharedBill();
      bill.ledgerId = ledgerId;
      bill.creatorId = creatorId;
      bill.creatorName = creatorName;
      bill.amount = amount;
      bill.description = description;
      bill.categoryId = categoryId;
      bill.categoryName = categoryName;
      bill.splitMethod = splitMethod;
      bill.splitsJson = JSON.stringify(splits);
      bill.attachments = attachments || '';
      bill.status = requireApproval ? 'pending_approval' : 'approved';
      bill.version = 1;

      const billId = await SharedBillDAO.insert(bill);

      // 如果需要审批，创建审批记录
      if (requireApproval) {
        await SharedLedgerService.createApprovalRecord(ledgerId, billId, creatorId);
      }

      // 记录活动
      const metadata: ActivityMetadata = { billId, amount, splitMethod };
      await SharedLedgerService.logActivity(
        ledgerId,
        creatorId,
        creatorName,
        'bill_created',
        `创建了账单: ${description} ¥${amount.toFixed(2)}`,
        metadata
      );

      // 通知账本成员（除了创建者）
      try {
        const members = await LedgerMemberDAO.getByLedgerId(ledgerId);
        const ledger = await SharedLedgerDAO.getById(ledgerId);
        if (ledger) {
          for (const member of members) {
            if (member.userId !== creatorId) {
              await NotificationService.sendSharedLedgerNotification(
                member.userId,
                ledgerId,
                '新账单',
                `${creatorName} 在账本"${ledger.name}"中创建了账单: ${description} ¥${amount.toFixed(2)}`
              );
            }
          }
        }
      } catch (notifyError) {
        console.error('[SharedLedgerService] 发送账单创建通知失败:', notifyError);
      }

      return billId;
    } catch (error) {
      console.error('[SharedLedgerService] 创建共享账单失败:', error);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 验证分摊金额
   */
  private static validateSplits(
    totalAmount: number,
    splitMethod: string,
    splits: BillSplit[]
  ): boolean {
    if (splitMethod === 'by_amount') {
      let sum = 0;
      for (let i = 0; i < splits.length; i++) {
        sum += splits[i].amount;
      }
      return Math.abs(sum - totalAmount) < 0.01; // 允许0.01的误差
    } else if (splitMethod === 'by_percentage') {
      let sum = 0;
      for (let i = 0; i < splits.length; i++) {
        sum += splits[i].percentage;
      }
      return Math.abs(sum - 100) < 0.01;
    }
    return true;
  }

  /**
   * 更新共享账单
   */
  static async updateSharedBill(
    billId: number,
    operatorId: number,
    updates: UpdateSharedBillParams
  ): Promise<boolean> {
    try {
      const bill = await SharedBillDAO.getById(billId);
      if (!bill) {
        throw new Error('账单不存在');
      }

      // 检查权限
      const canEdit = await SharedLedgerService.checkPermission(bill.ledgerId, operatorId, 'member');
      if (!canEdit && bill.creatorId !== operatorId) {
        throw new Error('无权限修改账单');
      }

      // 更新版本号
      bill.version += 1;

      // 手动更新字段
      if (updates.amount !== undefined) bill.amount = updates.amount;
      if (updates.description !== undefined) bill.description = updates.description;
      if (updates.categoryId !== undefined) bill.categoryId = updates.categoryId;
      if (updates.categoryName !== undefined) bill.categoryName = updates.categoryName;
      if (updates.splitMethod !== undefined) bill.splitMethod = updates.splitMethod;
      if (updates.splitsJson !== undefined) bill.splitsJson = updates.splitsJson;
      if (updates.attachments !== undefined) bill.attachments = updates.attachments;
      if (updates.status !== undefined) bill.status = updates.status;

      const success = await SharedBillDAO.update(bill);

      if (success) {
        const metadata: ActivityMetadata = { billId, version: bill.version };
        await SharedLedgerService.logActivity(
          bill.ledgerId,
          operatorId,
          '',
          'bill_updated',
          `更新了账单: ${bill.description}`,
          metadata
        );
      }

      return success;
    } catch (error) {
      console.error('[SharedLedgerService] 更新共享账单失败:', error);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 删除共享账单
   */
  static async deleteSharedBill(billId: number, operatorId: number): Promise<boolean> {
    try {
      const bill = await SharedBillDAO.getById(billId);
      if (!bill) {
        throw new Error('账单不存在');
      }

      // 检查权限
      const canDelete = await SharedLedgerService.checkPermission(bill.ledgerId, operatorId, 'admin');
      if (!canDelete && bill.creatorId !== operatorId) {
        throw new Error('无权限删除账单');
      }

      const success = await SharedBillDAO.softDelete(billId);

      if (success) {
        const metadata: ActivityMetadata = { billId };
        await SharedLedgerService.logActivity(
          bill.ledgerId,
          operatorId,
          '',
          'bill_deleted',
          `删除了账单: ${bill.description}`,
          metadata
        );
      }

      return success;
    } catch (error) {
      console.error('[SharedLedgerService] 删除共享账单失败:', error);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 获取账本的所有账单
   */
  static async getLedgerBills(ledgerId: number): Promise<SharedBill[]> {
    try {
      return await SharedBillDAO.getByLedgerId(ledgerId);
    } catch (error) {
      console.error('[SharedLedgerService] 获取账本账单失败:', error);
      return [];
    }
  }

  // ==================== 审批管理 ====================

  /**
   * 创建审批记录
   */
  private static async createApprovalRecord(
    ledgerId: number,
    billId: number,
    submitterId: number
  ): Promise<boolean> {
    try {
      // 获取管理员成员
      const members = await LedgerMemberDAO.getByLedgerId(ledgerId);
      const approvers = members.filter(m => m.role === 'admin' || m.role === 'owner');

      for (let i = 0; i < approvers.length; i++) {
        const approver = approvers[i];
        if (approver.userId !== submitterId) {
          const record = new ApprovalRecord();
          record.billId = billId;
          record.approverId = approver.userId;
          record.approverName = approver.userName;
          record.status = 'pending';

          await ApprovalRecordDAO.insert(record);
        }
      }
      return true;
    } catch (error) {
      console.error('[SharedLedgerService] 创建审批记录失败:', error);
      return false;
    }
  }

  /**
   * 审批账单
   */
  static async approveBill(
    billId: number,
    approverId: number,
    approved: boolean,
    comments?: string
  ): Promise<boolean> {
    try {
      const bill = await SharedBillDAO.getById(billId);
      if (!bill) {
        throw new Error('账单不存在');
      }

      // 检查权限
      const hasPermission = await SharedLedgerService.checkPermission(bill.ledgerId, approverId, 'admin');
      if (!hasPermission) {
        throw new Error('无权限审批账单');
      }

      // 更新审批记录
      const success = await ApprovalRecordDAO.updateApproval(
        billId,
        approverId,
        approved ? 'approved' : 'rejected',
        comments
      );

      if (success) {
        // 检查是否所有审批完成
        const allApproved = await SharedLedgerService.checkAllApproved(billId);

        if (allApproved) {
          await SharedBillDAO.updateStatus(billId, 'approved');
        } else if (!approved) {
          await SharedBillDAO.updateStatus(billId, 'rejected');
        }

        // 记录活动
        const metadata: ActivityMetadata = { billId, comments };
        await SharedLedgerService.logActivity(
          bill.ledgerId,
          approverId,
          '',
          approved ? 'bill_approved' : 'bill_rejected',
          `${approved ? '批准' : '拒绝'}了账单: ${bill.description}`,
          metadata
        );
      }

      return success;
    } catch (error) {
      console.error('[SharedLedgerService] 审批账单失败:', error);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 检查是否所有审批完成
   */
  private static async checkAllApproved(billId: number): Promise<boolean> {
    try {
      const records = await ApprovalRecordDAO.getByBillId(billId);
      return records.every(r => r.status === 'approved');
    } catch (error) {
      console.error('[SharedLedgerService] 检查审批状态失败:', error);
      return false;
    }
  }

  // ==================== 结算计算 ====================

  /**
   * 计算账本结算方案
   */
  static async calculateSettlement(ledgerId: number): Promise<SettlementResult[]> {
    try {
      // 获取所有已批准的账单
      const bills = await SharedBillDAO.getByStatus(ledgerId, 'approved');

      // 计算每个成员的净欠款
      interface BalanceInfo {
        name: string;
        balance: number;
      }
      const balances: Map<number, BalanceInfo> = new Map();

      for (let i = 0; i < bills.length; i++) {
        const bill = bills[i];
        const splits: BillSplit[] = JSON.parse(bill.splitsJson);

        // 付款人收入
        const payer = balances.get(bill.creatorId) || { name: bill.creatorName, balance: 0 };
        payer.balance += bill.amount;
        balances.set(bill.creatorId, payer);

        // 参与者支出
        for (let j = 0; j < splits.length; j++) {
          const split = splits[j];
          const member = balances.get(split.memberId) || { name: '', balance: 0 };
          member.balance -= split.amount;
          balances.set(split.memberId, member);
        }
      }

      // 生成结算方案（最小转账次数算法）
      interface SettlementParticipant {
        id: number;
        name: string;
        amount: number;
      }
      const results: SettlementResult[] = [];
      const debtors: SettlementParticipant[] = [];
      const creditors: SettlementParticipant[] = [];

      balances.forEach((value, memberId) => {
        if (value.balance > 0.01) {
          creditors.push({ id: memberId, name: value.name, amount: value.balance });
        } else if (value.balance < -0.01) {
          debtors.push({ id: memberId, name: value.name, amount: -value.balance });
        }
      });

      // 简化结算
      let i = 0;
      let j = 0;
      while (i < debtors.length && j < creditors.length) {
        const debt = debtors[i].amount;
        const credit = creditors[j].amount;
        const settleAmount = Math.min(debt, credit);

        results.push({
          from: { memberId: debtors[i].id, memberName: debtors[i].name },
          to: { memberId: creditors[j].id, memberName: creditors[j].name },
          amount: settleAmount
        });

        debtors[i].amount -= settleAmount;
        creditors[j].amount -= settleAmount;

        if (debtors[i].amount < 0.01) i++;
        if (creditors[j].amount < 0.01) j++;
      }

      return results;
    } catch (error) {
      console.error('[SharedLedgerService] 计算结算方案失败:', error);
      return [];
    }
  }

  // ==================== 活动日志 ====================

  /**
   * 记录活动
   */
  private static async logActivity(
    ledgerId: number,
    userId: number,
    userName: string,
    activityType: string,
    description: string,
    metadata: ActivityMetadata
  ): Promise<boolean> {
    try {
      const activity = new MemberActivity();
      activity.ledgerId = ledgerId;
      activity.userId = userId;
      activity.userName = userName;
      activity.activityType = activityType;
      activity.description = description;
      activity.metadataJson = JSON.stringify(metadata);

      await MemberActivityDAO.insert(activity);
      return true;
    } catch (error) {
      console.error('[SharedLedgerService] 记录活动失败:', error);
      return false;
    }
  }

  /**
   * 获取账本活动日志
   */
  static async getLedgerActivities(ledgerId: number, limit: number = 50): Promise<MemberActivity[]> {
    try {
      return await MemberActivityDAO.getByLedgerId(ledgerId, limit);
    } catch (error) {
      console.error('[SharedLedgerService] 获取活动日志失败:', error);
      return [];
    }
  }

  // ==================== 权限检查 ====================

  /**
   * 检查用户权限
   */
  static async checkPermission(
    ledgerId: number,
    userId: number,
    requiredRole: 'owner' | 'admin' | 'member' | 'viewer'
  ): Promise<boolean> {
    try {
      const member = await LedgerMemberDAO.getMember(ledgerId, userId);
      if (!member) {
        return false;
      }

      // 获取成员角色等级
      let memberRoleLevel = 0;
      if (member.role === 'owner') {
        memberRoleLevel = 4;
      } else if (member.role === 'admin') {
        memberRoleLevel = 3;
      } else if (member.role === 'member') {
        memberRoleLevel = 2;
      } else if (member.role === 'viewer') {
        memberRoleLevel = 1;
      }

      // 获取所需角色等级
      let requiredRoleLevel = 0;
      if (requiredRole === 'owner') {
        requiredRoleLevel = 4;
      } else if (requiredRole === 'admin') {
        requiredRoleLevel = 3;
      } else if (requiredRole === 'member') {
        requiredRoleLevel = 2;
      } else if (requiredRole === 'viewer') {
        requiredRoleLevel = 1;
      }

      return memberRoleLevel >= requiredRoleLevel;
    } catch (error) {
      console.error('[SharedLedgerService] 检查权限失败:', error);
      return false;
    }
  }

  // ==================== 统计数据 ====================

  /**
   * 获取账本统计
   */
  static async getLedgerStatistics(ledgerId: number): Promise<SharedBillStatistics> {
    try {
      return await SharedBillDAO.getStatistics(ledgerId);
    } catch (error) {
      console.error('[SharedLedgerService] 获取账本统计失败:', error);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }
}
