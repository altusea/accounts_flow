import 'package:flutter/material.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../services/data_service.dart';
import '../widgets/balance_chart.dart';
import '../widgets/add_transaction_dialog.dart';

class AccountDetailScreen extends StatefulWidget {
  final Account account;

  const AccountDetailScreen({super.key, required this.account});

  @override
  State<AccountDetailScreen> createState() => _AccountDetailScreenState();
}

class _AccountDetailScreenState extends State<AccountDetailScreen> {
  List<Transaction> _transactions = [];
  List<Account> _allAccounts = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final transactions = await DataService.getTransactionsByAccount(widget.account.id);
    final accounts = await DataService.getAccounts();

    setState(() {
      _transactions = transactions;
      _allAccounts = accounts;
    });
  }

  void _showAddTransactionDialog() {
    showDialog(
      context: context,
      builder: (context) => AddTransactionDialog(
        accounts: _allAccounts,
        onTransactionAdded: (transaction) async {
          await DataService.addTransaction(transaction);
          _loadData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.account.name),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTransactionDialog,
        child: Icon(Icons.add),
        tooltip: '添加交易',
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 账户信息卡片
          Card(
            margin: EdgeInsets.all(16),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: widget.account.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Icon(
                      widget.account.typeIcon,
                      color: widget.account.color,
                      size: 30,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.account.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          widget.account.typeName,
                          style: TextStyle(color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '¥${widget.account.balance.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: widget.account.balance >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 余额变化图表
          Card(
            margin: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    '余额变化',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                BalanceChart(accountId: widget.account.id),
              ],
            ),
          ),

          // 交易记录
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '交易记录',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          if (_transactions.isEmpty) ...[
            Container(
              height: 100,
              child: Center(
                child: Text(
                  '暂无交易记录',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ] else ...[
            ..._transactions.map((transaction) {
              Account? targetAccount;
              if (transaction.type == TransactionType.transfer &&
                  transaction.targetAccountId != null) {
                targetAccount = _allAccounts.firstWhere(
                  (acc) => acc.id == transaction.targetAccountId,
                  orElse: () => Account(
                    id: '',
                    name: '未知账户',
                    type: AccountType.bankCard,
                    balance: 0,
                    color: Colors.grey,
                    createdAt: DateTime.now(),
                  ),
                );
              }

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: transaction.typeColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      _getTransactionIcon(transaction),
                      color: transaction.typeColor,
                      size: 20,
                    ),
                  ),
                  title: Text(transaction.description),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${transaction.formattedDate} ${transaction.formattedTime}',
                        style: TextStyle(color: Colors.grey),
                      ),
                      if (transaction.type == TransactionType.transfer &&
                          targetAccount != null)
                        Text(
                          '转账到 ${targetAccount.name}',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                    ],
                  ),
                  trailing: Text(
                    transaction.formattedAmount,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: transaction.typeColor,
                    ),
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  IconData _getTransactionIcon(Transaction transaction) {
    switch (transaction.type) {
      case TransactionType.income:
        return Icons.arrow_downward;
      case TransactionType.expense:
        return Icons.arrow_upward;
      case TransactionType.transfer:
        return Icons.swap_horiz;
    }
  }
}