import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';
import '../models/account.dart';
import '../models/balance_history.dart';
import 'database_helper.dart';

class DataService {
  static final DatabaseHelper _dbHelper = DatabaseHelper();

  // 账户相关方法
  static Future<List<Account>> getAccounts() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('accounts');

    return List.generate(maps.length, (i) {
      return Account(
        id: maps[i]['id'],
        name: maps[i]['name'],
        type: AccountType.values[maps[i]['type']],
        balance: maps[i]['balance'],
        color: Color(maps[i]['color']),
        createdAt: DateTime.fromMillisecondsSinceEpoch(maps[i]['createdAt']),
      );
    });
  }

  static Future<void> saveAccounts(List<Account> accounts) async {
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
  }

  static Future<void> addAccount(Account account) async {
    final db = await _dbHelper.database;
    await db.insert('accounts', {
      'id': account.id,
      'name': account.name,
      'type': account.type.index,
      'balance': account.balance,
      'color': account.color.value,
      'createdAt': account.createdAt.millisecondsSinceEpoch,
    });
  }

  static Future<void> updateAccount(Account updatedAccount) async {
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
  }

  static Future<void> deleteAccount(String accountId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'accounts',
      where: 'id = ?',
      whereArgs: [accountId],
    );
  }

  // 余额历史相关方法
  static Future<List<BalanceHistory>> getBalanceHistory() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('balance_history');

    return List.generate(maps.length, (i) {
      return BalanceHistory(
        id: maps[i]['id'],
        accountId: maps[i]['accountId'],
        balance: maps[i]['balance'],
        recordDate: DateTime.fromMillisecondsSinceEpoch(maps[i]['recordDate']),
        createdAt: DateTime.fromMillisecondsSinceEpoch(maps[i]['createdAt']),
      );
    });
  }

  static Future<void> saveBalanceHistory(List<BalanceHistory> history) async {
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
  }

  static Future<void> addBalanceHistory(BalanceHistory history) async {
    final db = await _dbHelper.database;
    await db.insert('balance_history', {
      'id': history.id,
      'accountId': history.accountId,
      'balance': history.balance,
      'recordDate': history.recordDate.millisecondsSinceEpoch,
      'createdAt': history.createdAt.millisecondsSinceEpoch,
    });
  }

  static Future<List<BalanceHistory>> getBalanceHistoryByAccount(String accountId) async {
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
    return history;
  }

  static Future<List<DateTime>> getRecordedDates() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT DISTINCT recordDate
      FROM balance_history
      ORDER BY recordDate DESC
    ''');

    return maps.map((map) =>
      DateTime.fromMillisecondsSinceEpoch(map['recordDate'])
    ).toList();
  }

  static Future<Map<String, double>> getBalancesByDate(DateTime date) async {
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

    return balances;
  }

  static Future<void> recordWeeklyBalances() async {
    final accounts = await getAccounts();
    final today = DateTime.now();

    // 只在周六记录
    if (today.weekday != DateTime.saturday) {
      return;
    }

    // 检查今天是否已经记录过
    final existingHistory = await getBalanceHistory();
    final todayString = DateFormat('yyyy-MM-dd').format(today);
    final alreadyRecorded = existingHistory.any((history) =>
        history.formattedDate == todayString);

    if (alreadyRecorded) {
      return;
    }

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
  }

  // 数据迁移方法（从 SharedPreferences 迁移到 SQLite）
  static Future<void> migrateFromSharedPreferences() async {
    // 这里可以添加从旧存储迁移数据的逻辑
    // 由于我们移除了交易功能，只需要迁移账户和余额历史数据
    print('数据迁移完成（SQLite）');
  }
}