/**
 * 共享账本数据访问对象 (DAO)
 *
 * 功能：
 * - 共享账本的CRUD操作
 * - 账本成员管理
 * - 邀请管理
 * - 共享账单管理
 * - 审批流程管理
 * - 成员活动记录
 *
 * @version 1.0.0
 * @author HarmonyExpense Team
 */

import relationalStore from '@ohos.data.relationalStore';
import { DatabaseManager } from '../database/DatabaseManager';
import { DAOHelper } from '../common/DAOHelper';
import {
  SharedLedger,
  LedgerMember,
  LedgerInvitation,
  SharedBill,
  ApprovalRecord,
  MemberActivity,
  INVITATION_STATUS_PENDING,
  INVITATION_STATUS_EXPIRED,
  APPROVAL_STATUS_PENDING
} from '../model/SharedLedger';

/**
 * 账单统计信息接口
 */
export interface SharedBillStatistics {
  totalBills: number;
  totalApprovedAmount: number;
  pendingCount: number;
}

/**
 * 共享账本DAO
 */
export class SharedLedgerDAO {
  /**
   * 创建共享账本
   */
  static async insert(ledger: SharedLedger): Promise<number> {
    try {
      const store = DatabaseManager.getDatabase();
      const now = new Date().toISOString();
      ledger.createdAt = now;
      ledger.updatedAt = now;

      const values: relationalStore.ValuesBucket = {
        name: ledger.name,
        description: ledger.description || null,
        type: ledger.type,
        owner_id: ledger.ownerId,
        owner_name: ledger.ownerName,
        currency: ledger.currency,
        icon: ledger.icon || null,
        color: ledger.color,
        member_count: ledger.memberCount,
        settings_json: ledger.settingsJson,
        created_at: ledger.createdAt,
        updated_at: ledger.updatedAt,
        is_deleted: ledger.isDeleted
      };

      const rowId = await store.insert(SharedLedger.tableName, values);
      return rowId;
    } catch (error) {
      throw DAOHelper.toError('[SharedLedgerDAO] 创建共享账本失败', error);
    }
  }

  /**
   * 更新共享账本
   */
  static async update(ledger: SharedLedger): Promise<boolean> {
    try {
      const store = DatabaseManager.getDatabase();
      ledger.updatedAt = new Date().toISOString();

      const values: relationalStore.ValuesBucket = {
        name: ledger.name,
        description: ledger.description || null,
        type: ledger.type,
        currency: ledger.currency,
        icon: ledger.icon || null,
        color: ledger.color,
        member_count: ledger.memberCount,
        settings_json: ledger.settingsJson,
        updated_at: ledger.updatedAt
      };

      const predicates = new relationalStore.RdbPredicates(SharedLedger.tableName);
      predicates.equalTo('ledger_id', ledger.ledgerId);

      const rowsAffected = await store.update(values, predicates);
      return rowsAffected > 0;
    } catch (error) {
      throw DAOHelper.toError('[SharedLedgerDAO] 更新共享账本失败', error);
    }
  }

