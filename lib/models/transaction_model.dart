// lib/models/transaction_model.dart

class TransactionItem {
  final String title;
  final double amount;
  final DateTime date;
  final bool isIncome;
  final String? paymentMethod;
  final String? createdByName;

  TransactionItem({
    required this.title,
    required this.amount,
    required this.date,
    required this.isIncome,
    this.paymentMethod,
    this.createdByName,
  });
}
