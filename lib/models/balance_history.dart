import 'package:intl/intl.dart';

class BalanceHistory {
  final String id;
  final String accountId;
  final double balance;
  final DateTime recordDate;
  final DateTime createdAt;

  BalanceHistory({
    required this.id,
    required this.accountId,
    required this.balance,
    required this.recordDate,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'accountId': accountId,
      'balance': balance,
      'recordDate': recordDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory BalanceHistory.fromJson(Map<String, dynamic> json) {
    return BalanceHistory(
      id: json['id'],
      accountId: json['accountId'],
      balance: (json['balance'] as num).toDouble(),
      recordDate: DateTime.parse(json['recordDate']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  String get formattedDate {
    return DateFormat('yyyy-MM-dd').format(recordDate);
  }

  String get formattedWeek {
    return DateFormat('yyyy年MM月dd日').format(recordDate);
  }

  bool get isSaturday {
    return recordDate.weekday == DateTime.saturday;
  }

  static bool isSaturdayDate(DateTime date) {
    return date.weekday == DateTime.saturday;
  }

  static DateTime getLastSaturday() {
    final now = DateTime.now();
    final daysSinceSaturday = (now.weekday - DateTime.saturday) % 7;
    return DateTime(now.year, now.month, now.day - daysSinceSaturday);
  }

  static DateTime getNextSaturday() {
    final now = DateTime.now();
    final daysUntilSaturday = (DateTime.saturday - now.weekday) % 7;
    return DateTime(now.year, now.month, now.day + daysUntilSaturday);
  }
}