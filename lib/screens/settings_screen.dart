import 'package:flutter/material.dart';
import '../models/account.dart';
import '../services/data_service.dart';
import '../utils/logger.dart';
import '../widgets/add_account_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<Account> _accounts = [];
  List<String> _accountOrder = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    AppLogger.ui('SettingsScreen 初始化');
    _loadData();
  }

  Future<void> _loadData() async {
    AppLogger.ui('开始加载设置数据');
    setState(() {
      _isLoading = true;
    });

    try {
      final accounts = await DataService.getAccounts();

      // 从存储中获取账户顺序，如果没有则使用默认顺序
      final storedOrder = await _getStoredAccountOrder();
      final accountOrder = storedOrder.isNotEmpty
          ? storedOrder
          : accounts.map((account) => account.id).toList();

      setState(() {
        _accounts = accounts;
        _accountOrder = accountOrder;
        _isLoading = false;
      });

      AppLogger.ui('成功加载设置数据: ${accounts.length} 个账户');
    } catch (e, stackTrace) {
      AppLogger.error('加载设置数据失败', e, stackTrace);
      rethrow;
    }
  }

  Future<List<String>> _getStoredAccountOrder() async {
    // 这里可以从 SharedPreferences 或其他存储中获取账户顺序
    // 暂时返回空列表，表示使用默认顺序
    return [];
  }

  Future<void> _saveAccountOrder(List<String> order) async {
    AppLogger.ui('保存账户顺序: ${order.length} 个账户');
    try {
      // 这里可以将账户顺序保存到 SharedPreferences 或其他存储中
      // 暂时只更新内存中的顺序
      setState(() {
        _accountOrder = order;
      });
      AppLogger.ui('成功保存账户顺序');
    } catch (e, stackTrace) {
      AppLogger.error('保存账户顺序失败', e, stackTrace);
      rethrow;
    }
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

            // 将新账户添加到顺序列表的末尾
            setState(() {
              _accountOrder.add(account.id);
            });

            await _loadData();

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('账户 ${account.name} 已添加')),
              );
            }
          } catch (e, stackTrace) {
            AppLogger.error('添加账户失败: ${account.name}', e, stackTrace);
            rethrow;
          }
        },
      ),
    );
  }

  void _reorderAccount(int oldIndex, int newIndex) {
    AppLogger.ui('重新排序账户: $oldIndex -> $newIndex');

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final accountId = _accountOrder.removeAt(oldIndex);
    _accountOrder.insert(newIndex, accountId);

    _saveAccountOrder(_accountOrder);
  }

  Future<void> _deleteAccount(Account account) async {
    AppLogger.ui('开始删除账户: ${account.name}');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('删除账户'),
        content: Text('确定要删除账户 "${account.name}" 吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('删除', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await DataService.deleteAccount(account.id);

        // 从顺序列表中移除
        setState(() {
          _accountOrder.remove(account.id);
        });

        await _loadData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('账户 ${account.name} 已删除')),
          );
        }
        AppLogger.ui('成功删除账户: ${account.name}');
      } catch (e, stackTrace) {
        AppLogger.error('删除账户失败: ${account.name}', e, stackTrace);
        rethrow;
      }
    }
  }

  List<Account> _getOrderedAccounts() {
    final accountMap = <String, Account>{};
    for (final account in _accounts) {
      accountMap[account.id] = account;
    }

    final orderedAccounts = <Account>[];
    for (final accountId in _accountOrder) {
      if (accountMap.containsKey(accountId)) {
        orderedAccounts.add(accountMap[accountId]!);
      }
    }

    // 添加不在顺序列表中的账户（新添加的账户）
    for (final account in _accounts) {
      if (!_accountOrder.contains(account.id)) {
        orderedAccounts.add(account);
        _accountOrder.add(account.id);
      }
    }

    return orderedAccounts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('设置'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              AppLogger.ui('点击刷新设置数据按钮');
              _loadData();
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _buildContent(),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_account_settings',
        onPressed: _showAddAccountDialog,
        child: Icon(Icons.account_balance_wallet),
        tooltip: '添加账户',
      ),
    );
  }

  Widget _buildContent() {
    final orderedAccounts = _getOrderedAccounts();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 账户管理标题
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '账户管理',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // 账户列表
          if (orderedAccounts.isEmpty)
            _buildEmptyState()
          else
            _buildAccountList(orderedAccounts),

          // 设置说明
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '使用说明',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '• 长按账户可以拖动调整显示顺序\n'
                  '• 点击账户可以编辑账户信息\n'
                  '• 点击删除按钮可以删除账户',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(32),
      child: Column(
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

  Widget _buildAccountList(List<Account> accounts) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: accounts.length,
      itemBuilder: (context, index) {
        final account = accounts[index];
        return _buildAccountItem(account, index);
      },
      onReorder: _reorderAccount,
    );
  }

  Widget _buildAccountItem(Account account, int index) {
    return Card(
      key: Key(account.id),
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
        title: Text(
          account.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          account.typeName,
          style: TextStyle(color: Colors.grey),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${account.balance.toStringAsFixed(2)}元',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: account.balance >= 0 ? Colors.green : Colors.red,
              ),
            ),
            SizedBox(width: 16),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteAccount(account),
              tooltip: '删除账户',
            ),
          ],
        ),
        onTap: () {
          AppLogger.ui('点击编辑账户: ${account.name}');
          _showEditAccountDialog(account);
        },
      ),
    );
  }

  void _showEditAccountDialog(Account account) {
    AppLogger.ui('打开编辑账户对话框: ${account.name}');

    final nameController = TextEditingController(text: account.name);
    final balanceController = TextEditingController(text: account.balance.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('编辑账户'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: '账户名称',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: balanceController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: '余额',
                suffixText: '元',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              final newBalance = double.tryParse(balanceController.text);

              if (newName.isNotEmpty && newBalance != null) {
                final updatedAccount = Account(
                  id: account.id,
                  name: newName,
                  type: account.type,
                  balance: newBalance,
                  color: account.color,
                  createdAt: account.createdAt,
                );

                try {
                  await DataService.updateAccount(updatedAccount);
                  await _loadData();

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('账户已更新')),
                    );
                  }
                  AppLogger.ui('成功更新账户: ${account.name}');
                } catch (e, stackTrace) {
                  AppLogger.error('更新账户失败: ${account.name}', e, stackTrace);
                  rethrow;
                }
              }
            },
            child: Text('保存'),
          ),
        ],
      ),
    );
  }
}