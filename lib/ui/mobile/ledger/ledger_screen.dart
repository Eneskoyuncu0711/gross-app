import 'package:flutter/material.dart';
import 'package:gross/ui/mobile/ledger/credit_tab.dart';
import 'package:gross/ui/mobile/ledger/tasks_tab.dart';

class LedgerScreen extends StatelessWidget {
  const LedgerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // BABA DİKKAT: BURASI 2 OLACAK
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F2F7),
        appBar: AppBar(
          title: const Text(
            "Dijital Defter",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Color(0xFF1C1C1E),
            ),
          ),
          backgroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
          bottom: const TabBar(
            labelColor: Color(0xFF2E3192),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF2E3192),
            indicatorWeight: 3,
            tabs: [
              Tab(
                icon: Icon(Icons.menu_book),
                text: "Veresiye (Cari)",
              ), // 1. BAŞLIK
              Tab(
                icon: Icon(Icons.assignment_turned_in),
                text: "Operasyon",
              ), // 2. BAŞLIK
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            CreditTab(), // 1. SAYFA (Veresiye)
            TasksTab(), // 2. SAYFA (Görevler) - Başka hiçbir şey olmayacak!
          ],
        ),
      ),
    );
  }
}
