import 'package:flutter/material.dart';
import '../models/account.dart';
import '../services/data_service.dart';
import '../widgets/account_card.dart';
import '../widgets/add_account_dialog.dart';
import 'account_detail_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  List<Account> _accounts = [];
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

    setState(() {
      _accounts = accounts;
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

    return FloatingActionButton(
      heroTag: 'add_account',
      onPressed: _showAddAccountDialog,
      child: Icon(Icons.account_balance_wallet),
      tooltip: '添加账户',
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
                    '${_totalBalance.toStringAsFixed(2)}元',
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

        ],
      ),
    );
  }
}