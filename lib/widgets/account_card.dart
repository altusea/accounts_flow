import 'package:flutter/material.dart';
import '../models/account.dart';

class AccountCard extends StatelessWidget {
  final Account account;
  final double balance;
  final VoidCallback? onTap;

  const AccountCard({
    super.key,
    required this.account,
    required this.balance,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        onTap: onTap,
      ),
    );
  }
}