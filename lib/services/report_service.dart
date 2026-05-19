// lib/services/report_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gross/models/sale_model.dart';
import 'package:gross/models/expense_model.dart';

class ReportService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getShops(String companyId) async {
    var snap = await _db
        .collection('shops')
        .where('companyId', isEqualTo: companyId)
        .get();
    return snap.docs
        .map((d) => {'id': d.id, 'name': d['name'] as String})
        .toList();
  }

  Stream<List<Sale>> getDailySales(
    String companyId,
    String? shopId,
    DateTime start,
    DateTime end,
  ) {
    Query q = _db
        .collection('sales')
        .where('companyId', isEqualTo: companyId)
        .where('date', isGreaterThanOrEqualTo: start.toIso8601String())
        .where('date', isLessThan: end.toIso8601String());
    if (shopId != null) q = q.where('shopId', isEqualTo: shopId);
    return q.snapshots().map(
      (s) => s.docs
          .map((d) => Sale.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList(),
    );
  }

  Stream<List<Expense>> getDailyExpenses(
    String companyId,
    String? shopId,
    DateTime start,
    DateTime end,
  ) {
    Query q = _db
        .collection('expenses')
        .where('companyId', isEqualTo: companyId)
        .where('date', isGreaterThanOrEqualTo: start.toIso8601String())
        .where('date', isLessThan: end.toIso8601String());
    if (shopId != null) q = q.where('shopId', isEqualTo: shopId);
    return q.snapshots().map(
      (s) => s.docs
          .map((d) => Expense.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList(),
    );
  }

  Future<List<Sale>> getSalesFuture(
    String companyId,
    String? shopId,
    DateTime start,
    DateTime end,
  ) async {
    Query q = _db
        .collection('sales')
        .where('companyId', isEqualTo: companyId)
        .where('date', isGreaterThanOrEqualTo: start.toIso8601String())
        .where('date', isLessThan: end.toIso8601String());
    if (shopId != null) q = q.where('shopId', isEqualTo: shopId);
    var s = await q.get();
    return s.docs
        .map((d) => Sale.fromMap(d.data() as Map<String, dynamic>, d.id))
        .toList();
  }

  Future<List<Expense>> getExpensesFuture(
    String companyId,
    String? shopId,
    DateTime start,
    DateTime end,
  ) async {
    Query q = _db
        .collection('expenses')
        .where('companyId', isEqualTo: companyId)
        .where('date', isGreaterThanOrEqualTo: start.toIso8601String())
        .where('date', isLessThan: end.toIso8601String());
    if (shopId != null) q = q.where('shopId', isEqualTo: shopId);
    var s = await q.get();
    return s.docs
        .map((d) => Expense.fromMap(d.data() as Map<String, dynamic>, d.id))
        .toList();
  }

  Future<void> addExpense(
    String companyId,
    String shopId,
    String userName,
    String userId,
    String title,
    double amount,
  ) async {
    await _db.collection('expenses').add({
      'title': title,
      'amount': amount,
      'date': DateTime.now().toIso8601String(),
      'companyId': companyId,
      'shopId': shopId,
      'createdByName': userName,
      'createdById': userId,
    });
  }
}
