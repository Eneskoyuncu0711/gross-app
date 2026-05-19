// Satışlar için model
class Sale {
  String id;
  double totalAmount;
  double totalCost;
  DateTime date;

  // Patron ekranında (Top 10) isimleri görebilmek için barkod yerine ürün İSMİ kaydedeceğiz
  Map<String, int> soldItems;
  String paymentMethod; // nakit mi, kart mı, veresiye mi

  Sale({
    required this.id,
    required this.totalAmount,
    required this.totalCost,
    required this.date,
    required this.soldItems,
    required this.paymentMethod,
  });

  factory Sale.fromMap(Map<String, dynamic> map, String documentId) {
    return Sale(
      id: documentId,
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      totalCost: (map['totalCost'] ?? 0).toDouble(),
      date: DateTime.parse(map['date']),
      soldItems: Map<String, int>.from(map['soldItems'] ?? {}),
      paymentMethod: map['paymentMethod'] ?? 'nakit',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalAmount': totalAmount,
      'totalCost': totalCost,
      'date': date.toIso8601String(),
      'soldItems': soldItems,
      'paymentMethod': paymentMethod,
    };
  }
}
