import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/account.dart';

class AddTransactionDialog extends StatefulWidget {
  final List<Account> accounts;
  final Function(Transaction) onTransactionAdded;

  const AddTransactionDialog({
    super.key,
    required this.accounts,
    required this.onTransactionAdded,
  });

  @override
  State<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  TransactionType _selectedType = TransactionType.expense;
  Account? _selectedAccount;
  Account? _selectedTargetAccount;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.accounts.isNotEmpty) {
      _selectedAccount = widget.accounts.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('添加交易'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<TransactionType>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: '交易类型',
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: TransactionType.income,
                    child: Row(
                      children: [
                        Icon(Icons.arrow_downward, color: Colors.green),
                        SizedBox(width: 8),
                        Text('收入'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: TransactionType.expense,
                    child: Row(
                      children: [
                        Icon(Icons.arrow_upward, color: Colors.red),
                        SizedBox(width: 8),
                        Text('支出'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: TransactionType.transfer,
                    child: Row(
                      children: [
                        Icon(Icons.swap_horiz, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('转账'),
                      ],
                    ),
                  ),
                ],
                onChanged: (TransactionType? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedType = newValue;
                      _selectedTargetAccount = null;
                    });
                  }
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<Account>(
                value: _selectedAccount,
                decoration: InputDecoration(
                  labelText: _selectedType == TransactionType.transfer ? '转出账户' : '账户',
                  border: OutlineInputBorder(),
                ),
                items: widget.accounts.map((account) {
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
              if (_selectedType == TransactionType.transfer) ...[
                SizedBox(height: 16),
                DropdownButtonFormField<Account>(
                  value: _selectedTargetAccount,
                  decoration: InputDecoration(
                    labelText: '转入账户',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.accounts
                      .where((account) => account.id != _selectedAccount?.id)
                      .map((account) {
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
                        _selectedTargetAccount = newValue;
                      });
                    }
                  },
                  validator: (value) => _selectedType == TransactionType.transfer && value == null
                      ? '请选择转入账户'
                      : null,
                ),
              ],
              SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: '金额',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入金额';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return '请输入有效的金额';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: '描述',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入描述';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Text('日期: '),
                  Expanded(
                    child: TextButton(
                      onPressed: () => _selectDate(context),
                      child: Text(
                        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                      ),
                    ),
                  ),
                ],
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
          onPressed: _saveTransaction,
          child: Text('保存'),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveTransaction() {
    if (_formKey.currentState!.validate() && _selectedAccount != null) {
      final transaction = Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        accountId: _selectedAccount!.id,
        type: _selectedType,
        amount: double.parse(_amountController.text),
        description: _descriptionController.text,
        date: _selectedDate,
        targetAccountId: _selectedType == TransactionType.transfer
            ? _selectedTargetAccount?.id
            : null,
      );

      widget.onTransactionAdded(transaction);
      Navigator.of(context).pop();
    }
  }
}