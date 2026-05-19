// lib/ui/mobile/ledger/credit_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gross/models/credit_account_model.dart';
import 'package:gross/controllers/credit_controller.dart';

class CreditTab extends StatefulWidget {
  const CreditTab({super.key});

  @override
  State<CreditTab> createState() => _CreditTabState();
}

class _CreditTabState extends State<CreditTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  void _showAddCreditAccountDialog() {
    final controller = context.read<CreditController>();
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          "Yeni Cari Hesap Aç",
          style: TextStyle(
            color: Color(0xFF1C1C1E),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: "Kişi veya Firma Adı",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.person, color: Color(0xFF2E3192)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
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
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                controller.addCreditAccount(nameController.text.trim());
                Navigator.pop(dialogContext);
              }
            },
            child: const Text(
              "Hesap Aç",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDebtDialog(CreditAccount account, bool isAddingDebt) {
    final controller = context.read<CreditController>();
    final TextEditingController amountController = TextEditingController();
    final TextEditingController noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          isAddingDebt ? "Hesaba Yaz" : "Tahsilat Al",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              account.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF2E3192),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: "Tutar (₺)",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(
                  Icons.currency_lira,
                  color: Colors.green,
                ),
              ),
            ),
            if (isAddingDebt) ...[
              const SizedBox(height: 10),
              TextField(
                controller: noteController,
                decoration: InputDecoration(
                  labelText: "Açıklama (Örn: Elden Borç)",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.edit_note),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              "İptal",
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (isAddingDebt)
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                double amount = double.tryParse(amountController.text) ?? 0;
                if (amount > 0) {
                  controller.addDebtToAccount(
                    account.id,
                    amount,
                    noteController.text.isNotEmpty
                        ? noteController.text
                        : "Elden Borç İşlemi",
                  );
                }
                Navigator.pop(dialogContext);
              },
              child: const Text(
                "Borçlandır",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF9A826),
                    ),
                    onPressed: () => _handlePayment(
                      context,
                      controller,
                      account,
                      amountController.text,
                      'kart',
                      dialogContext,
                    ),
                    child: const Text(
                      "Kredi Kartı",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: () => _handlePayment(
                      context,
                      controller,
                      account,
                      amountController.text,
                      'nakit',
                      dialogContext,
                    ),
                    child: const Text(
                      "Nakit",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _handlePayment(
    BuildContext context,
    CreditController controller,
    CreditAccount account,
    String amountText,
    String method,
    BuildContext dialogContext,
  ) async {
    double amount = double.tryParse(amountText) ?? 0;
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(dialogContext);

    String? errorMsg = await controller.processPayment(
      account.id,
      account.name,
      amount,
      method,
      account.totalDebt,
    );

    if (errorMsg != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            "Tahsilat kasaya ${method == 'kart' ? 'Kredi Kartı' : 'Nakit'} olarak işlendi.",
          ),
          backgroundColor: Colors.green,
        ),
      );
      nav.pop();
    }
  }

  // YENİ EKLENEN: HESAP SİLME ONAY DİYALOĞU
  void _showDeleteAccountConfirmation(CreditAccount account) {
    final controller = context.read<CreditController>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          "Cari Hesabı Sil",
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: Text(
          "${account.name} isimli müşteriyi tamamen silmek istiyor musunuz?\n\nUyarı: Bu işlem geri alınamaz ve müşterinin geçmiş verileri kaybolabilir.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("İptal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              controller.deleteCreditAccount(
                account.id,
              ); // Beyne silme emri ver
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Cari hesap başarıyla silindi."),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text(
              "Sil",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomerStatementSheet(CreditAccount account) {
    final controller = context.read<CreditController>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Container(
          height: MediaQuery.of(sheetContext).size.height * 0.85,
          padding: const EdgeInsets.only(top: 20, left: 15, right: 15),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF2E3192), Colors.blue[800]!],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.white24,
                      radius: 30,
                      child: Icon(Icons.person, color: Colors.white, size: 35),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            account.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            "Güncel Bakiye",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            "₺${account.totalDebt.toStringAsFixed(2)}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Hesap Hareketleri (Ekstre)",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              const Divider(thickness: 1.5),

              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: controller.getCustomerTransactionsStream(account.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text(
                          "Henüz bir hesap hareketi bulunmuyor.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        var data = snapshot.data![index];
                        bool isDebt = data['type'] == 'debt';
                        double amount = (data['amount'] ?? 0).toDouble();
                        DateTime date = DateTime.parse(data['date']);
                        String formattedDate =
                            "${date.day}/${date.month}/${date.year} - ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";

                        return Card(
                          elevation: 0,
                          color: isDebt ? Colors.red[50] : Colors.green[50],
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isDebt
                                  ? Colors.red[100]
                                  : Colors.green[100],
                              child: Icon(
                                isDebt
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                color: isDebt ? Colors.red : Colors.green,
                              ),
                            ),
                            title: Text(
                              data['detail'] ?? "İşlem Detayı Yok",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF1C1C1E),
                              ),
                            ),
                            subtitle: Text(
                              formattedDate,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                            trailing: Text(
                              "${isDebt ? '+' : '-'} ₺${amount.toStringAsFixed(2)}",
                              style: TextStyle(
                                color: isDebt ? Colors.red : Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(sheetContext).padding.bottom + 20,
                  top: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _showDebtDialog(account, true);
                        },
                        icon: const Icon(
                          Icons.add_shopping_cart,
                          color: Colors.white,
                        ),
                        label: const Text(
                          "Borç Yaz",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _showDebtDialog(account, false);
                        },
                        icon: const Icon(Icons.payments, color: Colors.white),
                        label: const Text(
                          "Tahsilat Al",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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
      backgroundColor: const Color(0xFFF2F2F7),
      body: StreamBuilder<List<CreditAccount>>(
        stream: context.read<CreditController>().creditAccountsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final accounts = snapshot.data ?? [];
          if (accounts.isEmpty) {
            return const Center(
              child: Text(
                "Kayıtlı cari hesap yok.",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 120, top: 10),
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              final account = accounts[index];
              return Card(
                elevation: 0,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  onTap: () => _showCustomerStatementSheet(account),
                  onLongPress: () => _showDeleteAccountConfirmation(
                    account,
                  ), // BABA İŞTE BURAYA UZUN BASMA EKLENDİ!
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E3192).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Color(0xFF2E3192),
                      size: 28,
                    ),
                  ),
                  title: Text(
                    account.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      "Borç: ₺${account.totalDebt.toStringAsFixed(2)}",
                      style: TextStyle(
                        color: account.totalDebt > 0
                            ? Colors.red.shade700
                            : Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.add_circle,
                          color: Colors.red.shade400,
                        ),
                        onPressed: () => _showDebtDialog(account, true),
                      ),
                      IconButton(
                        icon: Icon(Icons.payment, color: Colors.green.shade400),
                        onPressed: () => _showDebtDialog(account, false),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90.0),
        child: FloatingActionButton.extended(
          heroTag: "btn_add_credit",
          backgroundColor: const Color(0xFF2E3192),
          onPressed: _showAddCreditAccountDialog,
          icon: const Icon(Icons.person_add, color: Colors.white),
          label: const Text(
            "Yeni Müşteri",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
