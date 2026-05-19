class CompanyModel {
  String id;
  String name; // Örn: Gross Gıda Sanayi
  List<String> partnerIds; // 3 ortağın kullanıcı ID'leri

  CompanyModel({
    required this.id,
    required this.name,
    required this.partnerIds,
  });

  Map<String, dynamic> toMap() => {'name': name, 'partnerIds': partnerIds};

  factory CompanyModel.fromMap(Map<String, dynamic> map, String id) {
    return CompanyModel(
      id: id,
      name: map['name'] ?? '',
      partnerIds: List<String>.from(map['partnerIds'] ?? []),
    );
  }
}
