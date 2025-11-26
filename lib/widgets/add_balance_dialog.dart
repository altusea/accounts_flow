import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/account.dart';
import '../models/balance_history.dart';
import '../services/data_service.dart';

class AddBalanceDialog extends StatefulWidget {
  final Function(BalanceHistory) onBalanceAdded;

  const AddBalanceDialog({super.key, required this.onBalanceAdded});

  @override
  State<AddBalanceDialog> createState() => _AddBalanceDialogState();
}

class _AddBalanceDialogState extends State<AddBalanceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _balanceController = TextEditingController(text: '0.00');

  List<Account> _accounts = [];
  List<DateTime> _availableDates = [];
  Account? _selectedAccount;
  DateTime? _selectedDate;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final accounts = await DataService.getAccounts();
    final history = await DataService.getBalanceHistory();

    // 获取所有未记录的日期（过去一年内）
    final now = DateTime.now();
    final oneYearAgo = DateTime(now.year - 1, now.month, now.day);
    final availableDates = <DateTime>[];

    var currentDate = oneYearAgo;
    while (currentDate.isBefore(now) || currentDate.isAtSameMomentAs(now)) {
      // 检查该日期是否已记录
      final dateString = DateFormat('yyyy-MM-dd').format(currentDate);
      final isRecorded = history.any((item) =>
          item.formattedDate == dateString);

      if (!isRecorded) {
        availableDates.add(currentDate);
      }
      currentDate = currentDate.add(Duration(days: 1));
    }

    // 按日期倒序排列
    availableDates.sort((a, b) => b.compareTo(a));

    setState(() {
      _accounts = accounts;
      _availableDates = availableDates;
      _isLoading = false;
    });

    // 默认选择最近的日期和第一个账户
    if (availableDates.isNotEmpty && accounts.isNotEmpty) {
      setState(() {
        _selectedDate = availableDates.first;
        _selectedAccount = accounts.first;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('记录余额'),
      content: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _buildContent(),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('取消'),
        ),
        ElevatedButton(
          onPressed: _saveBalance,
          child: Text('保存'),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_availableDates.isEmpty) {
      return SizedBox(
        height: 100,
        child: Center(
          child: Text(
            '所有日期都已记录过余额',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    if (_accounts.isEmpty) {
      return SizedBox(
        height: 100,
        child: Center(
          child: Text(
            '请先添加账户',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 日期选择
            DropdownButtonFormField<DateTime>(
              initialValue: _selectedDate,
              decoration: InputDecoration(
                labelText: '记录日期',
                border: OutlineInputBorder(),
              ),
              items: _availableDates.map((date) {
                final isSaturday = date.weekday == DateTime.saturday;
                return DropdownMenuItem<DateTime>(
                  value: date,
                  child: Row(
                    children: [
                      Text(DateFormat('yyyy年MM月dd日').format(date)),
                      SizedBox(width: 8),
                      if (isSaturday)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Text(
                            '周六',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.orange[200]!),
                          ),
                          child: Text(
                            '非周六',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.orange[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (DateTime? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedDate = newValue;
                  });
                }
              },
              validator: (value) => value == null ? '请选择日期' : null,
            ),
            SizedBox(height: 16),

            // 日期选择警告
            if (_selectedDate != null && _selectedDate!.weekday != DateTime.saturday)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange[700], size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '您选择的是非周六日期。建议在每周六记录余额以保持数据一致性。',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(height: 16),

            // 账户选择
            DropdownButtonFormField<Account>(
              initialValue: _selectedAccount,
              decoration: InputDecoration(
                labelText: '账户',
                border: OutlineInputBorder(),
              ),
              items: _accounts.map((account) {
                return DropdownMenuItem<Account>(
                  value: account,
                  child: Row(
                    children: [
                      Icon(account.typeIcon, color: account.color),
                      SizedBox(width: 8),
                      Text(account.name),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (Account? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedAccount = newValue;
                  });
                }
              },
              validator: (value) => value == null ? '请选择账户' : null,
            ),
            SizedBox(height: 16),

            // 余额输入
            TextFormField(
              controller: _balanceController,
              decoration: InputDecoration(
                labelText: '余额 (人民币)',
                border: OutlineInputBorder(),
                prefixText: '',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入余额';
                }
                final balance = double.tryParse(value);
                if (balance == null) {
                  return '请输入有效的金额';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  void _saveBalance() {
    if (_formKey.currentState!.validate() &&
        _selectedDate != null &&
        _selectedAccount != null) {

      final balance = double.parse(_balanceController.text);
      final history = BalanceHistory(
        id: '${_selectedAccount!.id}_${_selectedDate!.millisecondsSinceEpoch}',
        accountId: _selectedAccount!.id,
        balance: balance,
        recordDate: _selectedDate!,
        createdAt: DateTime.now(),
      );

      // 如果是非周六日期，显示确认对话框
      if (_selectedDate!.weekday != DateTime.saturday) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('确认记录非周六余额'),
            content: Text(
              '您选择的是非周六日期 (${DateFormat('yyyy年MM月dd日').format(_selectedDate!)}). '
              '建议在每周六记录余额以保持数据一致性。\n\n'
              '确定要继续记录吗？'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('取消'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onBalanceAdded(history);
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
                child: Text('确定记录'),
              ),
            ],
          ),
        );
      } else {
        widget.onBalanceAdded(history);
        Navigator.of(context).pop();
      }
    }
  }
}