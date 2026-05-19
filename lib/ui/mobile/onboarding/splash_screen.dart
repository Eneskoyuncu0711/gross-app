import 'package:flutter/material.dart';
import 'package:gross/ui/mobile/onboarding/login_screen.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gross/ui/mobile/onboarding/welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _checkRoute();
  }

  Future<void> _checkRoute() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? linkedShop = prefs.getString('linkedShopId');

    // 3 saniyelik gereksiz bekleme süresi 500 milisaniyeye düşürüldü.
    // Animasyonun çok hızlı geçmemesi için kısa bir tampon süre yeterlidir.
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      if (linkedShop != null && linkedShop.isNotEmpty) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, a1, a2) => const LoginScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) =>
                    FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, a1, a2) => const WelcomeScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) =>
                    FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _animation,
              child: Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.shopping_cart_checkout,
                  size: 70,
                  color: Color(0xFF2E3192),
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              "GROSS ERP",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                color: Color(0xFF1C1C1E),
              ),
            ),
            const SizedBox(height: 15),
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                color: Color(0xFFF39C12),
                strokeWidth: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
