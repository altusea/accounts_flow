import 'package:flutter/material.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../services/data_service.dart';
import '../widgets/account_card.dart';
import '../widgets/add_account_dialog.dart';
import '../widgets/add_transaction_dialog.dart';
import 'account_detail_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  List<Account> _accounts = [];
  List<Transaction> _recentTransactions = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final accounts = await DataService.getAccounts();
    final transactions = await DataService.getTransactions();

    // 获取最新的5笔交易
    transactions.sort((a, b) => b.date.compareTo(a.date));
    final recent = transactions.take(5).toList();

    setState(() {
      _accounts = accounts;
      _recentTransactions = recent;
    });
  }

  double get _totalBalance {
    return _accounts.fold(0.0, (sum, account) => sum + account.balance);
  }

  void _showAddAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AddAccountDialog(
        onAccountAdded: (account) async {
          await DataService.addAccount(account);
          _loadData();
        },
      ),
    );
  }

  void _showAddTransactionDialog() {
    if (_accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('请先添加账户')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AddTransactionDialog(
        accounts: _accounts,
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
        title: Text('记账应用'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.dashboard), text: '概览'),
            Tab(icon: Icon(Icons.history), text: '历史'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          HistoryScreen(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildFloatingActionButton() {
    // 只在概览tab显示FAB
    if (_tabController.index != 0) {
      return Container();
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton.small(
          heroTag: 'add_transaction',
          onPressed: _showAddTransactionDialog,
          child: Icon(Icons.add),
          tooltip: '添加交易',
        ),
        SizedBox(height: 8),
        FloatingActionButton(
          heroTag: 'add_account',
          onPressed: _showAddAccountDialog,
          child: Icon(Icons.account_balance_wallet),
          tooltip: '添加账户',
        ),
      ],
    );
  }

  Widget _buildOverviewTab() {
    if (_accounts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              '暂无账户',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              '点击右下角按钮添加第一个账户',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 总余额卡片
          Card(
            margin: EdgeInsets.all(16),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '总余额',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '¥${_totalBalance.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: _totalBalance >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 账户列表
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '我的账户',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ..._accounts.map((account) => AccountCard(
                account: account,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AccountDetailScreen(account: account),
                  ),
                ),
              )),

          // 最近交易
          if (_recentTransactions.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                '最近交易',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ..._recentTransactions.map((transaction) {
              final account = _accounts.firstWhere(
                (acc) => acc.id == transaction.accountId,
                orElse: () => Account(
                  id: '',
                  name: '未知账户',
                  type: AccountType.bankCard,
                  balance: 0,
                  color: Colors.grey,
                  createdAt: DateTime.now(),
                ),
              );

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: account.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      account.typeIcon,
                      color: account.color,
                      size: 20,
                    ),
                  ),
                  title: Text(transaction.description),
                  subtitle: Text(
                    '${transaction.formattedDate} ${transaction.typeName}',
                    style: TextStyle(color: Colors.grey),
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
}