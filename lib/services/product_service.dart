// lib/services/product_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gross/models/product_model.dart';
import 'package:gross/services/auth_service.dart';

class ProductService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get _companyId =>
      AuthService().currentUser?.companyId ?? 'default_company';
  String get _shopId => AuthService().currentUser?.shopId ?? 'default_shop';

  Stream<List<Product>> getProducts() {
    return _db
        .collection('products')
        .where('companyId', isEqualTo: _companyId)
        // 🔥 BABA MUCİZESİ: 10.000 ürün de olsa SADECE bu şubenin rafında olanları getirir!
        .where('shopIds', arrayContains: _shopId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Product.fromMap(doc.data(), doc.id, _shopId))
              .toList(),
        );
  }

  Future<void> addProduct(Product product) async {
    String docId = '${_companyId}_${product.barcode}';

    Map<String, dynamic> data = product.toMap();
    data['companyId'] = _companyId;

    // Stok ve hızlı erişimi Map olarak kaydediyoruz
    data['stocks'] = {_shopId: product.stock};
    data['quickAccess'] = {_shopId: product.isQuickAccess};

    // 🔥 ŞUBE KALKANI: Bu ürünü hangi şubeler satıyor bilmek için diziye ekliyoruz
    data['shopIds'] = FieldValue.arrayUnion([_shopId]);

    // merge: true sayesinde diğer şubelerin verilerini ezmeden üstüne yazarız
    await _db
        .collection('products')
        .doc(docId)
        .set(data, SetOptions(merge: true));
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    try {
      // Barkod okutulduğunda DİREKT Holding havuzuna bakar.
      // Böylece Market 1, Market 2'nin ürününü okutursa sıfırdan ürün açmak yerine anında bulur!
      var doc = await _db
          .collection('products')
          .doc('${_companyId}_$barcode')
          .get();
      if (doc.exists && doc.data() != null) {
        return Product.fromMap(doc.data()!, doc.id, _shopId);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> updateProductStock(String barcode, int amount) async {
    await _db.collection('products').doc('${_companyId}_$barcode').update({
      'stocks.$_shopId': FieldValue.increment(
        amount,
      ), // Sadece bu şubenin stoğunu güncelle!
    });
  }

  Future<void> toggleQuickAccess(String barcode, bool currentStatus) async {
    await _db.collection('products').doc('${_companyId}_$barcode').update({
      'quickAccess.$_shopId': !currentStatus,
    });
  }

  // 🔥 MUCİZE 1: FİLTRELEME ARTIK DART TARAFINDA (ÇÖKMEYİ ENGELLER)
  Stream<List<Product>> getQuickProducts() {
    return _db
        .collection('products')
        .where('companyId', isEqualTo: _companyId)
        .where(
          'shopIds',
          arrayContains: _shopId,
        ) // Sadece bu şubedekileri getir
        // DİKKAT: quickAccess sorgusunu buradan kaldırdık! Firebase'i yormuyoruz.
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Product.fromMap(doc.data(), doc.id, _shopId))
              .where(
                (product) => product.isQuickAccess,
              ) // 🔥 Dart tarafında ışık hızında filtrele!
              .toList(),
        );
  }

  // 🔥 MUCİZE 2: TERTEMİZ SİLME İŞLEMİ
  Future<void> deleteProduct(String barcode) async {
    await _db.collection('products').doc('${_companyId}_$barcode').update({
      // 0 veya false yapmak yerine FieldValue.delete() ile o şubenin verisini HARİTADAN TAMAMEN SİLİYORUZ.
      'stocks.$_shopId': FieldValue.delete(),
      'quickAccess.$_shopId': FieldValue.delete(),
      'shopIds': FieldValue.arrayRemove([_shopId]),
    });
  }

  Future<void> addCategory(String categoryName) async {
    String docId = '${_companyId}_$categoryName';
    await _db.collection('categories').doc(docId).set({
      'name': categoryName,
      'companyId': _companyId,
    });
  }

  Stream<List<String>> getCategories() {
    return _db
        .collection('categories')
        .where('companyId', isEqualTo: _companyId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => doc.data()['name'] as String).toList(),
        );
  }
}
