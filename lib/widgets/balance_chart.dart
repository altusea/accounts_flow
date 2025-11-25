import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/account.dart';
import '../models/balance_history.dart';
import '../services/data_service.dart';

class BalanceChart extends StatefulWidget {
  final String accountId;

  const BalanceChart({super.key, required this.accountId});

  @override
  State<BalanceChart> createState() => _BalanceChartState();
}

class _BalanceChartState extends State<BalanceChart> {
  List<BalanceHistory> _balanceHistory = [];
  Account? _account;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final accounts = await DataService.getAccounts();
    final account = accounts.firstWhere((acc) => acc.id == widget.accountId);
    final history = await DataService.getBalanceHistoryByAccount(widget.accountId);

    setState(() {
      _account = account;
      _balanceHistory = history;
    });
  }

  List<FlSpot> _getChartData() {
    if (_balanceHistory.isEmpty) return [];

    // 按日期分组余额历史
    final Map<String, double> dailyBalances = {};

    // 按日期排序余额历史
    final sortedHistory = List<BalanceHistory>.from(_balanceHistory)
      ..sort((a, b) => a.recordDate.compareTo(b.recordDate));

    for (final history in sortedHistory) {
      final dateKey = DateFormat('MM-dd').format(history.recordDate);
      dailyBalances[dateKey] = history.balance;
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
            '暂无余额历史数据',
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
                    '${value.toInt()}元',
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