// lib/controllers/app_resetter.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gross/controllers/auth_controller.dart';
import 'package:gross/controllers/pos_controller.dart';
import 'package:gross/controllers/inventory_controller.dart';
import 'package:gross/controllers/credit_controller.dart';
import 'package:gross/controllers/tasks_controller.dart';
import 'package:gross/controllers/finance_controller.dart';

class AppResetter extends StatefulWidget {
  final Widget child;

  const AppResetter({super.key, required this.child});

  static void restartApp(BuildContext context) {
    context.findAncestorStateOfType<_AppResetterState>()?.restartApp();
  }

  @override
  State<AppResetter> createState() => _AppResetterState();
}

class _AppResetterState extends State<AppResetter> {
  Key key = UniqueKey();

  void restartApp() {
    setState(() {
      key =
          UniqueKey(); // Anahtar değiştiğinde altındaki her şey yıkılıp yeniden yapılır.
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: key,
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthController()),
          ChangeNotifierProvider(create: (_) => PosController()),
          ChangeNotifierProvider(create: (_) => InventoryController()),
          ChangeNotifierProvider(create: (_) => CreditController()),
          ChangeNotifierProvider(create: (_) => TasksController()),
          ChangeNotifierProvider(create: (_) => FinanceController()),
        ],
        child: widget.child,
      ),
    );
  }
}
