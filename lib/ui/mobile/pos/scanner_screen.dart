import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:ui'; // Frosted Glass (Bulanık arka plan) efekti için

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  late AnimationController _animationController;
  bool isScanned = false;
  bool isTorchOn = false;

  @override
  void initState() {
    super.initState();
    // BABA İŞTE LAZER ANİMASYONU: 2 saniyede bir aşağı yukarı gidip gelecek
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) {
    if (isScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String code = barcodes.first.rawValue ?? '';
      if (code.isNotEmpty) {
        setState(() => isScanned = true);

        // PRO DOKUNUŞ: Başarılı okumada cihazı tok bir şekilde titret
        HapticFeedback.heavyImpact();

        // Flaş açıksa kapatıp öyle çıkalım
        if (isTorchOn) _scannerController.toggleTorch();

        Navigator.pop(context, code);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Okuma çerçevesi boyutları
    const double scanBoxWidth = 280.0;
    const double scanBoxHeight = 180.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. EN ALT KATMAN: KAMERA GÖRÜNTÜSÜ
          MobileScanner(
            controller: _scannerController,
            fit: BoxFit.cover,
            onDetect: _handleBarcode,
          ),

          // 2. ORTA KATMAN: YARIM SAYDAM SİYAH ÖRTÜ VE ŞEFFAF DELİK (Custom Paint)
          CustomPaint(
            size: Size(
              MediaQuery.of(context).size.width,
              MediaQuery.of(context).size.height,
            ),
            painter: ScannerOverlayPainter(
              scanBoxWidth: scanBoxWidth,
              scanBoxHeight: scanBoxHeight,
            ),
          ),

          // 3. LAZER VE ÇERÇEVE
          Center(
            child: SizedBox(
              width: scanBoxWidth,
              height: scanBoxHeight,
              child: Stack(
                children: [
                  // Yeşil Köşe Çizgileri / Çerçeve
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.greenAccent.withOpacity(0.8),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  // Kırmızı Lazer Çizgisi Animasyonu
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Positioned(
                        top: (scanBoxHeight - 4) * _animationController.value,
                        left: 10,
                        right: 10,
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.redAccent.withOpacity(0.8),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // 4. ÜST YAZI
          Positioned(
            top: MediaQuery.of(context).size.height * 0.25,
            left: 0,
            right: 0,
            child: const Text(
              "Barkodu Çerçeveye Hizalayın",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                shadows: [Shadow(color: Colors.black, blurRadius: 10)],
              ),
            ),
          ),

          // 5. ÜST BUTONLAR (KAPATMA VE FLAŞ) - iOS Frosted Glass Efekti
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 15.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // KAPATMA BUTONU
                  _buildGlassButton(
                    icon: Icons.close,
                    onTap: () => Navigator.pop(context),
                  ),

                  // FLAŞ (EL FENERİ) BUTONU
                  _buildGlassButton(
                    icon: isTorchOn ? Icons.flash_on : Icons.flash_off,
                    iconColor: isTorchOn ? Colors.yellowAccent : Colors.white,
                    onTap: () {
                      _scannerController.toggleTorch();
                      setState(() => isTorchOn = !isTorchOn);
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

  // iOS Stili Bulanık (Frosted Glass) Buton Üretici
  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
        ),
      ),
    );
  }
}

// BABA İŞTE EKRANI KARARTIP ORTASINA ŞEFFAF DELİK AÇAN RESSAM (Painter)
class ScannerOverlayPainter extends CustomPainter {
  final double scanBoxWidth;
  final double scanBoxHeight;

  ScannerOverlayPainter({
    required this.scanBoxWidth,
    required this.scanBoxHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Tüm ekranı kaplayacak yarı saydam siyah boya
    final paint = Paint()..color = Colors.black.withOpacity(0.65);

    // Ortadaki deliğin koordinatları
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: scanBoxWidth,
        height: scanBoxHeight,
      ),
      const Radius.circular(16),
    );

    // Ekranın tamamını çiz, ama rect (delik) olan yeri kes (Difference)
    final path = Path.combine(
      PathOperation.difference,
      Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
      Path()..addRRect(rect),
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
