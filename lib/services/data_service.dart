import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../models/balance_history.dart';

class DataService {
  static const String _accountsKey = 'accounts';
  static const String _transactionsKey = 'transactions';
  static const String _balanceHistoryKey = 'balanceHistory';

  static Future<List<Account>> getAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final accountsJson = prefs.getStringList(_accountsKey) ?? [];
    return accountsJson
        .map((json) => Account.fromJson(jsonDecode(json)))
        .toList();
  }

  static Future<void> saveAccounts(List<Account> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    final accountsJson = accounts.map((account) => account.toJson()).toList();
    await prefs.setStringList(
        _accountsKey, accountsJson.map((json) => jsonEncode(json)).toList());
  }

  static Future<List<Transaction>> getTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final transactionsJson = prefs.getStringList(_transactionsKey) ?? [];
    return transactionsJson
        .map((json) => Transaction.fromJson(jsonDecode(json)))
        .toList();
  }

  static Future<void> saveTransactions(List<Transaction> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    final transactionsJson = transactions.map((transaction) => transaction.toJson()).toList();
    await prefs.setStringList(
        _transactionsKey, transactionsJson.map((json) => jsonEncode(json)).toList());
  }

  static Future<void> addAccount(Account account) async {
    final accounts = await getAccounts();
    accounts.add(account);
    await saveAccounts(accounts);
  }

  static Future<void> updateAccount(Account updatedAccount) async {
    final accounts = await getAccounts();
    final index = accounts.indexWhere((account) => account.id == updatedAccount.id);
    if (index != -1) {
      accounts[index] = updatedAccount;
      await saveAccounts(accounts);
    }
  }

  static Future<void> deleteAccount(String accountId) async {
    final accounts = await getAccounts();
    accounts.removeWhere((account) => account.id == accountId);
    await saveAccounts(accounts);
  }

  static Future<void> addTransaction(Transaction transaction) async {
    final transactions = await getTransactions();
    transactions.add(transaction);
    await saveTransactions(transactions);
  }

  static Future<void> deleteTransaction(String transactionId) async {
    final transactions = await getTransactions();
    transactions.removeWhere((transaction) => transaction.id == transactionId);
    await saveTransactions(transactions);
  }

  static Future<List<Transaction>> getTransactionsByAccount(String accountId) async {
    final transactions = await getTransactions();
    return transactions
        .where((transaction) =>
            transaction.accountId == accountId ||
            transaction.targetAccountId == accountId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static Future<double> getAccountBalance(String accountId) async {
    final transactions = await getTransactionsByAccount(accountId);
    double balance = 0.0;

    for (final transaction in transactions) {
      if (transaction.accountId == accountId) {
        // 这是从该账户发起的交易
        if (transaction.type == TransactionType.income) {
          balance += transaction.amount;
        } else if (transaction.type == TransactionType.expense) {
          balance -= transaction.amount;
        } else if (transaction.type == TransactionType.transfer) {
          balance -= transaction.amount;
        }
      } else if (transaction.targetAccountId == accountId) {
        // 这是转入该账户的交易
        if (transaction.type == TransactionType.transfer) {
          balance += transaction.amount;
        }
      }
    }

    return balance;
  }

  // 历史余额相关方法
  static Future<List<BalanceHistory>> getBalanceHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList(_balanceHistoryKey) ?? [];
    return historyJson
        .map((json) => BalanceHistory.fromJson(jsonDecode(json)))
        .toList();
  }

  static Future<void> saveBalanceHistory(List<BalanceHistory> history) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = history.map((item) => item.toJson()).toList();
    await prefs.setStringList(
        _balanceHistoryKey, historyJson.map((json) => jsonEncode(json)).toList());
  }

  static Future<void> addBalanceHistory(BalanceHistory history) async {
    final historyList = await getBalanceHistory();
    historyList.add(history);
    await saveBalanceHistory(historyList);
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
      final currentBalance = await getAccountBalance(account.id);
      final history = BalanceHistory(
        id: '${account.id}_${today.millisecondsSinceEpoch}',
        accountId: account.id,
        balance: currentBalance,
        recordDate: today,
        createdAt: today,
      );
      await addBalanceHistory(history);
    }
  }

  static Future<List<BalanceHistory>> getBalanceHistoryByAccount(String accountId) async {
    final history = await getBalanceHistory();
    return history
        .where((item) => item.accountId == accountId)
        .toList()
      ..sort((a, b) => a.recordDate.compareTo(b.recordDate));
  }

  static Future<List<DateTime>> getRecordedDates() async {
    final history = await getBalanceHistory();
    final dates = history.map((item) =>
        DateTime(item.recordDate.year, item.recordDate.month, item.recordDate.day))
        .toSet()
        .toList();
    dates.sort((a, b) => b.compareTo(a));
    return dates;
  }

  static Future<Map<String, double>> getBalancesByDate(DateTime date) async {
    final history = await getBalanceHistory();
    final accounts = await getAccounts();
    final balances = <String, double>{};

    for (final account in accounts) {
      final accountHistory = history
          .where((item) =>
              item.accountId == account.id &&
              item.recordDate.year == date.year &&
              item.recordDate.month == date.month &&
              item.recordDate.day == date.day)
          .toList();

      if (accountHistory.isNotEmpty) {
        balances[account.id] = accountHistory.first.balance;
      }
    }

    return balances;
  }
}