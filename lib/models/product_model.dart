// lib/models/product_model.dart
class Product {
  String id;
  String barcode;
  String name;
  double costPrice;
  double margin;
  double price;
  int stock;
  String category;
  bool isQuickAccess;

  Product({
    required this.id,
    required this.barcode,
    required this.name,
    required this.costPrice,
    required this.margin,
    required this.price,
    required this.stock,
    required this.category,
    this.isQuickAccess = false,
  });

  // 🔥 BABA İŞTE MUCİZE BURADA!
  // UI patlamasın diye, Map'in içinden sadece aktif olan şubenin stoğunu alıp 'int' olarak veriyoruz.
  factory Product.fromMap(
    Map<String, dynamic> map,
    String docId,
    String currentShopId,
  ) {
    // Firestore'dan gelen Map'leri güvenli şekilde yakalıyoruz
    Map<String, dynamic> stocksMap = map['stocks'] != null
        ? Map<String, dynamic>.from(map['stocks'])
        : {};
    Map<String, dynamic> quickAccessMap = map['quickAccess'] != null
        ? Map<String, dynamic>.from(map['quickAccess'])
        : {};

    return Product(
      id: docId,
      barcode: map['barcode'] ?? '',
      name: map['name'] ?? '',
      costPrice: (map['costPrice'] ?? 0).toDouble(),
      margin: (map['margin'] ?? 0).toDouble(),
      price: (map['price'] ?? 0).toDouble(),
      stock: (stocksMap[currentShopId] ?? 0)
          .toInt(), // Sadece bu şubenin rafındaki stoğu al!
      category: map['category'] ?? 'Tümü',
      isQuickAccess:
          quickAccessMap[currentShopId] ??
          false, // Sadece bu şubenin kasasındaki ayarı al!
    );
  }

  // Veritabanına kaydederken ortak alanları veriyoruz (Stokları serviste map'e çevireceğiz)
  Map<String, dynamic> toMap() {
    return {
      'barcode': barcode,
      'name': name,
      'costPrice': costPrice,
      'margin': margin,
      'price': price,
      'category': category,
      // NOT: stocks ve quickAccess Map'lerini ProductService içinde 'merge' ederek ekleyeceğiz.
    };
  }
}
