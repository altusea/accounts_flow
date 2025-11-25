import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum TransactionType {
  income,
  expense,
  transfer,
}

class Transaction {
  final String id;
  final String accountId;
  final TransactionType type;
  final double amount;
  final String description;
  final DateTime date;
  final String? category;
  final String? targetAccountId;

  Transaction({
    required this.id,
    required this.accountId,
    required this.type,
    required this.amount,
    required this.description,
    required this.date,
    this.category,
    this.targetAccountId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'accountId': accountId,
      'type': type.index,
      'amount': amount,
      'description': description,
      'date': date.toIso8601String(),
      'category': category,
      'targetAccountId': targetAccountId,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      accountId: json['accountId'],
      type: TransactionType.values[json['type']],
      amount: (json['amount'] as num).toDouble(),
      description: json['description'],
      date: DateTime.parse(json['date']),
      category: json['category'],
      targetAccountId: json['targetAccountId'],
    );
  }

  String get formattedDate {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String get formattedTime {
    return DateFormat('HH:mm').format(date);
  }

  String get typeName {
    switch (type) {
      case TransactionType.income:
        return '收入';
      case TransactionType.expense:
        return '支出';
      case TransactionType.transfer:
        return '转账';
    }
  }

  Color get typeColor {
    switch (type) {
      case TransactionType.income:
        return Colors.green;
      case TransactionType.expense:
        return Colors.red;
      case TransactionType.transfer:
        return Colors.blue;
    }
  }

  String get formattedAmount {
    final prefix = type == TransactionType.expense ? '-' : '+';
    return '$prefix¥${amount.toStringAsFixed(2)}';
  }
}