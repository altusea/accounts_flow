import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/account.dart';
import '../services/data_service.dart';
import '../utils/logger.dart';
import '../widgets/add_balance_dialog.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Account> _accounts = [];
  List<DateTime> _recordedDates = [];
  DateTime? _selectedDate;
  Map<String, double> _selectedDateBalances = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    AppLogger.ui('HistoryScreen 初始化');
    _loadData();
  }

  Future<void> _loadData() async {
    AppLogger.ui('开始加载历史数据');
    setState(() {
      _isLoading = true;
    });

    try {
      final accounts = await DataService.getAccounts();
      final dates = await DataService.getRecordedDates();

      setState(() {
        _accounts = accounts;
        _recordedDates = dates;
        _isLoading = false;
      });

      AppLogger.ui('成功加载 ${accounts.length} 个账户和 ${dates.length} 个历史日期');

      // 默认选择最近的日期
      if (dates.isNotEmpty && _selectedDate == null) {
        _selectDate(dates.first);
      }
    } catch (e, stackTrace) {
      AppLogger.error('加载历史数据失败', e, stackTrace);
      rethrow;
    }
  }

  Future<void> _selectDate(DateTime date) async {
    AppLogger.ui('选择日期: ${DateFormat('yyyy-MM-dd').format(date)}');
    try {
      final balances = await DataService.getBalancesByDate(date);
      setState(() {
        _selectedDate = date;
        _selectedDateBalances = balances;
      });
      AppLogger.ui('成功加载 ${balances.length} 个账户在 ${DateFormat('yyyy-MM-dd').format(date)} 的余额');
    } catch (e, stackTrace) {
      AppLogger.error('选择日期 ${DateFormat('yyyy-MM-dd').format(date)} 失败', e, stackTrace);
      rethrow;
    }
  }

  Future<void> _recordCurrentBalances() async {
    AppLogger.ui('开始记录本周余额');
    try {
      await DataService.recordWeeklyBalances();
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已记录当前账户余额')),
        );
      }
      AppLogger.ui('成功记录本周余额');
    } catch (e, stackTrace) {
      AppLogger.error('记录本周余额失败', e, stackTrace);
      rethrow;
    }
  }

  void _showAddBalanceDialog() {
    AppLogger.ui('打开手动记录余额对话框');
    showDialog(
      context: context,
      builder: (context) => AddBalanceDialog(
        onBalanceAdded: (history) async {
          AppLogger.ui('开始手动记录余额: ${history.accountId} - ${history.balance}元');
          try {
            await DataService.addBalanceHistory(history);
            await _loadData();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('余额记录已保存')),
              );
            }
            AppLogger.ui('成功手动记录余额: ${history.accountId}');
          } catch (e, stackTrace) {
            AppLogger.error('手动记录余额失败: ${history.accountId}', e, stackTrace);
            rethrow;
          }
        },
      ),
    );
  }

  double get _totalBalanceForSelectedDate {
    return _selectedDateBalances.values.fold(0.0, (sum, balance) => sum + balance);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('历史余额'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              AppLogger.ui('点击手动记录余额按钮');
              _showAddBalanceDialog();
            },
            tooltip: '手动记录余额',
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              AppLogger.ui('点击刷新历史数据按钮');
              _loadData();
            },
          ),
          if (DateTime.now().weekday == DateTime.saturday)
            IconButton(
              icon: Icon(Icons.save),
              onPressed: () {
                AppLogger.ui('点击记录本周余额按钮');
                _recordCurrentBalances();
              },
              tooltip: '记录本周余额',
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_recordedDates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              '暂无历史记录',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              '每周六会自动记录账户余额',
              style: TextStyle(color: Colors.grey),
            ),
            if (DateTime.now().weekday == DateTime.saturday) ...[
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  AppLogger.ui('点击空状态记录本周余额按钮');
                  _recordCurrentBalances();
                },
                child: Text('记录本周余额'),
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      children: [
        // 日期选择器
        Container(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '选择日期:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _recordedDates.map((date) {
                    final isSelected = _selectedDate == date;
                    return Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(
                          DateFormat('MM月dd日').format(date),
                          style: TextStyle(
                            color: isSelected ? Colors.white : null,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (_) {
                          AppLogger.ui('点击日期选择器: ${DateFormat('MM月dd日').format(date)}');
                          _selectDate(date);
                        },
                        backgroundColor: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.grey[200],
                        selectedColor: Theme.of(context).primaryColor,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // 总余额卡片
        if (_selectedDate != null) ...[
          Card(
            margin: EdgeInsets.all(16),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${DateFormat('yyyy年MM月dd日').format(_selectedDate!)} 总余额',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${_totalBalanceForSelectedDate.toStringAsFixed(2)}元',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: _totalBalanceForSelectedDate >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 账户余额列表
          Expanded(
            child: ListView.builder(
              itemCount: _accounts.length,
              itemBuilder: (context, index) {
                final account = _accounts[index];
                final balance = _selectedDateBalances[account.id] ?? 0.0;

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
                    trailing: Text(
                      '${balance.toStringAsFixed(2)}元',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: balance >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}