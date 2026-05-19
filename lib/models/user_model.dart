// lib/models/user_model.dart

// 1. TEMEL SÖZLEŞME (IUser - Interface)
abstract class IUser {
  String get id;
  String get name;
  String get pin;
  String get role;
  String get companyId;
  String? get shopId;

  // 🔥 BABA MÜDAHALESİ: Şube ID'si artık sonradan değiştirilebilir!
  set shopId(String? newShopId);

  Map<String, dynamic> toMap();
}

// 2. YÖNETİCİ SÖZLEŞMESİ (IAdmin - Interface)
abstract class IAdmin {
  List<String> get permissions;
  bool get canViewFinance;
  bool get canManageUsers;
}

// 3. KASİYER SINIFI
class CashierUser implements IUser {
  @override
  final String id;
  @override
  final String name;
  @override
  final String pin;
  @override
  final String role = 'kasiyer';
  @override
  final String companyId;

  @override
  String? shopId; // 🔥 final kelimesi kaldırıldı

  CashierUser({
    required this.id,
    required this.name,
    required this.pin,
    required this.companyId,
    this.shopId,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'pin': pin,
      'role': role,
      'companyId': companyId,
      'shopId': shopId,
    };
  }
}

// 4. PATRON SINIFI
class BossUser implements IUser, IAdmin {
  @override
  final String id;
  @override
  final String name;
  @override
  final String pin;
  @override
  final String role = 'patron';
  @override
  final String companyId;

  @override
  String? shopId; // 🔥 final kelimesi kaldırıldı

  @override
  final List<String> permissions;

  BossUser({
    required this.id,
    required this.name,
    required this.pin,
    required this.companyId,
    this.shopId,
    required this.permissions,
  });

  @override
  bool get canViewFinance => permissions.contains('view_finance');

  @override
  bool get canManageUsers => permissions.contains('manage_users');

  @override
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'pin': pin,
      'role': role,
      'companyId': companyId,
      'shopId': shopId,
      'permissions': permissions,
    };
  }
}

// 5. AKILLI ÜRETİCİ (Factory Pattern)
class UserFactory {
  static IUser fromMap(Map<String, dynamic> map, String docId) {
    String role = map['role'] ?? 'kasiyer';

    if (role == 'patron') {
      return BossUser(
        id: docId,
        name: map['name'] ?? '',
        pin: map['pin'] ?? '',
        companyId: map['companyId'] ?? '',
        shopId: map['shopId'],
        permissions: List<String>.from(map['permissions'] ?? []),
      );
    } else {
      return CashierUser(
        id: docId,
        name: map['name'] ?? '',
        pin: map['pin'] ?? '',
        companyId: map['companyId'] ?? '',
        shopId: map['shopId'],
      );
    }
  }
}
