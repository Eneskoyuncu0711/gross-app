import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gross/controllers/app_resetter.dart';
import 'package:gross/firebase_options.dart';
import 'package:gross/ui/mobile/onboarding/splash_screen.dart';

void main() async {
  // 1. Flutter motorunun tam yüklendiğinden emin ol
  WidgetsFlutterBinding.ensureInitialized();

  // Uygulama ayağa kalkmadan şifreyi ekleme
  await dotenv.load(fileName: ".env");

  // 2. ÖNCE FİREBASE'İ AYAĞA KALDIR (Uygulama kimliğini tanıt)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 3. SONRA AYARLARI YAP (Uygulama artık tanındığı için ayar yapabilirsin)
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true, // Yerel önbelleği aç
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED, // Faturayı koru
  );

  runApp(const AppResetter(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gross POS',
      home: SplashScreen(),
    );
  }
}
