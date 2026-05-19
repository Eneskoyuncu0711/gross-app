// lib/services/sale_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gross/models/sale_model.dart';
import 'package:gross/services/auth_service.dart';

class SaleService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get _companyId =>
      AuthService().currentUser?.companyId ?? 'default_company';
  String get _shopId => AuthService().currentUser?.shopId ?? 'default_shop';

  Future<void> saveSale(
    List<dynamic> cartItems,
    String paymentMethod,
    double totalAmount,
  ) async {
    String saleId = _db.collection('sales').doc().id;
    Map<String, int> soldItemsMap = {};
    double calculatedTotalCost = 0.0;

    for (var item in cartItems) {
      soldItemsMap[item.product.name] = item.quantity;
      calculatedTotalCost += (item.product.costPrice * item.quantity);
    }

    Sale newSale = Sale(
      id: saleId,
      totalAmount: totalAmount,
      totalCost: calculatedTotalCost,
      date: DateTime.now(),
      soldItems: soldItemsMap,
      paymentMethod: paymentMethod,
    );

    WriteBatch batch = _db.batch();
    Map<String, dynamic> saleData = newSale.toMap();
    saleData['companyId'] = _companyId;
    saleData['shopId'] = _shopId;

    batch.set(_db.collection('sales').doc(saleId), saleData);

    // 🔥 DÜZELTME: Doğru ürünün, DOĞRU ŞUBE STOĞUNDAN düşülmesi!
    for (var item in cartItems) {
      DocumentReference productRef = _db
          .collection('products')
          .doc('${_companyId}_${item.product.barcode}'); // Ortak ID
      batch.update(productRef, {
        'stocks.$_shopId': FieldValue.increment(
          -item.quantity,
        ), // Sadece bu şubenin stoğunu azalt!
      });
    }

    await batch.commit();
  }

  Stream<QuerySnapshot> getDailySales(DateTime date) {
    DateTime start = DateTime(date.year, date.month, date.day);
    DateTime end = start.add(const Duration(days: 1));

    return _db
        .collection('sales')
        .where('companyId', isEqualTo: _companyId)
        .where('shopId', isEqualTo: _shopId)
        .where('date', isGreaterThanOrEqualTo: start.toIso8601String())
        .where('date', isLessThan: end.toIso8601String())
        .snapshots();
  }
}
