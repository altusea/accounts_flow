import 'package:flutter/material.dart';
import '../models/account.dart';

class AddAccountDialog extends StatefulWidget {
  final Function(Account, double) onAccountAdded;

  const AddAccountDialog({super.key, required this.onAccountAdded});

  @override
  State<AddAccountDialog> createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends State<AddAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController(text: '0.00');
  AccountType _selectedType = AccountType.bankCard;
  Color _selectedColor = Colors.blue;

  final List<Color> _availableColors = [
    Colors.blue,
    Colors.green,
    Colors.red,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('添加账户'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: '账户名称',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入账户名称';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<AccountType>(
                initialValue: _selectedType,
                decoration: InputDecoration(
                  labelText: '账户类型',
                  border: OutlineInputBorder(),
                ),
                items: AccountType.values.map((type) {
                  return DropdownMenuItem<AccountType>(
                    value: type,
                    child: Row(
                      children: [
                        Icon(_getIconForType(type)),
                        SizedBox(width: 8),
                        Text(_getTypeName(type)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (AccountType? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedType = newValue;
                    });
                  }
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _balanceController,
                decoration: InputDecoration(
                  labelText: '初始余额',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入初始余额';
                  }
                  final balance = double.tryParse(value);
                  if (balance == null) {
                    return '请输入有效的金额';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              Text('选择颜色:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableColors.map((color) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColor = color;
                      });
                    },
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: _selectedColor == color
                            ? Border.all(color: Colors.black, width: 2)
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('取消'),
        ),
        ElevatedButton(
          onPressed: _saveAccount,
          child: Text('保存'),
        ),
      ],
    );
  }

  void _saveAccount() {
    if (_formKey.currentState!.validate()) {
      final account = Account(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        type: _selectedType,
        color: _selectedColor,
        createdAt: DateTime.now(),
      );

      final initialBalance = double.parse(_balanceController.text);
      widget.onAccountAdded(account, initialBalance);
      Navigator.of(context).pop();
    }
  }

  IconData _getIconForType(AccountType type) {
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

  String _getTypeName(AccountType type) {
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
}