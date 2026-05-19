// lib/services/user_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gross/models/user_model.dart';
import 'package:gross/services/auth_service.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _auth = AuthService();

  // ÇALIŞANLARI GETİR
  Stream<List<IUser>> getUsers() {
    return _db.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => UserFactory.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // YENİ PERSONEL EKLE
  Future<void> addEmployee(
    String name,
    String plainPin,
    String role,
    String companyId,
    String shopId, {
    List<String> permissions = const [],
  }) async {
    String hashedPin = _auth.hashPin(plainPin);
    String id = _db.collection('users').doc().id;

    IUser newUser;
    if (role == 'patron') {
      newUser = BossUser(
        id: id,
        name: name,
        pin: hashedPin,
        companyId: companyId,
        shopId: shopId,
        permissions: permissions,
      );
    } else {
      newUser = CashierUser(
        id: id,
        name: name,
        pin: hashedPin,
        companyId: companyId,
        shopId: shopId,
      );
    }

    await _db.collection('users').doc(id).set(newUser.toMap());
  }

  // PATRON ŞİFRESİ Mİ? (Yetki Onayı İçin)
  Future<bool> verifyBossPin(String companyId, String pin) async {
    try {
      var query = await _db
          .collection('users')
          .where('companyId', isEqualTo: companyId)
          .where('role', isEqualTo: 'patron')
          .get();

      for (var doc in query.docs) {
        if (doc['pin'] == _auth.hashPin(pin)) return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Şirketteki bir personeli ismine göre bulur (Join ekranındaki transfer mantığı için)
  Future<IUser?> findUserByNameAndCompany(String companyId, String name) async {
    var query = await _db
        .collection('users')
        .where('companyId', isEqualTo: companyId)
        .where('name', isEqualTo: name)
        .get();

    if (query.docs.isNotEmpty) {
      return UserFactory.fromMap(query.docs.first.data(), query.docs.first.id);
    }
    return null;
  }

  // Personelin şubesini günceller (Transfer işlemi)
  Future<void> updateUserShopId(String userId, String newShopId) async {
    await _db.collection('users').doc(userId).update({'shopId': newShopId});
  }

  // Sadece belirli bir şirkete ait kullanıcıları dinler (Login ekranı için)
  Stream<List<IUser>> getUsersByCompanyStream(String companyId) {
    return _db
        .collection('users')
        .where('companyId', isEqualTo: companyId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => UserFactory.fromMap(doc.data(), doc.id))
              .toList();
        });
  }
}