  /**
   * 根据ID获取账本
   */
  static async getById(ledgerId: number): Promise<SharedLedger | null> {
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const store = DatabaseManager.getDatabase();
      const predicates = new relationalStore.RdbPredicates(SharedLedger.tableName);
      predicates.equalTo('ledger_id', ledgerId);
      predicates.equalTo('is_deleted', 0);

      resultSet = await store.query(predicates);

      if (resultSet.goToFirstRow()) {
        return SharedLedgerDAO.mapRowToLedger(resultSet);
      }
      return null;
    } catch (error) {
      throw DAOHelper.toError('[SharedLedgerDAO] 根据ID获取账本失败', error);
    } finally {
      DAOHelper.closeResultSet(resultSet);
    }
  }

  /**
   * 获取用户拥有的账本
   */
  static async getByOwnerId(ownerId: number): Promise<SharedLedger[]> {
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const store = DatabaseManager.getDatabase();
      const predicates = new relationalStore.RdbPredicates(SharedLedger.tableName);
      predicates.equalTo('owner_id', ownerId);
      predicates.equalTo('is_deleted', 0);
      predicates.orderByDesc('created_at');

      resultSet = await store.query(predicates);

      const ledgers: SharedLedger[] = [];
      while (resultSet.goToNextRow()) {
        ledgers.push(SharedLedgerDAO.mapRowToLedger(resultSet));
      }
      return ledgers;
    } catch (error) {
      throw DAOHelper.toError('[SharedLedgerDAO] 获取用户拥有的账本失败', error);
    } finally {
      DAOHelper.closeResultSet(resultSet);
    }
  }

  /**
   * 获取用户参与的所有账本（包括作为成员）
   */
  static async getByUserId(userId: number): Promise<SharedLedger[]> {
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const store = DatabaseManager.getDatabase();

      // 查询用户作为owner或member的账本
      const sql = `
        SELECT DISTINCT l.*
        FROM ${SharedLedger.tableName} l
        LEFT JOIN ${LedgerMember.tableName} m ON l.ledger_id = m.ledger_id
        WHERE (l.owner_id = ? OR m.user_id = ?)
          AND l.is_deleted = 0
          AND (m.is_deleted = 0 OR m.is_deleted IS NULL)
        ORDER BY l.created_at DESC
      `;

      resultSet = await store.querySql(sql, [userId.toString(), userId.toString()]);

      const ledgers: SharedLedger[] = [];
      while (resultSet.goToNextRow()) {
        ledgers.push(SharedLedgerDAO.mapRowToLedger(resultSet));
      }
      return ledgers;
    } catch (error) {
      throw DAOHelper.toError('[SharedLedgerDAO] 获取用户参与的账本失败', error);
    } finally {
      DAOHelper.closeResultSet(resultSet);
    }
  }

  /**
   * 更新成员数量（自动计算）
   */
  static async updateMemberCount(ledgerId: number): Promise<boolean> {
    try {
      const store = DatabaseManager.getDatabase();

      // 统计当前账本的成员数量
      const countSql = `
        SELECT COUNT(*) as count
        FROM ${LedgerMember.tableName}
        WHERE ledger_id = ? AND is_deleted = 0
      `;
      const countRs = await store.querySql(countSql, [ledgerId]);
      let memberCount = 0;
      if (countRs.goToFirstRow()) {
        memberCount = DAOHelper.getLong(countRs, 'count');
      }
      countRs.close();

      const values: relationalStore.ValuesBucket = {
        member_count: memberCount,
        updated_at: new Date().toISOString()
      };

      const predicates = new relationalStore.RdbPredicates(SharedLedger.tableName);
      predicates.equalTo('ledger_id', ledgerId);

      const rowsAffected = await store.update(values, predicates);
      return rowsAffected > 0;
    } catch (error) {
      throw DAOHelper.toError('[SharedLedgerDAO] 更新成员数量失败', error);
    }
  }

  /**
   * 软删除账本
   */
  static async softDelete(ledgerId: number): Promise<boolean> {
    try {
      await DAOHelper.softDelete(SharedLedger.tableName, 'ledger_id', ledgerId);
      return true;
    } catch (error) {
      throw DAOHelper.toError('[SharedLedgerDAO] 软删除账本失败', error);
    }
  }

  /**
   * 映射数据库行到SharedLedger对象
   */
  private static mapRowToLedger(resultSet: relationalStore.ResultSet): SharedLedger {
    return new SharedLedger(
      DAOHelper.getLong(resultSet, 'ledger_id'),
      DAOHelper.getString(resultSet, 'name'),
      DAOHelper.getString(resultSet, 'description'),
      DAOHelper.getString(resultSet, 'type'),
      DAOHelper.getLong(resultSet, 'owner_id'),
      DAOHelper.getString(resultSet, 'owner_name'),
      DAOHelper.getString(resultSet, 'currency'),
      DAOHelper.getString(resultSet, 'icon'),
      DAOHelper.getString(resultSet, 'color'),
      DAOHelper.getLong(resultSet, 'member_count'),
      DAOHelper.getString(resultSet, 'settings_json'),
      DAOHelper.getString(resultSet, 'created_at'),
      DAOHelper.getString(resultSet, 'updated_at'),
      DAOHelper.getLong(resultSet, 'is_deleted')
    );
  }
}

/**
 * 账本成员DAO
 */
export class LedgerMemberDAO {
  /**
   * 添加成员
   */
  static async insert(member: LedgerMember): Promise<number> {
    try {
      const store = DatabaseManager.getDatabase();
      const now = new Date().toISOString();
      member.joinedAt = now;
      member.lastActiveAt = now;
      member.createdAt = now;
      member.updatedAt = now;

      const values: relationalStore.ValuesBucket = {
        ledger_id: member.ledgerId,
        user_id: member.userId,
        username: member.username,
        email: member.email,
        avatar: member.avatar || null,
        role: member.role,
        permissions_json: member.permissionsJson,
        nickname: member.nickname || null,
        contribution_amount: member.contributionAmount,
        bill_count: member.billCount,
        joined_at: member.joinedAt,
        last_active_at: member.lastActiveAt,
        is_active: member.isActive,
        created_at: member.createdAt,
        updated_at: member.updatedAt,
        is_deleted: member.isDeleted
      };

      const rowId = await store.insert(LedgerMember.tableName, values);
      return rowId;
    } catch (error) {
      throw DAOHelper.toError('[LedgerMemberDAO] 添加成员失败', error);
    }
  }

  /**
   * 更新成员
   */
  static async update(member: LedgerMember): Promise<boolean> {
    try {
      const store = DatabaseManager.getDatabase();
      member.updatedAt = new Date().toISOString();

      const values: relationalStore.ValuesBucket = {
        role: member.role,
        permissions_json: member.permissionsJson,
        nickname: member.nickname || null,
        contribution_amount: member.contributionAmount,
        bill_count: member.billCount,
        is_active: member.isActive,
        updated_at: member.updatedAt
      };

      const predicates = new relationalStore.RdbPredicates(LedgerMember.tableName);
      predicates.equalTo('member_id', member.memberId);

      const rowsAffected = await store.update(values, predicates);
      return rowsAffected > 0;
    } catch (error) {
      throw DAOHelper.toError('[LedgerMemberDAO] 更新成员失败', error);
    }
  }

