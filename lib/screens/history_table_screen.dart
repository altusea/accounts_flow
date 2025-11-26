import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/account.dart';
import '../models/balance_history.dart';
import '../services/data_service.dart';
import '../utils/logger.dart';

class HistoryTableScreen extends StatefulWidget {
  const HistoryTableScreen({super.key});

  @override
  State<HistoryTableScreen> createState() => _HistoryTableScreenState();
}

class _HistoryTableScreenState extends State<HistoryTableScreen> {
  List<Account> _accounts = [];
  List<DateTime> _recordedDates = [];
  Map<String, Map<String, double>> _tableData = {}; // accountId -> date -> balance
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    AppLogger.ui('HistoryTableScreen 初始化');
    _loadData();
  }

  Future<void> _loadData() async {
    AppLogger.ui('开始加载表格数据');
    setState(() {
      _isLoading = true;
    });

    try {
      final accounts = await DataService.getAccounts();
      final dates = await DataService.getRecordedDates();
      final allHistory = await DataService.getBalanceHistory();

      // 构建表格数据结构
      final tableData = <String, Map<String, double>>{};

      for (final account in accounts) {
        tableData[account.id] = {};
      }

      for (final history in allHistory) {
        final dateKey = DateFormat('yyyy-MM-dd').format(history.recordDate);
        if (tableData.containsKey(history.accountId)) {
          tableData[history.accountId]![dateKey] = history.balance;
        }
      }

      // 日期倒序排列
      final sortedDates = List<DateTime>.from(dates);
      sortedDates.sort((a, b) => b.compareTo(a));

      setState(() {
        _accounts = accounts;
        _recordedDates = sortedDates;
        _tableData = tableData;
        _isLoading = false;
      });

      AppLogger.ui('成功加载表格数据: ${accounts.length} 个账户, ${sortedDates.length} 个日期（倒序）');
    } catch (e, stackTrace) {
      AppLogger.error('加载表格数据失败', e, stackTrace);
      rethrow;
    }
  }

  Future<void> _editCell(String accountId, DateTime date, double currentBalance) async {
    AppLogger.ui('开始编辑单元格: $accountId, ${DateFormat('yyyy-MM-dd').format(date)}');

    final TextEditingController controller = TextEditingController(
      text: currentBalance.toStringAsFixed(2),
    );

    final result = await showDialog<double?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('编辑余额'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: '余额',
            suffixText: '元',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null) {
                Navigator.pop(context, value);
              }
            },
            child: Text('保存'),
          ),
        ],
      ),
    );

    if (result != null && result != currentBalance) {
      AppLogger.ui('保存单元格编辑: $accountId, ${DateFormat('yyyy-MM-dd').format(date)}, $result');

      try {
        // 创建或更新余额历史记录
        final history = BalanceHistory(
          id: '${accountId}_${date.millisecondsSinceEpoch}',
          accountId: accountId,
          balance: result,
          recordDate: date,
          createdAt: DateTime.now(),
        );

        await DataService.addBalanceHistory(history);

        // 更新表格数据
        final dateKey = DateFormat('yyyy-MM-dd').format(date);
        setState(() {
          _tableData[accountId]![dateKey] = result;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('余额已更新')),
          );
        }

        AppLogger.ui('成功更新余额: $accountId, $dateKey, $result');
      } catch (e, stackTrace) {
        AppLogger.error('更新余额失败', e, stackTrace);
        rethrow;
      }
    }
  }

  double _getCellBalance(String accountId, DateTime date) {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    return _tableData[accountId]?[dateKey] ?? 0.0;
  }

  double _getRowTotal(String accountId) {
    final accountData = _tableData[accountId];
    if (accountData == null || accountData.isEmpty) {
      return 0.0;
    }
    return accountData.values.fold(0.0, (sum, balance) => sum + balance);
  }

  double _getColumnTotal(DateTime date) {
    double total = 0.0;
    for (final account in _accounts) {
      total += _getCellBalance(account.id, date);
    }
    return total;
  }

  double _getGrandTotal() {
    double total = 0.0;
    for (final account in _accounts) {
      total += _getRowTotal(account.id);
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('历史余额表格'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              AppLogger.ui('点击刷新表格数据按钮');
              _loadData();
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _buildTable(),
    );
  }

  Widget _buildTable() {
    if (_recordedDates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.table_chart,
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
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 表头
            _buildTableHeader(),
            // 数据行
            ..._buildDataRows(),
            // 总计行
            _buildTotalRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          // 日期列
          Container(
            width: 120,
            padding: EdgeInsets.all(12),
            child: Text(
              '日期',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          // 账户列
          ..._accounts.map((account) {
            return Container(
              width: 100,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Column(
                children: [
                  Text(
                    account.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Text(
                    account.typeName,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            );
          }),
          // 合计列
          Container(
            width: 100,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: Colors.grey[300]!)),
              color: Colors.blue[50],
            ),
            child: Text(
              '合计',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.blue[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDataRows() {
    return _recordedDates.map((date) {
      return Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
        ),
        child: Row(
          children: [
            // 日期
            Container(
              width: 120,
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('MM-dd').format(date),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    DateFormat('EEE').format(date),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            // 余额数据
            ..._accounts.map((account) {
              final balance = _getCellBalance(account.id, date);
              return GestureDetector(
                onTap: () => _editCell(account.id, date, balance),
                child: Container(
                  width: 100,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border(left: BorderSide(color: Colors.grey[200]!)),
                    color: Colors.white,
                  ),
                  child: Text(
                    balance == 0 ? '-' : balance.toStringAsFixed(2),
                    style: TextStyle(
                      fontSize: 12,
                      color: balance >= 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }),
            // 行合计（日期合计）
            Container(
              width: 100,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: Colors.grey[200]!)),
                color: Colors.blue[50],
              ),
              child: Text(
                _getColumnTotal(date).toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildTotalRow() {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
        color: Colors.green[50],
      ),
      child: Row(
        children: [
          // 总计标签
          Container(
            width: 120,
            padding: EdgeInsets.all(12),
            child: Text(
              '总计',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.green[700],
              ),
            ),
          ),
          // 账户总计
          ..._accounts.map((account) {
            final total = _getRowTotal(account.id);
            return Container(
              width: 100,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Text(
                total.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: total >= 0 ? Colors.green : Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
            );
          }),
          // 总计
          Container(
            width: 100,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: Colors.grey[300]!)),
              color: Colors.green[100],
            ),
            child: Text(
              _getGrandTotal().toStringAsFixed(2),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}