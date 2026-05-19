import 'package:flutter/material.dart';
import 'package:gross/ui/mobile/onboarding/setup_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7), // iOS Kırık Beyaz
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),

              // İkon ve Gölgeli Kutu (iOS Stili)
              Container(
                padding: const EdgeInsets.all(35),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.storefront,
                  size: 80,
                  color: Color(0xFF2E3192),
                ),
              ),
              const SizedBox(height: 50),

              // Başlık
              const Text(
                "Gross'a Hoş Geldiniz",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1C1C1E),
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Özel Esnaf Metni
              const Text(
                "İşletmenizin tüm yükünü hafifletmek için tasarlandı. Sadece kasanızı değil, tüm zincirinizi cebinizden yönetin.",
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF8E8E93), // iOS İkincil Gri
                  height: 1.6,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // Tek ve Dev Buton
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E3192), // Mavi
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ), // Hafif yuvarlak köşeler
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SetupScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    "Haydi Başlayalım",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