  /**
   * 获取账本的所有成员
   */
  static async getByLedgerId(ledgerId: number): Promise<LedgerMember[]> {
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const store = DatabaseManager.getDatabase();
      const predicates = new relationalStore.RdbPredicates(LedgerMember.tableName);
      predicates.equalTo('ledger_id', ledgerId);
      predicates.equalTo('is_deleted', 0);
      predicates.orderByDesc('role');
      predicates.orderByDesc('joined_at');

      resultSet = await store.query(predicates);

      const members: LedgerMember[] = [];
      while (resultSet.goToNextRow()) {
        members.push(LedgerMemberDAO.mapRowToMember(resultSet));
      }
      return members;
    } catch (error) {
      throw DAOHelper.toError('[LedgerMemberDAO] 获取账本成员失败', error);
    } finally {
      DAOHelper.closeResultSet(resultSet);
    }
  }

  /**
   * 获取用户在账本中的成员身份
   */
  static async getMember(ledgerId: number, userId: number): Promise<LedgerMember | null> {
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const store = DatabaseManager.getDatabase();
      const predicates = new relationalStore.RdbPredicates(LedgerMember.tableName);
      predicates.equalTo('ledger_id', ledgerId);
      predicates.equalTo('user_id', userId);
      predicates.equalTo('is_deleted', 0);

      resultSet = await store.query(predicates);

      if (resultSet.goToFirstRow()) {
        return LedgerMemberDAO.mapRowToMember(resultSet);
      }
      return null;
    } catch (error) {
      throw DAOHelper.toError('[LedgerMemberDAO] 获取成员身份失败', error);
    } finally {
      DAOHelper.closeResultSet(resultSet);
    }
  }

  /**
   * 更新最后活跃时间
   */
  static async updateLastActive(memberId: number): Promise<boolean> {
    try {
      const store = DatabaseManager.getDatabase();

      const values: relationalStore.ValuesBucket = {
        last_active_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      };

      const predicates = new relationalStore.RdbPredicates(LedgerMember.tableName);
      predicates.equalTo('member_id', memberId);

      const rowsAffected = await store.update(values, predicates);
      return rowsAffected > 0;
    } catch (error) {
      throw DAOHelper.toError('[LedgerMemberDAO] 更新最后活跃时间失败', error);
    }
  }

  /**
   * 更新贡献金额和账单数量
   */
  static async updateContribution(memberId: number, amount: number, billCount: number): Promise<boolean> {
    try {
      const store = DatabaseManager.getDatabase();

      const values: relationalStore.ValuesBucket = {
        contribution_amount: amount,
        bill_count: billCount,
        updated_at: new Date().toISOString()
      };

      const predicates = new relationalStore.RdbPredicates(LedgerMember.tableName);
      predicates.equalTo('member_id', memberId);

      const rowsAffected = await store.update(values, predicates);
      return rowsAffected > 0;
    } catch (error) {
      throw DAOHelper.toError('[LedgerMemberDAO] 更新贡献统计失败', error);
    }
  }

  /**
   * 移除成员（按成员ID）
   */
  static async remove(memberId: number): Promise<boolean> {
    try {
      await DAOHelper.softDelete(LedgerMember.tableName, 'member_id', memberId);
      return true;
    } catch (error) {
      throw DAOHelper.toError('[LedgerMemberDAO] 移除成员失败', error);
    }
  }

  /**
   * 软删除成员（按账本ID和用户ID）
   */
  static async softDelete(ledgerId: number, userId: number): Promise<boolean> {
    try {
      const store = DatabaseManager.getDatabase();
      const values: relationalStore.ValuesBucket = {
        is_deleted: 1,
        updated_at: new Date().toISOString()
      };

      const predicates = new relationalStore.RdbPredicates(LedgerMember.tableName);
      predicates.equalTo('ledger_id', ledgerId);
      predicates.equalTo('user_id', userId);

      const rowsAffected = await store.update(values, predicates);
      return rowsAffected > 0;
    } catch (error) {
      throw DAOHelper.toError('[LedgerMemberDAO] 软删除成员失败', error);
    }
  }

  /**
   * 更新成员角色
   */
  static async updateRole(
    ledgerId: number,
    userId: number,
    newRole: string
  ): Promise<boolean> {
    try {
      const store = DatabaseManager.getDatabase();
      const values: relationalStore.ValuesBucket = {
        role: newRole,
        updated_at: new Date().toISOString()
      };

      const predicates = new relationalStore.RdbPredicates(LedgerMember.tableName);
      predicates.equalTo('ledger_id', ledgerId);
      predicates.equalTo('user_id', userId);

      const rowsAffected = await store.update(values, predicates);
      return rowsAffected > 0;
    } catch (error) {
      throw DAOHelper.toError('[LedgerMemberDAO] 更新成员角色失败', error);
    }
  }

  /**
   * 映射数据库行到LedgerMember对象
   */
  private static mapRowToMember(resultSet: relationalStore.ResultSet): LedgerMember {
    const username = DAOHelper.getString(resultSet, 'username');
    return new LedgerMember(
      DAOHelper.getLong(resultSet, 'member_id'),
      DAOHelper.getLong(resultSet, 'ledger_id'),
      DAOHelper.getLong(resultSet, 'user_id'),
      username,
      username,  // userName 别名
      DAOHelper.getString(resultSet, 'email'),
      DAOHelper.getString(resultSet, 'avatar'),
      DAOHelper.getString(resultSet, 'role'),
      DAOHelper.getString(resultSet, 'permissions_json'),
      DAOHelper.getString(resultSet, 'nickname'),
      DAOHelper.getDouble(resultSet, 'contribution_amount'),
      DAOHelper.getLong(resultSet, 'bill_count'),
      DAOHelper.getString(resultSet, 'joined_at'),
      DAOHelper.getString(resultSet, 'last_active_at'),
      DAOHelper.getLong(resultSet, 'is_active'),
      DAOHelper.getString(resultSet, 'created_at'),
      DAOHelper.getString(resultSet, 'updated_at'),
      DAOHelper.getLong(resultSet, 'is_deleted')
    );
  }
}

