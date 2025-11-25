import 'package:flutter/material.dart';

enum AccountType {
  bankCard,
  digitalWallet,
  stockAccount,
  creditCard,
  cash,
  investment,
}

class Account {
  final String id;
  final String name;
  final AccountType type;
  final double balance;
  final Color color;
  final String? icon;
  final DateTime createdAt;

  Account({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.color,
    this.icon,
    required this.createdAt,
  });

  Account copyWith({
    String? id,
    String? name,
    AccountType? type,
    double? balance,
    Color? color,
    String? icon,
    DateTime? createdAt,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.index,
      'balance': balance,
      'color': color.alpha << 24 | color.red << 16 | color.green << 8 | color.blue,
      'icon': icon,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'],
      name: json['name'],
      type: AccountType.values[json['type']],
      balance: (json['balance'] as num).toDouble(),
      color: Color(json['color']),
      icon: json['icon'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  String get typeName {
    switch (type) {
      case AccountType.bankCard:
        return '银行卡';
      case AccountType.digitalWallet:
        return '电子钱包';
      case AccountType.stockAccount:
        return '股票账户';
      case AccountType.creditCard:
        return '信用卡';
      case AccountType.cash:
        return '现金';
      case AccountType.investment:
        return '投资账户';
    }
  }

  IconData get typeIcon {
    switch (type) {
      case AccountType.bankCard:
        return Icons.credit_card;
      case AccountType.digitalWallet:
        return Icons.wallet;
      case AccountType.stockAccount:
        return Icons.trending_up;
      case AccountType.creditCard:
        return Icons.payment;
      case AccountType.cash:
        return Icons.money;
      case AccountType.investment:
        return Icons.bar_chart;
    }
  }
}