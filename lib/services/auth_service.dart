// lib/services/auth_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gross/models/user_model.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // LISKOV: Sisteme giren kişi (Patron veya Kasiyer fark etmez)
  IUser? currentUser;

  // Şifre Kriptolama (Diğer servisler de bunu kullanacak)
  String hashPin(String plainPin) {
    var bytes = utf8.encode(plainPin);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // GİRİŞ KONTROLÜ
  bool login(IUser user, String enteredPin) {
    if (user.pin == hashPin(enteredPin)) {
      currentUser = user;
      return true;
    }
    return false;
  }

  // ŞİFRE GÜNCELLEME
  Future<void> updatePin(String newPin) async {
    if (currentUser != null) {
      String hashedPin = hashPin(newPin);
      await _db.collection('users').doc(currentUser!.id).update({
        'pin': hashedPin,
      });

      if (currentUser is BossUser) {
        currentUser = BossUser(
          id: currentUser!.id,
          name: currentUser!.name,
          pin: hashedPin,
          companyId: currentUser!.companyId,
          shopId: currentUser!.shopId,
          permissions: (currentUser as BossUser).permissions,
        );
      } else {
        currentUser = CashierUser(
          id: currentUser!.id,
          name: currentUser!.name,
          pin: hashedPin,
          companyId: currentUser!.companyId,
          shopId: currentUser!.shopId,
        );
      }
    }
  }

  // HESAP SİLME VE ÇIKIŞ
  Future<void> deleteAccount() async {
    if (currentUser != null) {
      await _db.collection('users').doc(currentUser!.id).delete();
      logout();
    }
  }

  void logout() {
    currentUser = null;
  }
}
