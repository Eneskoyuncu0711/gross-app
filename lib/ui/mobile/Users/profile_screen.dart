// lib/ui/mobile/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gross/controllers/app_resetter.dart';
import 'package:provider/provider.dart';
import 'package:gross/ui/mobile/onboarding/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gross/controllers/auth_controller.dart';
import 'package:gross/services/company_service.dart';

class ProfileScreen extends StatefulWidget {
  final Function(bool) onPosToggled;
  const ProfileScreen({super.key, required this.onPosToggled});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final CompanyService _companyService = CompanyService();

  bool _showPos = true;
  String _shopCode = "YÜKLENİYOR...";

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (!mounted) return;
    setState(() {
      _showPos = prefs.getBool('showPos') ?? true;
    });

    String? code = prefs.getString('shopShortCode');
    String? shopId = prefs.getString('linkedShopId');

    if ((code == null || code == "HATA") && shopId != null) {
      code = await _companyService.getOrGenerateShortCode(shopId);
      await prefs.setString('shopShortCode', code);
    }

    if (!mounted) return;
    setState(() {
      _shopCode = code ?? "HATA";
    });
  }

  Future<void> _togglePos(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showPos', value);

    if (!mounted) return;
    setState(() {
      _showPos = value;
    });
    widget.onPosToggled(value);
  }

  void _logout() async {
    final authController = context.read<AuthController>();

    // 1. Kullanıcıyı sistemden çıkar (Firebase ve AuthService temizlenir)
    authController.logout();

    // İşlemin tamamlanması için ufak bir bekleme
    await Future.delayed(const Duration(milliseconds: 150));

    // 2. TÜM UYGULAMAYI YIKIP YENİDEN YAP (Controller'lar sıfırlanır)
    if (mounted) {
      AppResetter.restartApp(context);
    }
  }

  void _showAddNewShopDialog() {
    final authController = context.read<AuthController>();
    final TextEditingController nameCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Yeni Şube Aç"),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(
            labelText: "Yeni Şube Adı (Örn: AVM Şubesi)",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("İptal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E3192),
            ),
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty) {
                final nav = Navigator.of(dialogContext);
                final mainContext = context;

                var result = await _companyService.createNewShop(
                  authController.currentUser!.companyId, // BEYİNDEN OKUDUK
                  nameCtrl.text.trim(),
                );

                nav.pop();

                if (!mounted) return;

                showDialog(
                  context: mainContext,
                  builder: (context) => AlertDialog(
                    title: const Text("Şube Başarıyla Kuruldu!"),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Yeni cihazı bu şubeye bağlamak için 'Cihaz Eşleştir' ekranına şu kodu girin:",
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 15),
                        SelectableText(
                          result['shortCode']!,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Tamam"),
                      ),
                    ],
                  ),
                );
              }
            },
            child: const Text(
              "Şube Oluştur",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePinDialog() {
    final authController = context.read<AuthController>();
    final TextEditingController pinCtrl = TextEditingController();
    String errorMessage = '';

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Şifre Değiştir"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: pinCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: "Yeni 4 Haneli Şifre",
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) {
                    if (val.length < 4) setDialogState(() => errorMessage = '');
                  },
                ),
                if (errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text("İptal"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E3192),
                ),
                onPressed: () async {
                  if (pinCtrl.text.length == 4) {
                    final nav = Navigator.of(dialogContext);
                    final messenger = ScaffoldMessenger.of(context);

                    await authController.updatePin(
                      pinCtrl.text,
                    ); // BEYNE EMİR VERDİK

                    nav.pop();
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text("Şifre başarıyla değiştirildi!"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    setDialogState(
                      () => errorMessage = 'Şifre tam 4 haneli olmalıdır!',
                    );
                  }
                },
                child: const Text(
                  "Kaydet",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final authController = context.read<AuthController>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Hesabı Sil", style: TextStyle(color: Colors.red)),
        content: const Text(
          "Kendi profilinizi tamamen silmek istiyor musunuz? (Bu işlem geri alınamaz!)",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final rootNavigator = Navigator.of(context, rootNavigator: true);
              Navigator.pop(dialogContext);

              await authController.deleteAccount(); // BEYNE EMİR VERDİK

              rootNavigator.pushAndRemoveUntil(
                PageRouteBuilder(
                  pageBuilder: (context, a1, a2) => const LoginScreen(),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
                (route) => false,
              );
            },
            child: const Text(
              "Sil ve Çık",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 BABA İŞTE BURASI: Artık Controller'ı DİNLİYORUZ!
    // Şifre güncellendiğinde UI otomatik güncellenecek!
    final authController = context.watch<AuthController>();
    final user = authController.currentUser;

    if (user == null) return const Center(child: Text("Hata"));

    bool isPatron = authController.isPatron; // Getter kullandık tertemiz!

    return Scaffold(
      appBar: AppBar(title: const Text("Hesap Yönetimi")),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
        children: [
          Card(
            color: isPatron ? const Color(0xFF2E3192) : Colors.orange,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white24,
                    child: Text(
                      user.name[0].toUpperCase(),
                      style: const TextStyle(fontSize: 40, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    user.role.toUpperCase(),
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          if (isPatron) ...[
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue),
              ),
              child: Column(
                children: [
                  const Text(
                    "ŞUBE EŞLEŞTİRME KODU",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _shopCode,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: const Icon(Icons.copy, color: Colors.blue),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _shopCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Kod Kopyalandı!"),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const Text(
                    "(Başka bir tableti bu kasaya bağlamak için kullanın)",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          SwitchListTile(
            title: const Text("POS Ekranını Kapat"),
            subtitle: const Text("Telefonda satış yapılmayacaksa gizleyin"),
            value: !_showPos,
            activeColor: Colors.red,
            onChanged: (val) => _togglePos(!val),
          ),
          const Divider(),

          if (isPatron) ...[
            ListTile(
              leading: const Icon(Icons.add_business, color: Colors.green),
              title: const Text(
                "Şirkete Yeni Şube Ekle",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: _showAddNewShopDialog,
            ),
            const Divider(),
          ],

          ListTile(
            leading: const Icon(Icons.password, color: Colors.blue),
            title: const Text("Şifre Değiştir"),
            onTap: _showChangePinDialog,
          ),

          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text(
              "Hesabımı Sil",
              style: TextStyle(color: Colors.red),
            ),
            onTap: _showDeleteAccountDialog,
          ),
          const Divider(),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              "Vardiyayı Kapat (Çıkış Yap)",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            onTap: _logout,
          ),
        ],
      ),
    );
  }
}
