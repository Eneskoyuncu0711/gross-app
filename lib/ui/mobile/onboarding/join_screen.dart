import 'package:flutter/material.dart';
import 'package:gross/services/auth_service.dart';
import 'package:gross/services/company_service.dart';
import 'package:gross/services/user_service.dart';
import 'package:gross/ui/mobile/onboarding/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gross/models/user_model.dart';

class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key});
  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  final AuthService _authService = AuthService();
  final CompanyService _companyService = CompanyService();
  final UserService _userService = UserService();

  final TextEditingController codeCtrl = TextEditingController();
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController pinCtrl = TextEditingController();
  final TextEditingController bossVerifyCtrl = TextEditingController();

  bool isPartner = false;

  void _attemptJoin() async {
    String code = codeCtrl.text.trim().toUpperCase();
    String name = nameCtrl.text.trim();
    String pin = pinCtrl.text;

    if (code.length == 6 && name.isNotEmpty && pin.length == 4) {
      // 1. Şubeyi Bul
      var shopData = await _companyService.linkDeviceByShortCode(code);
      if (shopData == null) {
        _showError("Hatalı Şube Kodu!");
        return;
      }

      // 2. Kullanıcı Şirkette Zaten Var Mı Bak! (Firebase yerine UserService kullanıldı)
      IUser? existingUser = await _userService.findUserByNameAndCompany(
        shopData['companyId']!,
        name,
      );

      if (existingUser != null) {
        // Şifre doğruysa kullanıcının şube ID'sini YENİ şubeye güncelle! (TRANSFER)
        if (_authService.login(existingUser, pin)) {
          await _userService.updateUserShopId(
            existingUser.id,
            shopData['shopId']!,
          );
          _finalizeJoin(shopData['shopId']!, shopData['companyId']!, code);
        } else {
          _showError(
            "Bu isimde bir kullanıcı zaten var. Lütfen şifrenizi kontrol edin veya farklı bir isim seçin.",
          );
        }
        return;
      }

      // 3. KULLANICI ŞİRKETTE YOKSA SIFIRDAN OLUŞTUR
      if (isPartner) {
        bool bossVerified = await _userService.verifyBossPin(
          shopData['companyId']!,
          bossVerifyCtrl.text,
        );
        if (!bossVerified) {
          _showError("Ana Patron Şifresi Hatalı!");
          return;
        }
      }

      await _userService.addEmployee(
        name,
        pin,
        isPartner ? 'patron' : 'kasiyer',
        shopData['companyId']!,
        shopData['shopId']!,
        permissions: isPartner
            ? ['view_stock', 'give_debt', 'view_finance']
            : ['view_stock', 'give_debt'],
      );

      _finalizeJoin(shopData['shopId']!, shopData['companyId']!, code);
    }
  }

  void _finalizeJoin(String sId, String cId, String shortCode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('linkedShopId', sId);
    await prefs.setString('linkedCompanyId', cId);
    await prefs.setString('shopShortCode', shortCode);

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: const Text(
          "Şubeye Katıl",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Ekibe Dahil Ol",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const Text(
              "Şube kodunu girerek profilini oluştur.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),

            _inputLabel("6 Haneli Şube Kodu"),
            TextField(
              controller: codeCtrl,
              maxLength: 6,
              textCapitalization: TextCapitalization.characters,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
                color: Color(0xFF2E3192),
              ),
              decoration: _inputDeco("ABCDEF"),
            ),
            const SizedBox(height: 20),
            _inputLabel("Adınız Soyadınız"),
            TextField(
              controller: nameCtrl,
              decoration: _inputDeco("Profil isminiz"),
            ),
            const SizedBox(height: 20),
            _inputLabel("Kendi 4 Haneli Şifreniz"),
            TextField(
              controller: pinCtrl,
              maxLength: 4,
              keyboardType: TextInputType.number,
              obscureText: true,
              decoration: _inputDeco("****"),
            ),

            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text(
                "Ben bu şubenin ortağıyım",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text("Yönetici yetkileri tanımlanır."),
              value: isPartner,
              activeColor: const Color(0xFFF39C12),
              onChanged: (val) => setState(() => isPartner = val),
            ),

            if (isPartner) ...[
              const SizedBox(height: 10),
              _inputLabel("Ana Patron Şifresi"),
              TextField(
                controller: bossVerifyCtrl,
                obscureText: true,
                decoration: _inputDeco("Kurucunun PIN kodu"),
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                "Güvenlik için bu şubeyi kuran kişinin şifresini girmelisiniz.",
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E3192),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: _attemptJoin,
                child: Text(
                  isPartner ? "Yönetici Olarak Katıl" : "Kasiyer Olarak Katıl",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    counterText: "",
  );
  Widget _inputLabel(String label) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(
      label,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    ),
  );
}
