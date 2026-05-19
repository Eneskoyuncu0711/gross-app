import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'package:gross/services/auth_service.dart';
import 'package:gross/ui/mobile/ledger/ledger_screen.dart';
import 'package:gross/ui/mobile/onboarding/login_screen.dart';
import 'package:gross/ui/mobile/finance/finance_screen.dart';
import 'package:gross/ui/mobile/inventory/inventory_screen.dart';
import 'package:gross/ui/mobile/pos/pos_screen.dart';
import 'package:gross/ui/mobile/Users/profile_screen.dart'; // import yolunu klasör ismine göre düzelt (küçük/büyük harf)
import 'package:shared_preferences/shared_preferences.dart';

class Bottombar extends StatefulWidget {
  final int initialIndex;
  const Bottombar({super.key, this.initialIndex = 0});

  @override
  State<Bottombar> createState() => _BottombarState();
}

class _BottombarState extends State<Bottombar> {
  int _selectedIndex = 0;
  late PageController _pageController;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  final AuthService _authService = AuthService(); // GLOBAL HAFIZA

  bool _showPos = true;
  bool _isLoading = true;

  bool get isPatron => _authService.currentUser?.role == 'patron';

  @override
  void initState() {
    super.initState();
    _loadSettings();

    // İnternet değişikliklerini dinlemeye başla
    _subscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> result,
    ) {
      if (result.contains(ConnectivityResult.none)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("İnternet bağlantınız kesildi! Offline moddasınız."),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
    });
  }

  // POS ŞALTERİNİ HAFIZADAN OKUYORUZ
  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _showPos = prefs.getBool('showPos') ?? true;
      _isLoading = false;

      // Varsayılan olarak POS ekranını aç (Kasiyer için 1, Patron için 2)
      int defaultPosIndex = isPatron ? 2 : 1;
      _selectedIndex = widget.initialIndex != 0
          ? widget.initialIndex
          : (_showPos ? defaultPosIndex : 0);

      _pageController = PageController(initialPage: _selectedIndex);
    });
  }

  // SİNYALİ YAKALADIĞIMIZ YER (DİNAMİK HESAPLAMA)
  void _handlePosToggle(bool isPosVisible) {
    setState(() {
      _showPos = isPosVisible;

      // Profil sayfası her zaman dinakmik olarak listenin en sonundadır:
      int totalTabs = (isPatron ? 1 : 0) + 1 + (isPosVisible ? 1 : 0) + 1 + 1;
      _selectedIndex = totalTabs - 1;
    });

    _pageController.jumpToPage(_selectedIndex);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void onBarTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onPageSwiped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // GÜVENLİK KONTROLÜ
    if (_authService.currentUser == null) {
      return const LoginScreen();
    }

    // AYARLARIN YÜKLENMESİNİ BEKLE
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // DİNAMİK MENÜ (Rol ve Ayarlara Göre)
    List<Widget> pages = [];
    List<GButton> tabs = [];

    // 1. FİNANS / ÖZET EKRANI (SADECE PATRON)
    if (isPatron) {
      pages.add(const FinanceScreen());
      tabs.add(const GButton(icon: FontAwesomeIcons.wallet, text: 'Finans'));
    }

    // 2. STOK EKRANI
    pages.add(const InventoryScreen());
    tabs.add(const GButton(icon: FontAwesomeIcons.boxesStacked, text: 'Stok'));

    // 3. POS EKRANI
    if (_showPos) {
      // Dinamik indeks hesaplaması: Patron ise POS 2. indekste, kasiyer ise 1. indekste olur.
      int posIndex = isPatron ? 2 : 1;

      pages.add(
        PosScreen(isActive: _selectedIndex == posIndex),
      ); // YENİ: Aktiflik durumu gönderiliyor
      tabs.add(const GButton(icon: FontAwesomeIcons.barcode, text: 'Kasa'));
    }

    // 4. DEFTER (VERESİYE & GÖREVLER)
    pages.add(const LedgerScreen());
    tabs.add(const GButton(icon: FontAwesomeIcons.bookOpen, text: 'Defter'));

    // 5. PROFİL
    pages.add(ProfileScreen(onPosToggled: _handlePosToggle));
    tabs.add(const GButton(icon: FontAwesomeIcons.userGear, text: 'Profil'));

    return PopScope(
      canPop: false,
      // Yeni Flutter sürümlerindeki onPopInvoked parametresine uyum
      onPopInvoked: (didPop) async {
        if (didPop) return;

        // Eğer ilk sayfa (Index 0) dışındaysa → İlk Sayfaya dön
        if (_selectedIndex != 0) {
          onBarTapped(0);
          return;
        }

        // Zaten ilk sayfadaysa → Uygulamadan çıkış
        bool? exitApp = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text(
              "Uygulamayı Kapat",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text(
              "Uygulamadan tamamen çıkmak istediğinize emin misiniz?",
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  "Hayır",
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Evet",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );

        if (exitApp == true) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        extendBody: true, // Menü arkasını şeffaflaştır
        body: PageView(
          controller: _pageController,
          onPageChanged: _onPageSwiped,
          physics:
              const NeverScrollableScrollPhysics(), // İndeks kaymasını önlemek için el ile kaydırma kapalı
          children: pages,
        ),
        backgroundColor: const Color(0xFFF2F2F7), // Apple Gri Arkaplanı
        bottomNavigationBar: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 25), // Jilet kenarlıklar
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                blurRadius: 20,
                color: Colors.black.withOpacity(0.08),
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 8.0,
              ),
              child: GNav(
                gap: 6,
                haptic: true, // BABA İŞTE BURASI: iOS tok titreşim hissiyatı
                activeColor: Colors.white,
                iconSize: 22,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                duration: const Duration(milliseconds: 300),
                tabBackgroundColor: const Color(0xFF2E3192),
                color: Colors.grey.shade500,
                selectedIndex: _selectedIndex,
                onTabChange: onBarTapped,
                tabs: tabs,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
