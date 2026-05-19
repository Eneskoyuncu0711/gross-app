import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gross/models/user_model.dart';
import 'package:gross/services/auth_service.dart';
import 'package:gross/services/company_service.dart';
import 'package:gross/services/user_service.dart';
import 'package:gross/ui/mobile/bottombar.dart';
import 'package:gross/ui/mobile/onboarding/welcome_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final CompanyService _companyService = CompanyService();
  final UserService _userService = UserService();

  String? _linkedShopId;
  String? _linkedCompanyId;
  String _shopName = "Yükleniyor...";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkDevice();
  }

  Future<void> _checkDevice() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    String? sId = prefs.getString('linkedShopId');
    String? cId = prefs.getString('linkedCompanyId');

    if (sId == null || cId == null) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        );
      }
    } else {
      _shopName = await _companyService.getShopName(sId);
      setState(() {
        _linkedShopId = sId;
        _linkedCompanyId = cId;
        _isLoading = false;
      });
    }
  }

  void _showSwitchBranchDialogWithAuth() {
    final TextEditingController bossPinCtrl = TextEditingController();
    String error = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Yönetici İzni Gerekli"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Şubeyi değiştirmek için Master Patron şifresini girin.",
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: bossPinCtrl,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  onChanged: (val) async {
                    if (val.length == 4) {
                      bool isBoss = await _userService.verifyBossPin(
                        _linkedCompanyId!,
                        val,
                      );
                      if (isBoss) {
                        Navigator.pop(context);
                        _showSwitchBranchSheet();
                      } else {
                        setDialogState(() {
                          error = "Yetkisiz Şifre!";
                          bossPinCtrl.clear();
                        });
                      }
                    }
                  },
                ),
                if (error.isNotEmpty)
                  Text(error, style: const TextStyle(color: Colors.red)),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSwitchBranchSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return StreamBuilder<QuerySnapshot>(
          stream: _companyService.getShopsByCompanyStream(_linkedCompanyId!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            var shops = snapshot.data?.docs ?? [];

            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text(
                      "Geçiş Yapılacak Şubeyi Seçin",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Divider(height: 0),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: shops.length,
                      itemBuilder: (context, index) {
                        var shop = shops[index];
                        bool isCurrent = shop.id == _linkedShopId;

                        return ListTile(
                          leading: Icon(
                            Icons.storefront,
                            color: isCurrent
                                ? const Color(0xFF2E3192)
                                : Colors.grey,
                          ),
                          title: Text(
                            shop['name'],
                            style: TextStyle(
                              fontWeight: isCurrent
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 16,
                            ),
                          ),
                          trailing: isCurrent
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                )
                              : const Icon(Icons.arrow_forward_ios, size: 14),
                          onTap: () async {
                            if (!isCurrent) {
                              Navigator.pop(context);
                              setState(() => _isLoading = true);
                              SharedPreferences prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.setString('linkedShopId', shop.id);
                              var shopData =
                                  shop.data() as Map<String, dynamic>;
                              if (shopData.containsKey('shortCode')) {
                                await prefs.setString(
                                  'shopShortCode',
                                  shopData['shortCode'],
                                );
                              }
                              _checkDevice();
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddProfileDialog() {
    final TextEditingController bossPinCtrl = TextEditingController();
    String error = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Yönetici İzni Gerekli"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Yeni personel eklemek için Master Patron şifresini girin.",
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: bossPinCtrl,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  onChanged: (val) async {
                    if (val.length == 4) {
                      bool isBoss = await _userService.verifyBossPin(
                        _linkedCompanyId!,
                        val,
                      );
                      if (isBoss) {
                        Navigator.pop(context);
                        _showNewEmployeeForm();
                      } else {
                        setDialogState(() {
                          error = "Yetkisiz Şifre!";
                          bossPinCtrl.clear();
                        });
                      }
                    }
                  },
                ),
                if (error.isNotEmpty)
                  Text(error, style: const TextStyle(color: Colors.red)),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showNewEmployeeForm() {
    final TextEditingController nameCtrl = TextEditingController();
    final TextEditingController pinCtrl = TextEditingController();
    String selectedRole = 'kasiyer';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text(
              "Yeni Profil Ekle",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: "Ad Soyad",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: pinCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    decoration: InputDecoration(
                      labelText: "4 Haneli Şifre",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelText: "Yetki Rolü",
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'kasiyer',
                        child: Text("Kasiyer (Standart Paket)"),
                      ),
                      DropdownMenuItem(
                        value: 'patron',
                        child: Text("Yönetici (Tam Yetki)"),
                      ),
                    ],
                    onChanged: (val) =>
                        setDialogState(() => selectedRole = val!),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "İptal",
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E3192),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  if (nameCtrl.text.isNotEmpty && pinCtrl.text.length == 4) {
                    List<String> selectedPermissions = selectedRole == 'patron'
                        ? ['view_stock', 'give_debt', 'view_finance']
                        : ['view_stock', 'give_debt'];
                    await _userService.addEmployee(
                      nameCtrl.text.trim(),
                      pinCtrl.text,
                      selectedRole,
                      _linkedCompanyId!,
                      _linkedShopId!,
                      permissions: selectedPermissions,
                    );
                    if (mounted) Navigator.pop(context);
                  }
                },
                child: const Text(
                  "Oluştur",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showPinDialog(IUser user) {
    final TextEditingController pinController = TextEditingController();
    String errorMessage = '';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("Şifrenizi Girin: ${user.name}"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    autofocus: true,
                    maxLength: 4,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, letterSpacing: 8),
                    onChanged: (val) {
                      setDialogState(() => errorMessage = '');
                      if (val.length == 4) {
                        // 🔥 BABA İŞTE MUCİZE BURADA!
                        // Veritabanından gelen kimliğin üzerine, cihazdaki (ekrandaki) şubeyi ZORLA YAZDIRIYORUZ!
                        user.shopId = _linkedShopId;

                        if (_authService.login(user, val)) {
                          Navigator.pop(context);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Bottombar(),
                            ),
                          );
                        } else {
                          setDialogState(() {
                            errorMessage = 'Hatalı Şifre!';
                            pinController.clear();
                          });
                        }
                      }
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
            );
          },
        );
      },
    );
  }

  void _showLeaveShopDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "Cihazı Şubeden Çıkar",
          style: TextStyle(color: Colors.red),
        ),
        content: const Text(
          "Bu cihazın şube bağlantısı silinecek. Emin misiniz?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WelcomeScreen(),
                  ),
                  (route) => false,
                );
              }
            },
            child: const Text(
              "Evet, Ayrıl",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF2F2F7),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: StreamBuilder<List<IUser>>(
        stream: _userService.getUsersByCompanyStream(_linkedCompanyId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allUsers = snapshot.data ?? [];
          final users = allUsers
              .where((u) => u.shopId == _linkedShopId || u.role == 'patron')
              .toList();

          return SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E3192).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Color(0xFF2E3192),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _shopName.toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF2E3192),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  "KİM İŞLEM YAPIYOR?",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: Color(0xFF1C1C1E),
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  "Lütfen profilinizi seçin.",
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 30),

                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 25,
                          mainAxisSpacing: 30,
                        ),
                    itemCount: users.length + 1,
                    itemBuilder: (context, index) {
                      if (index == users.length) {
                        return GestureDetector(
                          onTap: _showAddProfileDialog,
                          child: Column(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                      width: 2,
                                      style: BorderStyle.solid,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.add,
                                      color: Colors.grey,
                                      size: 50,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                "Yeni Profil",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final user = users[index];
                      return GestureDetector(
                        onTap: () => _showPinDialog(user),
                        child: Column(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: user.role == 'patron'
                                      ? const Color(0xFF2E3192)
                                      : const Color(0xFFF9A826),
                                  borderRadius: BorderRadius.circular(25),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    user.name.substring(0, 1).toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              user.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1C1C1E),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                StreamBuilder<QuerySnapshot>(
                  stream: _companyService.getShopsByCompanyStream(
                    _linkedCompanyId!,
                  ),
                  builder: (context, shopSnapshot) {
                    if (shopSnapshot.hasData &&
                        shopSnapshot.data!.docs.length > 1) {
                      return TextButton.icon(
                        onPressed: _showSwitchBranchDialogWithAuth,
                        icon: const Icon(
                          Icons.swap_horiz,
                          color: Color(0xFF2E3192),
                          size: 20,
                        ),
                        label: const Text(
                          "Diğer Şubeye Geçiş Yap",
                          style: TextStyle(
                            color: Color(0xFF2E3192),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                TextButton.icon(
                  onPressed: _showLeaveShopDialog,
                  icon: const Icon(
                    Icons.phonelink_erase,
                    color: Colors.red,
                    size: 16,
                  ),
                  label: const Text(
                    "Cihazı Şubeden Çıkar",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
