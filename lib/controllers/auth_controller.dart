// lib/controllers/auth_controller.dart
import 'package:flutter/material.dart';
import 'package:gross/models/user_model.dart';
import 'package:gross/services/auth_service.dart';

class AuthController extends ChangeNotifier {
  final AuthService _authService = AuthService();

  // --- GETTER (Sadece UI okuyabilir) ---
  IUser? get currentUser => _authService.currentUser;
  bool get isPatron => currentUser?.role == 'patron';

  // --- İŞLEMLER ---
  bool login(IUser user, String enteredPin) {
    bool success = _authService.login(user, enteredPin);
    if (success) {
      notifyListeners(); // Kullanıcı değişti, sistemi uyar!
    }
    return success;
  }

  void logout() {
    _authService.logout();
    notifyListeners(); // Çıkış yapıldı, ekranları güncelle!
  }

  Future<void> updatePin(String newPin) async {
    await _authService.updatePin(newPin);
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    await _authService.deleteAccount();
    notifyListeners();
  }
}
