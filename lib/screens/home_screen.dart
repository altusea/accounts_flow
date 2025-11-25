import 'package:flutter/material.dart';
import '../models/account.dart';
import '../services/data_service.dart';
import '../utils/logger.dart';
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
    AppLogger.ui('HomeScreen 初始化');
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadData();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      final tabNames = ['概览', '历史'];
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
      final accounts = await DataService.getAccounts();

      setState(() {
        _accounts = accounts;
      });
      AppLogger.ui('成功加载 ${accounts.length} 个账户');
    } catch (e, stackTrace) {
      AppLogger.error('加载账户数据失败', e, stackTrace);
      rethrow;
    }
  }

  double get _totalBalance {
    return _accounts.fold(0.0, (sum, account) => sum + account.balance);
  }

  void _showAddAccountDialog() {
    AppLogger.ui('打开添加账户对话框');
    showDialog(
      context: context,
      builder: (context) => AddAccountDialog(
        onAccountAdded: (account) async {
          AppLogger.ui('开始添加账户: ${account.name}');
          try {
            await DataService.addAccount(account);
            AppLogger.ui('成功添加账户: ${account.name}');
            _loadData();
          } catch (e, stackTrace) {
            AppLogger.error('添加账户失败: ${account.name}', e, stackTrace);
            rethrow;
          }
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