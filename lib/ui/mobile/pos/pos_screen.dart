import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:gross/models/product_model.dart';
import 'package:gross/controllers/pos_controller.dart';

class PosScreen extends StatefulWidget {
  final bool isActive;
  const PosScreen({super.key, required this.isActive});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  final MobileScannerController _scannerController = MobileScannerController(
    autoStart: false,
  );
  final PageController _cartPageController = PageController();

  bool _isStartingCamera = false;

  Future<void> _safeStartCamera() async {
    if (_isStartingCamera) return;
    _isStartingCamera = true;
    try {
      await _scannerController.start();
    } catch (e) {
      debugPrint("Kamera başlatılamadı: $e");
    } finally {
      if (mounted) _isStartingCamera = false;
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.isActive) _safeStartCamera();
  }

  @override
  void didUpdateWidget(covariant PosScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      if (widget.isActive) {
        _safeStartCamera();
      } else {
        _scannerController.stop();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController.dispose();
    _cartPageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.isActive) {
      _safeStartCamera();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _scannerController.stop();
    }
  }

  void _onBarcodeDetected(BarcodeCapture capture) async {
    final controller = context.read<PosController>();

    if (controller.isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String code = barcodes.first.rawValue ?? '';
      if (code.isNotEmpty) {
        bool found = await controller.handleBarcode(code);

        if (found) {
          HapticFeedback.heavyImpact();
        } else {
          HapticFeedback.lightImpact();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ürün rafta bulunamadı!'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 1),
              ),
            );
          }
        }
        await Future.delayed(const Duration(milliseconds: 1000));
      }
    }
  }

  void _showDiscountDialog(PosController controller) {
    if (controller.activeCart.isEmpty) return;
    _scannerController.stop();

    TextEditingController discountCtrl = TextEditingController(
      text: controller.activeDiscount > 0
          ? controller.activeDiscount.toStringAsFixed(0)
          : '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("İskonto (Sepet ${controller.activeCartIndex + 1})"),
          content: TextField(
            controller: discountCtrl,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: "İndirilecek Tutar (₺)",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                controller.setDiscount(0.0);
                Navigator.pop(context);
              },
              child: const Text("Sıfırla", style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E3192),
              ),
              onPressed: () {
                controller.setDiscount(
                  double.tryParse(discountCtrl.text) ?? 0.0,
                );
                Navigator.pop(context);
              },
              child: const Text(
                "Uygula",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    ).then((_) => _safeStartCamera());
  }

  void _showVeresiyeSheet(PosController controller) {
    if (controller.activeCart.isEmpty) return;
    _scannerController.stop();
    TextEditingController searchCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Veresiye Hesabı Seç",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: searchCtrl,
                    autofocus: false,
                    decoration: InputDecoration(
                      hintText: "Müşteri Ara veya Yeni Ekle...",
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFFF2F2F7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: (val) => setSheetState(() {}),
                  ),
                  const SizedBox(height: 10),

                  StreamBuilder<List<dynamic>>(
                    stream: controller.creditAccountsStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          height: 100,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      List<dynamic> allCustomers = snapshot.data ?? [];
                      allCustomers.sort(
                        (a, b) => (b['totalDebt'] as double).compareTo(
                          a['totalDebt'] as double,
                        ),
                      );
                      List<dynamic> filteredCustomers = allCustomers
                          .where(
                            (c) => c['name'].toString().toLowerCase().contains(
                              searchCtrl.text.toLowerCase(),
                            ),
                          )
                          .toList();
                      bool exactMatch = allCustomers.any(
                        (c) =>
                            c['name'].toString().toLowerCase() ==
                            searchCtrl.text.trim().toLowerCase(),
                      );
                      bool showAddButton =
                          searchCtrl.text.trim().isNotEmpty && !exactMatch;

                      return Flexible(
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            if (showAddButton)
                              Card(
                                elevation: 0,
                                color: Colors.green[50],
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(
                                    color: Colors.green[300]!,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: Colors.green,
                                    child: Icon(
                                      Icons.person_add,
                                      color: Colors.white,
                                    ),
                                  ),
                                  title: Text(
                                    '"${searchCtrl.text.trim()}"',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  subtitle: const Text(
                                    "Yeni müşteri oluştur ve borcu yaz",
                                  ),
                                  trailing: const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  ),
                                  onTap: () {
                                    String newName = searchCtrl.text.trim();
                                    Navigator.pop(context);
                                    String newAccountId = controller
                                        .createCreditAccount(newName);
                                    _finalizeSaleUI(
                                      controller,
                                      'veresiye',
                                      customerId: newAccountId,
                                      customerName: newName,
                                    );
                                  },
                                ),
                              ),

                            ...filteredCustomers.map(
                              (customer) => Card(
                                elevation: 0,
                                color: const Color(0xFFF2F2F7),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: Color(0xFF2E3192),
                                    child: Icon(
                                      Icons.person,
                                      color: Colors.white,
                                    ),
                                  ),
                                  title: Text(
                                    customer['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1C1C1E),
                                    ),
                                  ),
                                  subtitle: Text(
                                    "Güncel Borç: ₺${customer['totalDebt']}",
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _finalizeSaleUI(
                                      controller,
                                      'veresiye',
                                      customerId: customer['id'],
                                      customerName: customer['name'],
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    ).then((_) => _safeStartCamera());
  }

  void _finalizeSaleUI(
    PosController controller,
    String method, {
    String? customerId,
    String? customerName,
  }) async {
    if (controller.activeCart.isEmpty) return;
    _scannerController.stop();

    final double finalPrice = controller.activeTotal;
    String methodText = method == 'nakit'
        ? 'Nakit'
        : method == 'kart'
        ? 'Kredi Kartı'
        : 'Veresiye (${customerName ?? "Bilinmeyen"})';

    await controller.processSale(method, customerId: customerId);

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text(
              "Satış Başarılı",
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Ödeme: $methodText",
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Text(
              "Toplam: ₺${finalPrice.toStringAsFixed(2)}",
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1C1C1E),
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E3192),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                _safeStartCamera();
              },
              child: const Text(
                "Yeni İşlem (Tamam)",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartSegment(PosController controller, int index, String title) {
    bool isActive = controller.activeCartIndex == index;
    bool hasItems = controller.carts[index].isNotEmpty;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          controller.switchCart(index);
          _cartPageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isActive
                      ? const Color(0xFF1C1C1E)
                      : Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              if (hasItems) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.orange : Colors.grey[400],
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    "${controller.carts[index].length}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartList(PosController controller, int cartIndex) {
    var currentCart = controller.carts[cartIndex];
    if (currentCart.isEmpty) {
      return const Center(
        child: Text(
          "Sepet boş. Lütfen barkod okutun.",
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: currentCart.length,
      itemBuilder: (context, index) {
        final item = currentCart[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF1C1C1E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "₺${item.product.price.toStringAsFixed(2)}",
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 35),
                      icon: const Icon(
                        Icons.remove,
                        size: 20,
                        color: Color(0xFF2E3192),
                      ),
                      onPressed: () => controller.decreaseQuantity(index),
                    ),
                    Text(
                      "${item.quantity}",
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Color(0xFF1C1C1E),
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 35),
                      icon: const Icon(
                        Icons.add,
                        size: 20,
                        color: Color(0xFF2E3192),
                      ),
                      onPressed: () => controller.increaseQuantity(index),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. KAMERA EKRANI
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.40,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () =>
                  _scannerController.stop().then((_) => _safeStartCamera()),
              child: Stack(
                children: [
                  MobileScanner(
                    controller: _scannerController,
                    onDetect: _onBarcodeDetected,
                  ),
                  Container(color: Colors.black.withOpacity(0.3)),
                  Center(
                    child: Container(
                      width: 250,
                      height: 120,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.greenAccent.withOpacity(0.8),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),

                  Positioned(
                    top: 60,
                    left: 0,
                    right: 0,
                    child: Consumer<PosController>(
                      builder: (context, controller, child) {
                        return Text(
                          controller.isProcessing
                              ? "Aranıyor..."
                              : "Barkodu Çerçeveye Hizalayın",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(color: Colors.black, blurRadius: 10),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. KASA KONSOLU
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.65,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF2F2F7),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 20,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- SEPET SEÇİCİ ---
                  Consumer<PosController>(
                    builder: (context, controller, child) {
                      return Container(
                        margin: const EdgeInsets.only(
                          top: 20,
                          left: 16,
                          right: 16,
                        ),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            _buildCartSegment(controller, 0, "Sepet 1"),
                            _buildCartSegment(
                              controller,
                              1,
                              "Sepet 2 (Beklet)",
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 15),

                  // --- HIZLI ÜRÜNLER (Güvenlik Kalkanı Eklendi) ---
                  StreamBuilder<List<Product>>(
                    stream: context.read<PosController>().quickProductsStream,
                    builder: (context, snapshot) {
                      // 🔥 BABA KALKANI: Eğer veritabanı hata fırlatırsa UYGULAMA ÇÖKMEZ!
                      if (snapshot.hasError) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            "Hızlı ürünler yüklenemedi!",
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox.shrink();
                      }

                      final quicks = snapshot.data ?? [];
                      if (quicks.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return SizedBox(
                        height: 45,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: quicks.length,
                          itemBuilder: (context, index) {
                            final p = quicks[index];
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF2E3192),
                                  elevation: 0,
                                  side: BorderSide(color: Colors.grey.shade300),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () {
                                  HapticFeedback.heavyImpact();
                                  context.read<PosController>().addToCart(p);
                                },
                                child: Text(
                                  p.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  // --- SEPET LİSTESİ ---
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Consumer<PosController>(
                        builder: (context, controller, child) {
                          return PageView(
                            controller: _cartPageController,
                            onPageChanged: (index) =>
                                controller.switchCart(index),
                            children: [
                              _buildCartList(controller, 0),
                              _buildCartList(controller, 1),
                            ],
                          );
                        },
                      ),
                    ),
                  ),

                  // --- GENEL TOPLAM VE ÖDEME BUTONLARI ---
                  Consumer<PosController>(
                    builder: (context, controller, child) {
                      return Container(
                        padding: const EdgeInsets.only(
                          left: 20,
                          right: 20,
                          top: 15,
                          bottom: 100, // Alt navigasyon barı için boşluk
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(25),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, -5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Genel Toplam",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () =>
                                          _showDiscountDialog(controller),
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          controller.activeDiscount > 0
                                              ? "- ₺${controller.activeDiscount.toStringAsFixed(2)} İskonto"
                                              : "+ İskonto Ekle",
                                          style: TextStyle(
                                            color: controller.activeDiscount > 0
                                                ? Colors.green
                                                : const Color(0xFF2E3192),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  "₺${controller.activeTotal.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF1C1C1E),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),

                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 60,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            controller.activeCart.isEmpty
                                            ? Colors.grey.shade300
                                            : const Color(0xFFF9A826),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                        ),
                                      ),
                                      onPressed: controller.activeCart.isEmpty
                                          ? null
                                          : () => _finalizeSaleUI(
                                              controller,
                                              'kart',
                                            ),
                                      child: Text(
                                        "K. Kartı",
                                        style: TextStyle(
                                          color: controller.activeCart.isEmpty
                                              ? Colors.grey.shade500
                                              : Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: SizedBox(
                                    height: 60,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            controller.activeCart.isEmpty
                                            ? Colors.grey.shade300
                                            : const Color(0xFF34C759),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                        ),
                                      ),
                                      onPressed: controller.activeCart.isEmpty
                                          ? null
                                          : () => _finalizeSaleUI(
                                              controller,
                                              'nakit',
                                            ),
                                      child: Text(
                                        "Nakit",
                                        style: TextStyle(
                                          color: controller.activeCart.isEmpty
                                              ? Colors.grey.shade500
                                              : Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: SizedBox(
                                    height: 60,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            controller.activeCart.isEmpty
                                            ? Colors.grey.shade300
                                            : const Color(0xFFFF3B30),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                        ),
                                      ),
                                      onPressed: controller.activeCart.isEmpty
                                          ? null
                                          : () =>
                                                _showVeresiyeSheet(controller),
                                      child: Text(
                                        "Veresiye",
                                        style: TextStyle(
                                          color: controller.activeCart.isEmpty
                                              ? Colors.grey.shade500
                                              : Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