/**
 * 账本邀请DAO
 */
export class LedgerInvitationDAO {
  /**
   * 根据ID获取邀请
   */
  static async getById(invitationId: number): Promise<LedgerInvitation | null> {
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const store = DatabaseManager.getDatabase();
      const predicates = new relationalStore.RdbPredicates(LedgerInvitation.tableName);
      predicates.equalTo('invitation_id', invitationId);
      predicates.equalTo('is_deleted', 0);

      resultSet = await store.query(predicates);

      if (resultSet.goToFirstRow()) {
        return LedgerInvitationDAO.mapRowToInvitation(resultSet);
      }
      return null;
    } catch (error) {
      throw DAOHelper.toError('[LedgerInvitationDAO] 根据ID获取邀请失败', error);
    } finally {
      DAOHelper.closeResultSet(resultSet);
    }
  }

  /**
   * 创建邀请
   */
  static async insert(invitation: LedgerInvitation): Promise<number> {
    try {
      const store = DatabaseManager.getDatabase();
      const now = new Date().toISOString();
      invitation.createdAt = now;
      invitation.updatedAt = now;

      const values: relationalStore.ValuesBucket = {
        ledger_id: invitation.ledgerId,
        ledger_name: invitation.ledgerName,
        inviter_id: invitation.inviterId,
        inviter_name: invitation.inviterName,
        invitee_email: invitation.inviteeEmail,
        invitee_user_id: invitation.inviteeUserId,
        role: invitation.role,
        message: invitation.message || null,
        status: invitation.status,
        invitation_code: invitation.invitationCode,
        expires_at: invitation.expiresAt,
        responded_at: invitation.respondedAt || null,
        created_at: invitation.createdAt,
        updated_at: invitation.updatedAt,
        is_deleted: invitation.isDeleted
      };

      const rowId = await store.insert(LedgerInvitation.tableName, values);
      return rowId;
    } catch (error) {
      throw DAOHelper.toError('[LedgerInvitationDAO] 创建邀请失败', error);
    }
  }

  /**
   * 更新邀请状态
   */
  static async updateStatus(invitationId: number, status: string): Promise<boolean> {
    try {
      const store = DatabaseManager.getDatabase();
      const now = new Date().toISOString();

      const values: relationalStore.ValuesBucket = {
        status: status,
        responded_at: now,
        updated_at: now
      };

      const predicates = new relationalStore.RdbPredicates(LedgerInvitation.tableName);
      predicates.equalTo('invitation_id', invitationId);

      const rowsAffected = await store.update(values, predicates);
      return rowsAffected > 0;
    } catch (error) {
      throw DAOHelper.toError('[LedgerInvitationDAO] 更新邀请状态失败', error);
    }
  }

  /**
   * 根据邀请码获取邀请
   */
  static async getByInvitationCode(code: string): Promise<LedgerInvitation | null> {
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const store = DatabaseManager.getDatabase();
      const predicates = new relationalStore.RdbPredicates(LedgerInvitation.tableName);
      predicates.equalTo('invitation_code', code);
      predicates.equalTo('is_deleted', 0);

      resultSet = await store.query(predicates);

      if (resultSet.goToFirstRow()) {
        return LedgerInvitationDAO.mapRowToInvitation(resultSet);
      }
      return null;
    } catch (error) {
      throw DAOHelper.toError('[LedgerInvitationDAO] 根据邀请码获取邀请失败', error);
    } finally {
      DAOHelper.closeResultSet(resultSet);
    }
  }

  /**
   * 获取用户的邀请
   */
  static async getByEmail(email: string): Promise<LedgerInvitation[]> {
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const store = DatabaseManager.getDatabase();
      const predicates = new relationalStore.RdbPredicates(LedgerInvitation.tableName);
      predicates.equalTo('invitee_email', email);
      predicates.equalTo('status', INVITATION_STATUS_PENDING);
      predicates.equalTo('is_deleted', 0);
      predicates.orderByDesc('created_at');

      resultSet = await store.query(predicates);

      const invitations: LedgerInvitation[] = [];
      while (resultSet.goToNextRow()) {
        invitations.push(LedgerInvitationDAO.mapRowToInvitation(resultSet));
      }
      return invitations;
    } catch (error) {
      throw DAOHelper.toError('[LedgerInvitationDAO] 获取用户邀请失败', error);
    } finally {
      DAOHelper.closeResultSet(resultSet);
    }
  }

  /**
   * 获取账本的所有邀请
   */
  static async getByLedgerId(ledgerId: number): Promise<LedgerInvitation[]> {
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const store = DatabaseManager.getDatabase();
      const predicates = new relationalStore.RdbPredicates(LedgerInvitation.tableName);
      predicates.equalTo('ledger_id', ledgerId);
      predicates.equalTo('is_deleted', 0);
      predicates.orderByDesc('created_at');

      resultSet = await store.query(predicates);

      const invitations: LedgerInvitation[] = [];
      while (resultSet.goToNextRow()) {
        invitations.push(LedgerInvitationDAO.mapRowToInvitation(resultSet));
      }
      return invitations;
    } catch (error) {
      throw DAOHelper.toError('[LedgerInvitationDAO] 获取账本邀请失败', error);
    } finally {
      DAOHelper.closeResultSet(resultSet);
    }
  }

  /**
   * 使过期的邀请失效
   */
  static async expireOldInvitations(): Promise<number> {
    try {
      const store = DatabaseManager.getDatabase();
      const now = new Date().toISOString();

      const values: relationalStore.ValuesBucket = {
        status: INVITATION_STATUS_EXPIRED,
        updated_at: now
      };

      const predicates = new relationalStore.RdbPredicates(LedgerInvitation.tableName);
      predicates.equalTo('status', INVITATION_STATUS_PENDING);
      predicates.lessThan('expires_at', now);
      predicates.equalTo('is_deleted', 0);

      const rowsAffected = await store.update(values, predicates);
      return rowsAffected;
    } catch (error) {
      throw DAOHelper.toError('[LedgerInvitationDAO] 使过期邀请失效失败', error);
    }
  }

  /**
   * 映射数据库行到LedgerInvitation对象
   */
  private static mapRowToInvitation(resultSet: relationalStore.ResultSet): LedgerInvitation {
    const inviteeUserId = DAOHelper.getLong(resultSet, 'invitee_user_id');
    const inviterName = DAOHelper.getString(resultSet, 'inviter_name');
    return new LedgerInvitation(
      DAOHelper.getLong(resultSet, 'invitation_id'),
      DAOHelper.getLong(resultSet, 'ledger_id'),
      DAOHelper.getString(resultSet, 'ledger_name'),
      DAOHelper.getLong(resultSet, 'inviter_id'),
      inviterName,
      DAOHelper.getString(resultSet, 'invitee_email'),
      inviteeUserId,
      inviteeUserId,  // inviteeId 别名
      inviterName,  // inviteeName 别名
      DAOHelper.getString(resultSet, 'role'),
      DAOHelper.getString(resultSet, 'message'),
      DAOHelper.getString(resultSet, 'status'),
      DAOHelper.getString(resultSet, 'invitation_code'),
      DAOHelper.getString(resultSet, 'expires_at'),
      DAOHelper.getString(resultSet, 'responded_at'),
      DAOHelper.getString(resultSet, 'created_at'),
      DAOHelper.getString(resultSet, 'updated_at'),
      DAOHelper.getLong(resultSet, 'is_deleted')
    );
  }
}

