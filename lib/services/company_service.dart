// lib/services/company_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gross/models/user_model.dart';
import 'package:gross/services/auth_service.dart'; // Şifreleme (hashPin) için
import 'dart:math';

class CompanyService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _auth = AuthService(); // Yardımcı araçlar için

  // KISA KOD ÜRETİCİ
  String _generateShortCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    Random rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }

  // YENİ ŞİRKET VE İLK PATRON KURULUMU
  Future<Map<String, String>> setupNewCompany(
    String companyName,
    String shopName,
    String adminName,
    String plainPin,
  ) async {
    WriteBatch batch = _db.batch();
    String companyId = _db.collection('companies').doc().id;
    String shopId = _db.collection('shops').doc().id;
    String userId = _db.collection('users').doc().id;
    String shortCode = _generateShortCode();

    batch.set(_db.collection('companies').doc(companyId), {
      'name': companyName,
      'partnerIds': [userId],
    });

    batch.set(_db.collection('shops').doc(shopId), {
      'companyId': companyId,
      'name': shopName,
      'shortCode': shortCode,
    });

    BossUser adminUser = BossUser(
      id: userId,
      name: adminName,
      pin: _auth.hashPin(plainPin),
      companyId: companyId,
      shopId: shopId,
      permissions: ['view_stock', 'give_debt', 'view_finance', 'manage_users'],
    );

    batch.set(_db.collection('users').doc(userId), adminUser.toMap());
    await batch.commit();

    return {'shopId': shopId, 'companyId': companyId, 'shortCode': shortCode};
  }

  // İSİM KONTROLÜ
  Future<bool> isCompanyNameTaken(String name) async {
    var query = await _db
        .collection('companies')
        .where('name', isEqualTo: name)
        .get();
    return query.docs.isNotEmpty;
  }

  // YENİ ŞUBE AÇMA
  Future<Map<String, String>> createNewShop(
    String companyId,
    String shopName,
  ) async {
    String shopId = _db.collection('shops').doc().id;
    String shortCode = _generateShortCode();
    await _db.collection('shops').doc(shopId).set({
      'companyId': companyId,
      'name': shopName,
      'shortCode': shortCode,
    });
    return {'shopId': shopId, 'shortCode': shortCode};
  }

  // Şube adını ID'den bulur (Login ekranı karşılama yazısı için)
  Future<String> getShopName(String shopId) async {
    try {
      var doc = await _db.collection('shops').doc(shopId).get();
      return doc.exists
          ? (doc.data()?['name'] ?? 'Bilinmeyen Şube')
          : 'Bilinmeyen Şube';
    } catch (e) {
      return "Bağlantı Hatası";
    }
  }

  // Holdinge bağlı şubeleri dinler (Login ekranı şube değiştirme diyaloğu için)
  Stream<QuerySnapshot> getShopsByCompanyStream(String companyId) {
    return _db
        .collection('shops')
        .where('companyId', isEqualTo: companyId)
        .snapshots();
  }

  // Şubenin kısa kodunu getirir, yoksa yeni üretip veritabanına kaydeder
  Future<String> getOrGenerateShortCode(String shopId) async {
    try {
      var doc = await _db.collection('shops').doc(shopId).get();
      if (doc.exists) {
        if (doc.data()!.containsKey('shortCode')) {
          return doc['shortCode'];
        } else {
          // Eski dükkansa ve kodu yoksa yeni kod üret ve kaydet
          String newCode = _generateShortCode();
          await _db.collection('shops').doc(shopId).update({
            'shortCode': newCode,
          });
          return newCode;
        }
      }
      return "HATA";
    } catch (e) {
      return "BAĞLANTI YOK";
    }
  }

  // CİHAZ EŞLEŞTİRME (KISA KOD İLE)
  Future<Map<String, String>?> linkDeviceByShortCode(String shortCode) async {
    try {
      var query = await _db
          .collection('shops')
          .where('shortCode', isEqualTo: shortCode)
          .get();
      if (query.docs.isNotEmpty) {
        var doc = query.docs.first;
        return {
          'shopId': doc.id,
          'companyId': doc['companyId'],
          'name': doc['name'],
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // CİHAZ EŞLEŞTİRME (ID İLE)
  Future<bool> linkDeviceToShop(String shopId) async {
    try {
      var shopDoc = await _db.collection('shops').doc(shopId).get();
      return shopDoc.exists;
    } catch (e) {
      return false;
    }
  }
}
