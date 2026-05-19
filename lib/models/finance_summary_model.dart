// lib/models/finance_summary_model.dart
import 'package:gross/models/transaction_model.dart';

class DailyCashSummary {
  final double totalCiro;
  final Map<String, double> salesByMethod;
  final double toplamGider;
  final double netKasa;
  final List<TransactionItem> transactions;

  DailyCashSummary({
    required this.totalCiro,
    required this.salesByMethod,
    required this.toplamGider,
    required this.netKasa,
    required this.transactions,
  });
}

class BossReportSummary {
  final double totalCiro;
  final double totalCost;
  final double totalExpense;
  final double netProfit;
  final List<MapEntry<String, int>> top10Products;

  BossReportSummary({
    required this.totalCiro,
    required this.totalCost,
    required this.totalExpense,
    required this.netProfit,
    required this.top10Products,
  });
}