/**
 * 共享账单DAO
 */
export class SharedBillDAO {
  /**
   * 根据ID获取账单
   */
  static async getById(billId: number): Promise<SharedBill | null> {
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const store = DatabaseManager.getDatabase();
      const predicates = new relationalStore.RdbPredicates(SharedBill.tableName);
      predicates.equalTo('bill_id', billId);
      predicates.equalTo('is_deleted', 0);

      resultSet = await store.query(predicates);

      if (resultSet.goToFirstRow()) {
        return SharedBillDAO.mapRowToBill(resultSet);
      }
      return null;
    } catch (error) {
      throw DAOHelper.toError('[SharedBillDAO] 根据ID获取账单失败', error);
    } finally {
      DAOHelper.closeResultSet(resultSet);
    }
  }

  /**
   * 创建共享账单
   */
  static async insert(bill: SharedBill): Promise<number> {
    try {
      const store = DatabaseManager.getDatabase();
      const now = new Date().toISOString();
      bill.createdAt = now;
      bill.updatedAt = now;

      const values: relationalStore.ValuesBucket = {
        ledger_id: bill.ledgerId,
        creator_id: bill.creatorId,
        creator_name: bill.creatorName,
        account_id: bill.accountId,
        category_id: bill.categoryId,
        amount: bill.amount,
        note: bill.note || null,
        transaction_date: bill.transactionDate,
        type: bill.type,
        approval_status: bill.approvalStatus,
        approved_by: bill.approvedBy,
        approved_at: bill.approvedAt || null,
        sync_status: bill.syncStatus,
        last_synced_at: bill.lastSyncedAt || null,
        version: bill.version,
        split_type: bill.splitType,
        split_details_json: bill.splitDetailsJson,
        attachments_json: bill.attachmentsJson,
        tags_json: bill.tagsJson,
        location: bill.location || null,
        created_at: bill.createdAt,
        updated_at: bill.updatedAt,
        is_deleted: bill.isDeleted
      };

      const rowId = await store.insert(SharedBill.tableName, values);
      return rowId;
    } catch (error) {
      throw DAOHelper.toError('[SharedBillDAO] 创建共享账单失败', error);
    }
  }

  /**
   * 更新共享账单
   */
  static async update(bill: SharedBill): Promise<boolean> {
    try {
      const store = DatabaseManager.getDatabase();
      bill.updatedAt = new Date().toISOString();
      bill.version += 1;

      const values: relationalStore.ValuesBucket = {
        amount: bill.amount,
        note: bill.note || null,
        transaction_date: bill.transactionDate,
        approval_status: bill.approvalStatus,
        approved_by: bill.approvedBy,
        approved_at: bill.approvedAt || null,
        sync_status: bill.syncStatus,
        version: bill.version,
        split_type: bill.splitType,
        split_details_json: bill.splitDetailsJson,
        attachments_json: bill.attachmentsJson,
        tags_json: bill.tagsJson,
        location: bill.location || null,
        updated_at: bill.updatedAt
      };

      const predicates = new relationalStore.RdbPredicates(SharedBill.tableName);
      predicates.equalTo('bill_id', bill.billId);

      const rowsAffected = await store.update(values, predicates);
      return rowsAffected > 0;
    } catch (error) {
      throw DAOHelper.toError('[SharedBillDAO] 更新共享账单失败', error);
    }
  }

  /**
   * 获取账本的账单
   */
  static async getByLedgerId(ledgerId: number, limit: number = 100): Promise<SharedBill[]> {
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const store = DatabaseManager.getDatabase();
      const predicates = new relationalStore.RdbPredicates(SharedBill.tableName);
      predicates.equalTo('ledger_id', ledgerId);
      predicates.equalTo('is_deleted', 0);
      predicates.orderByDesc('transaction_date');

      resultSet = await store.query(predicates);

      const bills: SharedBill[] = [];
      let count = 0;
      while (resultSet.goToNextRow() && count < limit) {
        bills.push(SharedBillDAO.mapRowToBill(resultSet));
        count++;
      }
      return bills;
    } catch (error) {
      throw DAOHelper.toError('[SharedBillDAO] 获取账本账单失败', error);
    } finally {
      DAOHelper.closeResultSet(resultSet);
    }
  }

  /**
   * 获取待审批账单
   */
  static async getPendingApproval(ledgerId: number): Promise<SharedBill[]> {
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const store = DatabaseManager.getDatabase();
      const predicates = new relationalStore.RdbPredicates(SharedBill.tableName);
      predicates.equalTo('ledger_id', ledgerId);
      predicates.equalTo('approval_status', APPROVAL_STATUS_PENDING);
      predicates.equalTo('is_deleted', 0);
      predicates.orderByAsc('created_at');

      resultSet = await store.query(predicates);

      const bills: SharedBill[] = [];
      while (resultSet.goToNextRow()) {
        bills.push(SharedBillDAO.mapRowToBill(resultSet));
      }
      return bills;
    } catch (error) {
      throw DAOHelper.toError('[SharedBillDAO] 获取待审批账单失败', error);
    } finally {
      DAOHelper.closeResultSet(resultSet);
    }
  }

  /**
   * 更新账单状态
   */
  static async updateStatus(billId: number, status: string): Promise<boolean> {
    try {
      const store = DatabaseManager.getDatabase();
      const values: relationalStore.ValuesBucket = {
        approval_status: status,
        updated_at: new Date().toISOString()
      };

      const predicates = new relationalStore.RdbPredicates(SharedBill.tableName);
      predicates.equalTo('bill_id', billId);

      const rowsAffected = await store.update(values, predicates);
      return rowsAffected > 0;
    } catch (error) {
      throw DAOHelper.toError('[SharedBillDAO] 更新账单状态失败', error);
    }
  }

  /**
   * 根据状态获取账单列表
   */
  static async getByStatus(ledgerId: number, status: string): Promise<SharedBill[]> {
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const store = DatabaseManager.getDatabase();
      const predicates = new relationalStore.RdbPredicates(SharedBill.tableName);
      predicates.equalTo('ledger_id', ledgerId);
      predicates.equalTo('approval_status', status);
      predicates.equalTo('is_deleted', 0);
      predicates.orderByDesc('created_at');

      resultSet = await store.query(predicates);

      const bills: SharedBill[] = [];
      while (resultSet.goToNextRow()) {
        bills.push(SharedBillDAO.mapRowToBill(resultSet));
      }
      return bills;
    } catch (error) {
      throw DAOHelper.toError('[SharedBillDAO] 根据状态获取账单失败', error);
    } finally {
      DAOHelper.closeResultSet(resultSet);
    }
  }

  /**
   * 获取账单统计信息
   */
  static async getStatistics(ledgerId: number): Promise<SharedBillStatistics> {
    try {
      const store = DatabaseManager.getDatabase();
      const sql = `
        SELECT
          COUNT(*) as total_bills,
          SUM(CASE WHEN approval_status = 'approved' THEN amount ELSE 0 END) as total_approved_amount,
          SUM(CASE WHEN approval_status = 'pending' THEN 1 ELSE 0 END) as pending_count
        FROM ${SharedBill.tableName}
        WHERE ledger_id = ? AND is_deleted = 0
      `;
      const resultSet = await store.querySql(sql, [ledgerId]);

      const stats: SharedBillStatistics = {
        totalBills: 0,
        totalApprovedAmount: 0,
        pendingCount: 0
      };

      if (resultSet.goToFirstRow()) {
        stats.totalBills = DAOHelper.getLong(resultSet, 'total_bills');
        stats.totalApprovedAmount = DAOHelper.getDouble(resultSet, 'total_approved_amount');
        stats.pendingCount = DAOHelper.getLong(resultSet, 'pending_count');
      }
      resultSet.close();
      return stats;
    } catch (error) {
      throw DAOHelper.toError('[SharedBillDAO] 获取统计信息失败', error);
    }
  }

  /**
   * 软删除账单
   */
  static async softDelete(billId: number): Promise<boolean> {
    try {
      await DAOHelper.softDelete(SharedBill.tableName, 'bill_id', billId);
      return true;
    } catch (error) {
      throw DAOHelper.toError('[SharedBillDAO] 软删除账单失败', error);
    }
  }

  /**
   * 映射数据库行到SharedBill对象
   */
  private static mapRowToBill(resultSet: relationalStore.ResultSet): SharedBill {
    const note = DAOHelper.getString(resultSet, 'note');
    const splitType = DAOHelper.getString(resultSet, 'split_type');
    const splitDetailsJson = DAOHelper.getString(resultSet, 'split_details_json');
    const attachmentsJson = DAOHelper.getString(resultSet, 'attachments_json');
    const approvalStatus = DAOHelper.getString(resultSet, 'approval_status');

    return new SharedBill(
      DAOHelper.getLong(resultSet, 'bill_id'),
      DAOHelper.getLong(resultSet, 'ledger_id'),
      DAOHelper.getLong(resultSet, 'creator_id'),
      DAOHelper.getString(resultSet, 'creator_name'),
      DAOHelper.getLong(resultSet, 'account_id'),
      DAOHelper.getLong(resultSet, 'category_id'),
      '',  // categoryName - 不在数据库中
      DAOHelper.getDouble(resultSet, 'amount'),
      note,
      note,  // description 别名
      DAOHelper.getString(resultSet, 'transaction_date'),
      DAOHelper.getString(resultSet, 'type'),
      approvalStatus,
      DAOHelper.getLong(resultSet, 'approved_by'),
      DAOHelper.getString(resultSet, 'approved_at'),
      DAOHelper.getString(resultSet, 'sync_status'),
      DAOHelper.getString(resultSet, 'last_synced_at'),
      DAOHelper.getLong(resultSet, 'version'),
      splitType,
      splitType,  // splitMethod 别名
      splitDetailsJson,
      splitDetailsJson,  // splitsJson 别名
      attachmentsJson,
      attachmentsJson,  // attachments 别名
      DAOHelper.getString(resultSet, 'tags_json'),
      DAOHelper.getString(resultSet, 'location'),
      approvalStatus,  // status 别名
      DAOHelper.getString(resultSet, 'created_at'),
      DAOHelper.getString(resultSet, 'updated_at'),
      DAOHelper.getLong(resultSet, 'is_deleted')
    );
  }
}

