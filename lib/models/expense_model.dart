// Giderler için model
class Expense {
  String id;
  String title; // Örn: Toptancı, Elektrik Faturası
  double amount;
  DateTime date;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
  });

  factory Expense.fromMap(Map<String, dynamic> map, String documentId) {
    return Expense(
      id: documentId,
      title: map['title'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      date: DateTime.parse(map['date']),
    );
  }

  Map<String, dynamic> toMap() {
    return {'title': title, 'amount': amount, 'date': date.toIso8601String()};
  }
}
