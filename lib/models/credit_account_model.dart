class CreditAccount {
  String id;
  String name; // Ahmet Abi, Kuaför Ayşe vs.
  double totalDebt; // Toplam Borç Tutarı

  CreditAccount({
    required this.id,
    required this.name,
    required this.totalDebt,
  });

  factory CreditAccount.fromMap(Map<String, dynamic> map, String docId) {
    return CreditAccount(
      id: docId,
      name: map['name'] ?? '',
      totalDebt: (map['totalDebt'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'totalDebt': totalDebt};
  }
}
