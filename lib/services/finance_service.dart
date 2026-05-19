// lib/services/finance_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gross/services/auth_service.dart';

class FinanceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get _companyId =>
      AuthService().currentUser?.companyId ?? 'default_company';
  String get _shopId => AuthService().currentUser?.shopId ?? 'default_shop';

  Future<void> addExpense(String title, double amount) async {
    String id = _db.collection('expenses').doc().id;
    await _db.collection('expenses').doc(id).set({
      'title': title,
      'amount': amount,
      'date': DateTime.now().toIso8601String(),
      'companyId': _companyId,
      'shopId': _shopId,
    });
  }

  Stream<QuerySnapshot> getDailyExpenses(DateTime date) {
    DateTime start = DateTime(date.year, date.month, date.day);
    DateTime end = start.add(const Duration(days: 1));

    return _db
        .collection('expenses')
        .where('companyId', isEqualTo: _companyId)
        .where('shopId', isEqualTo: _shopId)
        .where('date', isGreaterThanOrEqualTo: start.toIso8601String())
        .where('date', isLessThan: end.toIso8601String())
        .snapshots();
  }

  String addCreditAccount(String name) {
    String id = _db.collection('credit_accounts').doc().id;
    _db.collection('credit_accounts').doc(id).set({
      'name': name,
      'totalDebt': 0.0,
      'companyId': _companyId,
      'shopId': _shopId,
    });
    return id;
  }

  Stream<List<dynamic>> getCreditAccounts() {
    return _db
        .collection('credit_accounts')
        .where('companyId', isEqualTo: _companyId)
        .where('shopId', isEqualTo: _shopId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  // EKLENEN METOT: İlgili cari hesabı Firestore'dan siler
  Future<void> deleteCreditAccount(String accountId) async {
    await _db.collection('credit_accounts').doc(accountId).delete();
  }

  Future<void> addDebtToAccount(
    String accountId,
    double amount, {
    String? note,
  }) async {
    WriteBatch batch = _db.batch();
    DocumentReference accountRef = _db
        .collection('credit_accounts')
        .doc(accountId);
    batch.update(accountRef, {'totalDebt': FieldValue.increment(amount)});

    DocumentReference transactionRef = accountRef
        .collection('transactions')
        .doc();
    batch.set(transactionRef, {
      'amount': amount,
      'type': 'debt',
      'detail': note ?? "Elden Borç Yazıldı",
      'date': DateTime.now().toIso8601String(),
      'companyId': _companyId,
      'shopId': _shopId,
    });
    await batch.commit();
  }

  Future<void> receivePaymentFromAccount(
    String accountId,
    String accountName,
    double amount,
    String method,
  ) async {
    WriteBatch batch = _db.batch();
    DocumentReference accountRef = _db
        .collection('credit_accounts')
        .doc(accountId);
    batch.update(accountRef, {'totalDebt': FieldValue.increment(-amount)});

    DocumentReference transactionRef = accountRef
        .collection('transactions')
        .doc();
    batch.set(transactionRef, {
      'amount': amount,
      'type': 'payment',
      'detail': "Tahsilat ($method)",
      'date': DateTime.now().toIso8601String(),
      'companyId': _companyId,
      'shopId': _shopId,
    });

    String saleId = _db.collection('sales').doc().id;
    DocumentReference saleRef = _db.collection('sales').doc(saleId);
    batch.set(saleRef, {
      'totalAmount': amount,
      'totalCost': 0.0,
      'date': DateTime.now().toIso8601String(),
      'soldItems': {'Tahsilat: $accountName': 1},
      'paymentMethod': method,
      'companyId': _companyId,
      'shopId': _shopId,
    });
    await batch.commit();
  }

  Stream<QuerySnapshot> getCustomerTransactions(String accountId) {
    return _db
        .collection('credit_accounts')
        .doc(accountId)
        .collection('transactions')
        .orderBy('date', descending: true)
        .snapshots();
  }
}
