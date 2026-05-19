class Note {
  String id;
  String title;
  String detail;
  String type;
  bool isDone;
  DateTime date;

  // YENİ EKLENEN PRO ÖZELLİKLER
  double budget; // Gerçek bütçe rakamı
  bool isUrgent; // Acil/Önemli bayrağı

  Note({
    required this.id,
    required this.title,
    required this.detail,
    required this.type,
    required this.isDone,
    required this.date,
    this.budget = 0.0,
    this.isUrgent = false,
  });

  factory Note.fromMap(Map<String, dynamic> map, String docId) {
    return Note(
      id: docId,
      title: map['title'] ?? '',
      detail: map['detail'] ?? '',
      type: map['type'] ?? 'gorev',
      isDone: map['isDone'] ?? false,
      date: DateTime.parse(map['date']),
      budget: (map['budget'] ?? 0).toDouble(), // YENİ
      isUrgent: map['isUrgent'] ?? false, // YENİ
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'detail': detail,
      'type': type,
      'isDone': isDone,
      'date': date.toIso8601String(),
      'budget': budget, // YENİ
      'isUrgent': isUrgent, // YENİ
    };
  }
}
