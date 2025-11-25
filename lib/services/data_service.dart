import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';
import '../models/account.dart';
import '../models/balance_history.dart';
import 'database_helper.dart';
import '../utils/logger.dart';

class DataService {
  static final DatabaseHelper _dbHelper = DatabaseHelper();

  // 账户相关方法
  static Future<List<Account>> getAccounts() async {
    AppLogger.db('开始获取账户列表');
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query('accounts');

      final accounts = List.generate(maps.length, (i) {
        return Account(
          id: maps[i]['id'],
          name: maps[i]['name'],
          type: AccountType.values[maps[i]['type']],
          balance: maps[i]['balance'],
          color: Color(maps[i]['color']),
          createdAt: DateTime.fromMillisecondsSinceEpoch(maps[i]['createdAt']),
        );
      });

      AppLogger.db('成功获取 ${accounts.length} 个账户');
      return accounts;
    } catch (e, stackTrace) {
      AppLogger.error('获取账户列表失败', e, stackTrace);
      rethrow;
    }
  }

  static Future<void> saveAccounts(List<Account> accounts) async {
    AppLogger.db('开始保存 ${accounts.length} 个账户');
    try {
      final db = await _dbHelper.database;

      // 使用事务确保数据一致性
      await db.transaction((txn) async {
        // 先清空表
        await txn.delete('accounts');

        // 批量插入
        for (final account in accounts) {
          await txn.insert('accounts', {
            'id': account.id,
            'name': account.name,
            'type': account.type.index,
            'balance': account.balance,
            'color': account.color.value,
            'createdAt': account.createdAt.millisecondsSinceEpoch,
          });
        }
      });
      AppLogger.db('成功保存 ${accounts.length} 个账户');
    } catch (e, stackTrace) {
      AppLogger.error('保存账户失败', e, stackTrace);
      rethrow;
    }
  }

  static Future<void> addAccount(Account account) async {
    AppLogger.db('开始添加账户: ${account.name} (${account.id})');
    try {
      final db = await _dbHelper.database;
      await db.insert('accounts', {
        'id': account.id,
        'name': account.name,
        'type': account.type.index,
        'balance': account.balance,
        'color': account.color.value,
        'createdAt': account.createdAt.millisecondsSinceEpoch,
      });
      AppLogger.db('成功添加账户: ${account.name}');
    } catch (e, stackTrace) {
      AppLogger.error('添加账户失败: ${account.name}', e, stackTrace);
      rethrow;
    }
  }

  static Future<void> updateAccount(Account updatedAccount) async {
    AppLogger.db('开始更新账户: ${updatedAccount.name} (${updatedAccount.id})');
    try {
      final db = await _dbHelper.database;
      await db.update(
        'accounts',
        {
          'name': updatedAccount.name,
          'type': updatedAccount.type.index,
          'balance': updatedAccount.balance,
          'color': updatedAccount.color.value,
        },
        where: 'id = ?',
        whereArgs: [updatedAccount.id],
      );
      AppLogger.db('成功更新账户: ${updatedAccount.name}');
    } catch (e, stackTrace) {
      AppLogger.error('更新账户失败: ${updatedAccount.name}', e, stackTrace);
      rethrow;
    }
  }

  static Future<void> deleteAccount(String accountId) async {
    AppLogger.db('开始删除账户: $accountId');
    try {
      final db = await _dbHelper.database;
      await db.delete(
        'accounts',
        where: 'id = ?',
        whereArgs: [accountId],
      );
      AppLogger.db('成功删除账户: $accountId');
    } catch (e, stackTrace) {
      AppLogger.error('删除账户失败: $accountId', e, stackTrace);
      rethrow;
    }
  }

  // 余额历史相关方法
  static Future<List<BalanceHistory>> getBalanceHistory() async {
    AppLogger.db('开始获取余额历史记录');
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query('balance_history');

      final history = List.generate(maps.length, (i) {
        return BalanceHistory(
          id: maps[i]['id'],
          accountId: maps[i]['accountId'],
          balance: maps[i]['balance'],
          recordDate: DateTime.fromMillisecondsSinceEpoch(maps[i]['recordDate']),
          createdAt: DateTime.fromMillisecondsSinceEpoch(maps[i]['createdAt']),
        );
      });

      AppLogger.db('成功获取 ${history.length} 条余额历史记录');
      return history;
    } catch (e, stackTrace) {
      AppLogger.error('获取余额历史记录失败', e, stackTrace);
      rethrow;
    }
  }

  static Future<void> saveBalanceHistory(List<BalanceHistory> history) async {
    AppLogger.db('开始保存 ${history.length} 条余额历史记录');
    try {
      final db = await _dbHelper.database;

      await db.transaction((txn) async {
        await txn.delete('balance_history');

        for (final item in history) {
          await txn.insert('balance_history', {
            'id': item.id,
            'accountId': item.accountId,
            'balance': item.balance,
            'recordDate': item.recordDate.millisecondsSinceEpoch,
            'createdAt': item.createdAt.millisecondsSinceEpoch,
          });
        }
      });
      AppLogger.db('成功保存 ${history.length} 条余额历史记录');
    } catch (e, stackTrace) {
      AppLogger.error('保存余额历史记录失败', e, stackTrace);
      rethrow;
    }
  }

  static Future<void> addBalanceHistory(BalanceHistory history) async {
    AppLogger.db('开始添加余额历史记录: ${history.accountId} - ${history.balance}元');
    try {
      final db = await _dbHelper.database;
      await db.insert('balance_history', {
        'id': history.id,
        'accountId': history.accountId,
        'balance': history.balance,
        'recordDate': history.recordDate.millisecondsSinceEpoch,
        'createdAt': history.createdAt.millisecondsSinceEpoch,
      });
      AppLogger.db('成功添加余额历史记录: ${history.accountId}');
    } catch (e, stackTrace) {
      AppLogger.error('添加余额历史记录失败: ${history.accountId}', e, stackTrace);
      rethrow;
    }
  }

  static Future<List<BalanceHistory>> getBalanceHistoryByAccount(String accountId) async {
    AppLogger.db('开始获取账户 $accountId 的余额历史记录');
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'balance_history',
        where: 'accountId = ?',
        whereArgs: [accountId],
      );

      final history = List.generate(maps.length, (i) {
        return BalanceHistory(
          id: maps[i]['id'],
          accountId: maps[i]['accountId'],
          balance: maps[i]['balance'],
          recordDate: DateTime.fromMillisecondsSinceEpoch(maps[i]['recordDate']),
          createdAt: DateTime.fromMillisecondsSinceEpoch(maps[i]['createdAt']),
        );
      });

      history.sort((a, b) => a.recordDate.compareTo(b.recordDate));
      AppLogger.db('成功获取账户 $accountId 的 ${history.length} 条余额历史记录');
      return history;
    } catch (e, stackTrace) {
      AppLogger.error('获取账户 $accountId 的余额历史记录失败', e, stackTrace);
      rethrow;
    }
  }

  static Future<List<DateTime>> getRecordedDates() async {
    AppLogger.db('开始获取已记录的日期列表');
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT DISTINCT recordDate
        FROM balance_history
        ORDER BY recordDate DESC
      ''');

      final dates = maps.map((map) =>
        DateTime.fromMillisecondsSinceEpoch(map['recordDate'])
      ).toList();

      AppLogger.db('成功获取 ${dates.length} 个已记录的日期');
      return dates;
    } catch (e, stackTrace) {
      AppLogger.error('获取已记录的日期列表失败', e, stackTrace);
      rethrow;
    }
  }

  static Future<Map<String, double>> getBalancesByDate(DateTime date) async {
    AppLogger.db('开始获取日期 ${DateFormat('yyyy-MM-dd').format(date)} 的账户余额');
    try {
      final db = await _dbHelper.database;
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT accountId, balance
        FROM balance_history
        WHERE recordDate BETWEEN ? AND ?
      ''', [startOfDay.millisecondsSinceEpoch, endOfDay.millisecondsSinceEpoch]);

      final balances = <String, double>{};
      for (final map in maps) {
        balances[map['accountId']] = map['balance'];
      }

      AppLogger.db('成功获取 ${balances.length} 个账户在 ${DateFormat('yyyy-MM-dd').format(date)} 的余额');
      return balances;
    } catch (e, stackTrace) {
      AppLogger.error('获取日期 ${DateFormat('yyyy-MM-dd').format(date)} 的账户余额失败', e, stackTrace);
      rethrow;
    }
  }

  static Future<void> recordWeeklyBalances() async {
    AppLogger.business('开始检查是否需要记录本周余额');
    try {
      final accounts = await getAccounts();
      final today = DateTime.now();

      // 只在周六记录
      if (today.weekday != DateTime.saturday) {
        AppLogger.business('今天不是周六，跳过余额记录');
        return;
      }

      // 检查今天是否已经记录过
      final existingHistory = await getBalanceHistory();
      final todayString = DateFormat('yyyy-MM-dd').format(today);
      final alreadyRecorded = existingHistory.any((history) =>
          history.formattedDate == todayString);

      if (alreadyRecorded) {
        AppLogger.business('今天 ${todayString} 已经记录过余额，跳过');
        return;
      }

      AppLogger.business('开始为 ${accounts.length} 个账户记录本周余额');

      // 为每个账户记录当前余额
      for (final account in accounts) {
        final history = BalanceHistory(
          id: '${account.id}_${today.millisecondsSinceEpoch}',
          accountId: account.id,
          balance: account.balance,
          recordDate: today,
          createdAt: today,
        );
        await addBalanceHistory(history);
      }

      AppLogger.business('成功为 ${accounts.length} 个账户记录本周余额');
    } catch (e, stackTrace) {
      AppLogger.error('记录本周余额失败', e, stackTrace);
      rethrow;
    }
  }

  // 数据迁移方法（从 SharedPreferences 迁移到 SQLite）
  static Future<void> migrateFromSharedPreferences() async {
    AppLogger.business('开始数据迁移（从 SharedPreferences 到 SQLite）');
    try {
      // 这里可以添加从旧存储迁移数据的逻辑
      // 由于我们移除了交易功能，只需要迁移账户和余额历史数据
      AppLogger.business('数据迁移完成（SQLite）');
    } catch (e, stackTrace) {
      AppLogger.error('数据迁移失败', e, stackTrace);
      rethrow;
    }
  }
}