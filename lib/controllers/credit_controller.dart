// lib/controllers/credit_controller.dart
import 'package:flutter/material.dart';
import 'package:gross/services/finance_service.dart';
import 'package:gross/models/credit_account_model.dart';

class CreditController extends ChangeNotifier {
  final FinanceService _financeService = FinanceService();

  // 1. DÜZELTME: UI ARTIK MAP İLE UĞRAŞMAZ. BEYİN DOĞRUDAN MODEL DÖNDÜRÜR.
  Stream<List<CreditAccount>> get creditAccountsStream {
    return _financeService.getCreditAccounts().map((list) {
      return list
          .map(
            (data) =>
                CreditAccount.fromMap(data as Map<String, dynamic>, data['id']),
          )
          .toList();
    });
  }

  // 2. DÜZELTME: QuerySnapshot UI'dan söküldü. Doğrudan Map listesi döner.
  Stream<List<Map<String, dynamic>>> getCustomerTransactionsStream(
    String accountId,
  ) {
    return _financeService.getCustomerTransactions(accountId).map((snapshot) {
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    });
  }

  Future<void> addCreditAccount(String name) async {
    _financeService.addCreditAccount(name);
  }

  Future<void> addDebtToAccount(
    String accountId,
    double amount,
    String note,
  ) async {
    await _financeService.addDebtToAccount(accountId, amount, note: note);
  }

  // EKSİK OLAN VE EKLENEN METOT: Cari hesabı silme
  Future<void> deleteCreditAccount(String accountId) async {
    // Not: _financeService (FinanceService) içerisinde deleteCreditAccount adında
    // Firestore'dan veriyi silecek ilgili metodun tanımlı olması gerekir.
    await _financeService.deleteCreditAccount(accountId);
  }

  // 3. DÜZELTME: BUSINESS LOGIC BEYNE GELDİ!
  // Başarılıysa null döner, hata varsa hata mesajı döner.
  Future<String?> processPayment(
    String accountId,
    String accountName,
    double amount,
    String method,
    double totalDebt,
  ) async {
    if (amount <= 0) return "Tutar 0'dan büyük olmalıdır.";
    if (amount > totalDebt) return "Hata: Borçtan fazla tahsilat girilemez!";

    try {
      await _financeService.receivePaymentFromAccount(
        accountId,
        accountName,
        amount,
        method,
      );
      return null; // Başarılı
    } catch (e) {
      return "Bir hata oluştu: $e";
    }
  }
}
