import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../services/data_service.dart';

class BalanceChart extends StatefulWidget {
  final String accountId;

  const BalanceChart({super.key, required this.accountId});

  @override
  State<BalanceChart> createState() => _BalanceChartState();
}

class _BalanceChartState extends State<BalanceChart> {
  List<Transaction> _transactions = [];
  Account? _account;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final accounts = await DataService.getAccounts();
    final account = accounts.firstWhere((acc) => acc.id == widget.accountId);
    final transactions = await DataService.getTransactionsByAccount(widget.accountId);

    setState(() {
      _account = account;
      _transactions = transactions;
    });
  }

  List<FlSpot> _getChartData() {
    if (_transactions.isEmpty) return [];

    // 按日期分组交易
    final Map<String, double> dailyBalances = {};
    double runningBalance = 0.0;

    // 按日期排序交易
    final sortedTransactions = List<Transaction>.from(_transactions)
      ..sort((a, b) => a.date.compareTo(b.date));

    for (final transaction in sortedTransactions) {
      final dateKey = DateFormat('MM-dd').format(transaction.date);

      if (transaction.accountId == widget.accountId) {
        if (transaction.type == TransactionType.income) {
          runningBalance += transaction.amount;
        } else if (transaction.type == TransactionType.expense) {
          runningBalance -= transaction.amount;
        } else if (transaction.type == TransactionType.transfer) {
          runningBalance -= transaction.amount;
        }
      } else if (transaction.targetAccountId == widget.accountId) {
        if (transaction.type == TransactionType.transfer) {
          runningBalance += transaction.amount;
        }
      }

      dailyBalances[dateKey] = runningBalance;
    }

    // 转换为FlSpot格式
    final spots = dailyBalances.entries
        .map((entry) {
          final dateParts = entry.key.split('-');
          final month = int.parse(dateParts[0]);
          final day = int.parse(dateParts[1]);
          // 使用月份和日期作为x轴值
          final x = month * 100 + day; // 例如：12月15日 -> 1215
          return FlSpot(x.toDouble(), entry.value);
        })
        .toList();

    spots.sort((a, b) => a.x.compareTo(b.x));
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    final chartData = _getChartData();

    if (chartData.isEmpty) {
      return Container(
        height: 200,
        child: Center(
          child: Text(
            '暂无交易数据',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
      height: 200,
      padding: EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  if (value % 100 == 0) {
                    final month = (value ~/ 100).toInt();
                    return Text('$month月');
                  }
                  return Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '¥${value.toInt()}',
                    style: TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: chartData,
              isCurved: true,
              color: _account?.color ?? Colors.blue,
              barWidth: 3,
              isStrokeCapRound: true,
              belowBarData: BarAreaData(show: false),
              dotData: FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}