/**
 * 审批记录DAO
 */
export class ApprovalRecordDAO {
  /**
   * 根据账单ID获取审批记录
   */
  static async getByBillId(billId: number): Promise<ApprovalRecord[]> {
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const store = DatabaseManager.getDatabase();
      const predicates = new relationalStore.RdbPredicates(ApprovalRecord.tableName);
      predicates.equalTo('bill_id', billId);
      predicates.equalTo('is_deleted', 0);
      predicates.orderByDesc('requested_at');

      resultSet = await store.query(predicates);

      const records: ApprovalRecord[] = [];
      while (resultSet.goToNextRow()) {
        records.push(ApprovalRecordDAO.mapRowToRecord(resultSet));
      }
      return records;
    } catch (error) {
      throw DAOHelper.toError('[ApprovalRecordDAO] 根据账单ID获取审批记录失败', error);
    } finally {
      DAOHelper.closeResultSet(resultSet);
    }
  }

  /**
   * 创建审批记录
   */
  static async insert(record: ApprovalRecord): Promise<number> {
    try {
      const store = DatabaseManager.getDatabase();
      const now = new Date().toISOString();
      record.requestedAt = now;
      record.createdAt = now;
      record.updatedAt = now;

      const values: relationalStore.ValuesBucket = {
        ledger_id: record.ledgerId,
        bill_id: record.billId,
        requester_id: record.requesterId,
        requester_name: record.requesterName,
        approver_id: record.approverId,
        approver_name: record.approverName || null,
        status: record.status,
        amount: record.amount,
        reason: record.reason || null,
        comment: record.comment || null,
        requested_at: record.requestedAt,
        processed_at: record.processedAt || null,
        created_at: record.createdAt,
        updated_at: record.updatedAt,
        is_deleted: record.isDeleted
      };

      const rowId = await store.insert(ApprovalRecord.tableName, values);
      return rowId;
    } catch (error) {
      throw DAOHelper.toError('[ApprovalRecordDAO] 创建审批记录失败', error);
    }
  }

  /**
   * 更新审批记录
   */
  static async updateStatus(
    approvalId: number,
    status: string,
    approverId: number,
    approverName: string,
    comment: string
  ): Promise<boolean> {
    try {
      const store = DatabaseManager.getDatabase();
      const now = new Date().toISOString();

      const values: relationalStore.ValuesBucket = {
        status: status,
        approver_id: approverId,
        approver_name: approverName,
        comment: comment,
        processed_at: now,
        updated_at: now
      };

      const predicates = new relationalStore.RdbPredicates(ApprovalRecord.tableName);
      predicates.equalTo('approval_id', approvalId);

      const rowsAffected = await store.update(values, predicates);
      return rowsAffected > 0;
    } catch (error) {
      throw DAOHelper.toError('[ApprovalRecordDAO] 更新审批记录失败', error);
    }
  }

  /**
   * 更新审批状态（简化版本）
   */
  static async updateApproval(
    billId: number,
    approverId: number,
    status: string,
    comments?: string
  ): Promise<boolean> {
    try {
      const store = DatabaseManager.getDatabase();
      const now = new Date().toISOString();

      const values: relationalStore.ValuesBucket = {
        status: status,
        comment: comments || '',
        processed_at: now,
        updated_at: now
      };

      const predicates = new relationalStore.RdbPredicates(ApprovalRecord.tableName);
      predicates.equalTo('bill_id', billId);
      predicates.equalTo('approver_id', approverId);
      predicates.equalTo('status', 'pending');

      const rowsAffected = await store.update(values, predicates);
      return rowsAffected > 0;
    } catch (error) {
      throw DAOHelper.toError('[ApprovalRecordDAO] 更新审批失败', error);
    }
  }

  /**
   * 获取账本的审批记录
   */
  static async getByLedgerId(ledgerId: number): Promise<ApprovalRecord[]> {
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const store = DatabaseManager.getDatabase();
      const predicates = new relationalStore.RdbPredicates(ApprovalRecord.tableName);
      predicates.equalTo('ledger_id', ledgerId);
      predicates.equalTo('is_deleted', 0);
      predicates.orderByDesc('requested_at');

      resultSet = await store.query(predicates);

      const records: ApprovalRecord[] = [];
      while (resultSet.goToNextRow()) {
        records.push(ApprovalRecordDAO.mapRowToRecord(resultSet));
      }
      return records;
    } catch (error) {
      throw DAOHelper.toError('[ApprovalRecordDAO] 获取审批记录失败', error);
    } finally {
      DAOHelper.closeResultSet(resultSet);
    }
  }

  /**
   * 映射数据库行到ApprovalRecord对象
   */
  private static mapRowToRecord(resultSet: relationalStore.ResultSet): ApprovalRecord {
    const approvalId = DAOHelper.getLong(resultSet, 'approval_id');
    const comment = DAOHelper.getString(resultSet, 'comment');
    const processedAt = DAOHelper.getString(resultSet, 'processed_at');

    return new ApprovalRecord(
      approvalId,
      approvalId,  // recordId 别名
      DAOHelper.getLong(resultSet, 'ledger_id'),
      DAOHelper.getLong(resultSet, 'bill_id'),
      DAOHelper.getLong(resultSet, 'requester_id'),
      DAOHelper.getString(resultSet, 'requester_name'),
      DAOHelper.getLong(resultSet, 'approver_id'),
      DAOHelper.getString(resultSet, 'approver_name'),
      DAOHelper.getString(resultSet, 'status'),
      DAOHelper.getDouble(resultSet, 'amount'),
      DAOHelper.getString(resultSet, 'reason'),
      comment,
      comment,  // comments 别名
      DAOHelper.getString(resultSet, 'requested_at'),
      processedAt,
      processedAt,  // approvedAt 别名
      DAOHelper.getString(resultSet, 'created_at'),
      DAOHelper.getString(resultSet, 'updated_at'),
      DAOHelper.getLong(resultSet, 'is_deleted')
    );
  }
}

