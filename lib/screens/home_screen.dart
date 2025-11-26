import 'package:flutter/material.dart';
import '../models/account.dart';
import '../services/data_service.dart';
import '../utils/logger.dart';
import '../widgets/account_card.dart';
import 'account_detail_screen.dart';
import 'history_table_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  List<Account> _accounts = [];
  Map<String, double> _accountBalances = {}; // accountId -> latest balance
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    AppLogger.ui('HomeScreen 初始化');
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadData();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      final tabNames = ['概览', '表格', '设置'];
      AppLogger.ui('切换到 ${tabNames[_tabController.index]} 标签页');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    AppLogger.ui('开始加载账户数据');
    try {
      final accounts = await DataService.getOrderedAccounts();
      final balances = <String, double>{};

      // 为每个账户获取最新余额
      for (final account in accounts) {
        final latestBalance = await DataService.getLatestBalanceForAccount(account.id);
        balances[account.id] = latestBalance;
      }

      setState(() {
        _accounts = accounts;
        _accountBalances = balances;
      });
      AppLogger.ui('成功加载 ${accounts.length} 个账户');
    } catch (e, stackTrace) {
      AppLogger.error('加载账户数据失败', e, stackTrace);
      rethrow;
    }
  }

  double get _totalBalance {
    return _accounts.fold(0.0, (sum, account) => sum + (_accountBalances[account.id] ?? 0.0));
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
            Tab(icon: Icon(Icons.table_chart), text: '表格'),
            Tab(icon: Icon(Icons.settings), text: '设置'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              AppLogger.ui('手动刷新账户数据');
              _loadData();
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          HistoryTableScreen(),
          SettingsScreen(),
        ],
      ),
      floatingActionButton: Container(),
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
              '请到设置页面添加第一个账户',
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
                balance: _accountBalances[account.id] ?? 0.0,
                onTap: () {
                  AppLogger.ui('导航到账户详情: ${account.name}');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AccountDetailScreen(account: account),
                    ),
                  );
                },
              )),

        ],
      ),
    );
  }
}