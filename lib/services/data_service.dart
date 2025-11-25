import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/account.dart';
import '../models/transaction.dart';

class DataService {
  static const String _accountsKey = 'accounts';
  static const String _transactionsKey = 'transactions';

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
}