/**
 * 成员活动记录DAO
 */
export class MemberActivityDAO {
  /**
   * 记录活动
   */
  static async insert(activity: MemberActivity): Promise<number> {
    try {
      const store = DatabaseManager.getDatabase();
      activity.createdAt = new Date().toISOString();

      const values: relationalStore.ValuesBucket = {
        ledger_id: activity.ledgerId,
        user_id: activity.userId,
        username: activity.username,
        action_type: activity.actionType,
        target_type: activity.targetType,
        target_id: activity.targetId,
        description: activity.description || null,
        metadata_json: activity.metadataJson,
        created_at: activity.createdAt
      };

      const rowId = await store.insert(MemberActivity.tableName, values);
      return rowId;
    } catch (error) {
      throw DAOHelper.toError('[MemberActivityDAO] 记录活动失败', error);
    }
  }

  /**
   * 获取账本的活动记录
   */
  static async getByLedgerId(ledgerId: number, limit: number = 50): Promise<MemberActivity[]> {
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const store = DatabaseManager.getDatabase();
      const predicates = new relationalStore.RdbPredicates(MemberActivity.tableName);
      predicates.equalTo('ledger_id', ledgerId);
      predicates.orderByDesc('created_at');

      resultSet = await store.query(predicates);

      const activities: MemberActivity[] = [];
      let count = 0;
      while (resultSet.goToNextRow() && count < limit) {
        activities.push(MemberActivityDAO.mapRowToActivity(resultSet));
        count++;
      }
      return activities;
    } catch (error) {
      throw DAOHelper.toError('[MemberActivityDAO] 获取活动记录失败', error);
    } finally {
      DAOHelper.closeResultSet(resultSet);
    }
  }

  /**
   * 映射数据库行到MemberActivity对象
   */
  private static mapRowToActivity(resultSet: relationalStore.ResultSet): MemberActivity {
    const username = DAOHelper.getString(resultSet, 'username');
    const actionType = DAOHelper.getString(resultSet, 'action_type');
    const createdAt = DAOHelper.getString(resultSet, 'created_at');

    return new MemberActivity(
      DAOHelper.getLong(resultSet, 'activity_id'),
      DAOHelper.getLong(resultSet, 'ledger_id'),
      DAOHelper.getLong(resultSet, 'user_id'),
      username,
      username,  // userName 别名
      actionType,
      actionType,  // activityType 别名
      DAOHelper.getString(resultSet, 'target_type'),
      DAOHelper.getLong(resultSet, 'target_id'),
      DAOHelper.getString(resultSet, 'description'),
      DAOHelper.getString(resultSet, 'metadata_json'),
      createdAt,  // occurredAt
      createdAt
    );
  }
}
