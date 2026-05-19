import 'package:flutter/material.dart';
import 'package:gross/services/company_service.dart';
import 'package:gross/ui/mobile/bottombar.dart';
import 'package:gross/ui/mobile/onboarding/join_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});
  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final CompanyService _companyService = CompanyService();
  final PageController _pageController = PageController();

  final TextEditingController companyCtrl = TextEditingController();
  final TextEditingController shopCtrl = TextEditingController();
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController pinCtrl = TextEditingController();

  bool isChain = false;
  int _currentStep = 0;

  void _finishSetup() async {
    if (shopCtrl.text.isNotEmpty &&
        nameCtrl.text.isNotEmpty &&
        pinCtrl.text.length == 4) {
      String companyName = isChain
          ? companyCtrl.text.trim()
          : shopCtrl.text.trim();

      if (isChain && companyName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Lütfen holding/şirket adını girin!"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      bool taken = await _companyService.isCompanyNameTaken(companyName);

      if (taken) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "'$companyName' isminde bir şirket zaten var. Lütfen farklı bir isim seçin veya mevcut olan şubeye giriş yapın.",
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      var ids = await _companyService.setupNewCompany(
        companyName,
        shopCtrl.text.trim(),
        nameCtrl.text.trim(),
        pinCtrl.text,
      );

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('linkedShopId', ids['shopId']!);
      await prefs.setString('linkedCompanyId', ids['companyId']!);
      await prefs.setString('shopShortCode', ids['shortCode']!);

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Bottombar()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (_currentStep > 0) {
          _pageController.previousPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.ease,
          );
        } else {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F2F7),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () {
              if (_currentStep > 0) {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.ease,
                );
              } else {
                Navigator.pop(context);
              }
            },
          ),
        ),
        body: PageView(
          controller: _pageController,
          onPageChanged: (idx) => setState(() => _currentStep = idx),
          physics: const NeverScrollableScrollPhysics(),
          children: [_buildStep1(), _buildStep2()],
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Padding(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.business_center, size: 80, color: Color(0xFF2E3192)),
          const SizedBox(height: 30),
          const Text(
            "İşletme Yapınız Nedir?",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            "Size en uygun yönetim panelini hazırlayacağız.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 40),
          _selectionCard(
            "Tek Şubeli İşletme",
            "Sadece bir dükkanım var.",
            Icons.store,
            () {
              setState(() => isChain = false);
              _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.ease,
              );
            },
          ),
          const SizedBox(height: 15),
          _selectionCard(
            "Zincir Market / Çoklu Şube",
            "Şubelerimi tek yerden yönetmek istiyorum.",
            Icons.account_tree,
            () {
              setState(() => isChain = true);
              _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.ease,
              );
            },
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFF9A826), width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const JoinScreen()),
              ),
              child: const Text(
                "Mevcut Şubeye Katıl",
                style: TextStyle(
                  color: Color(0xFFF9A826),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Son Bir Adım,",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const Text(
            "Kurulumu tamamlayalım.",
            style: TextStyle(color: Colors.grey, fontSize: 18),
          ),
          const SizedBox(height: 30),
          if (isChain) _inputLabel("Şirket/Holding Adı"),
          if (isChain)
            TextField(
              controller: companyCtrl,
              decoration: _inputDeco("Örn: Gross Şirketler Grubu"),
            ),
          const SizedBox(height: 20),
          _inputLabel("Şube Adı"),
          TextField(
            controller: shopCtrl,
            decoration: _inputDeco("Örn: Merkez Şube"),
          ),
          const SizedBox(height: 20),
          _inputLabel("Yönetici Ad Soyad"),
          TextField(controller: nameCtrl, decoration: _inputDeco("Adınız")),
          const SizedBox(height: 20),
          _inputLabel("Yönetici 4 Haneli PIN"),
          TextField(
            controller: pinCtrl,
            maxLength: 4,
            keyboardType: TextInputType.number,
            obscureText: true,
            decoration: _inputDeco("****"),
          ),
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
              onPressed: _finishSetup,
              child: const Text(
                "Sistemi Başlat",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _selectionCard(
    String title,
    String desc,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 40, color: const Color(0xFFF9A826)),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    desc,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
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
