import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/account.dart';
import '../services/data_service.dart';

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
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final accounts = await DataService.getAccounts();
    final dates = await DataService.getRecordedDates();

    setState(() {
      _accounts = accounts;
      _recordedDates = dates;
      _isLoading = false;
    });

    // 默认选择最近的日期
    if (dates.isNotEmpty && _selectedDate == null) {
      _selectDate(dates.first);
    }
  }

  Future<void> _selectDate(DateTime date) async {
    final balances = await DataService.getBalancesByDate(date);
    setState(() {
      _selectedDate = date;
      _selectedDateBalances = balances;
    });
  }

  Future<void> _recordCurrentBalances() async {
    await DataService.recordWeeklyBalances();
    await _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已记录当前账户余额')),
      );
    }
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
            icon: Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          if (DateTime.now().weekday == DateTime.saturday)
            IconButton(
              icon: Icon(Icons.save),
              onPressed: _recordCurrentBalances,
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
                onPressed: _recordCurrentBalances,
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
                        onSelected: (_) => _selectDate(date),
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
                    '¥${_totalBalanceForSelectedDate.toStringAsFixed(2)}',
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
                      '¥${balance.toStringAsFixed(2)}',
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