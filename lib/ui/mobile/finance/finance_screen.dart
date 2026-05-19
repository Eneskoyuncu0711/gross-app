// lib/ui/mobile/finance/finance_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gross/controllers/auth_controller.dart';
import 'package:gross/controllers/finance_controller.dart';
import 'package:gross/controllers/inventory_controller.dart';
import 'package:gross/controllers/credit_controller.dart';
import 'package:gross/controllers/tasks_controller.dart';
import 'package:url_launcher/url_launcher.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Ekran çizildikten hemen sonra Beyni (Controller) uyandırıyoruz!
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthController>();
      if (auth.currentUser != null) {
        context.read<FinanceController>().init(
          auth.currentUser!.companyId,
          auth.currentUser!.shopId!,
        );
      }
    });
  }

  void _showAddExpenseDialog() {
    final auth = context.read<AuthController>();
    final financeCtrl = context.read<FinanceController>();
    final TextEditingController titleController = TextEditingController();
    final TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          "Kasadan Para Çıkışı",
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: "Nereye Verildi? (Örn: Ekmekçi)",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: amountController,
              decoration: InputDecoration(
                labelText: "Tutar (₺)",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.money, color: Colors.red),
              ),
              keyboardType: TextInputType.number,
            ),
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
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              if (titleController.text.isNotEmpty &&
                  amountController.text.isNotEmpty) {
                double amount = double.tryParse(amountController.text) ?? 0;
                financeCtrl.addExpense(
                  auth.currentUser!.name,
                  auth.currentUser!.id,
                  titleController.text.trim(),
                  amount,
                );
                Navigator.pop(dialogContext);
              }
            },
            child: const Text(
              "Kaydet",
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

  Future<void> _pickDateRange(FinanceController controller) async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: controller.selectedRange,
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF2E3192),
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      HapticFeedback.lightImpact();
      controller.setDateRange(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F2F7),
        appBar: AppBar(
          title: const Text(
            "Holding Konsolu",
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
              Tab(icon: Icon(Icons.point_of_sale), text: "Günlük Kasa"),
              Tab(icon: Icon(Icons.insights), text: "Patron Raporu"),
            ],
          ),
        ),
        body: Column(
          children: [
            _buildShopSelector(),
            Expanded(
              child: TabBarView(
                children: [_buildDailyCashTab(), _buildBossReportTab()],
              ),
            ),
          ],
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 90.0),
          child: FloatingActionButton.extended(
            heroTag: "btn_expense",
            onPressed: _showAddExpenseDialog,
            backgroundColor: Colors.red[600],
            icon: const Icon(Icons.remove_circle_outline, color: Colors.white),
            label: const Text(
              "Gider Çık",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShopSelector() {
    return Container(
      height: 65,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Consumer<FinanceController>(
        builder: (context, controller, child) {
          return ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _shopTab(controller, null, "Tüm Şubeler"),
              ...controller.shops.map(
                (s) => _shopTab(controller, s['id'], s['name']),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _shopTab(FinanceController controller, String? id, String name) {
    bool isSelected = controller.selectedShopId == id;
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          HapticFeedback.lightImpact();
          controller.setShop(id);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2E3192) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF2E3192) : Colors.transparent,
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          name,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildDailyCashTab() {
    return Consumer<FinanceController>(
      builder: (context, controller, child) {
        if (controller.isDailyLoading || controller.dailySummary == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final summary = controller.dailySummary!;
        String dateString =
            "${controller.selectedDate.day.toString().padLeft(2, '0')}/${controller.selectedDate.month.toString().padLeft(2, '0')}/${controller.selectedDate.year}";
        bool isToday =
            controller.selectedDate.day == DateTime.now().day &&
            controller.selectedDate.month == DateTime.now().month &&
            controller.selectedDate.year == DateTime.now().year;

        return Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Color(0xFF2E3192),
                      size: 20,
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      controller.changeDate(-1);
                    },
                  ),
                  Text(
                    isToday ? "Bugün ($dateString)" : dateString,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E3192),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.arrow_forward_ios,
                      color: isToday ? Colors.grey : const Color(0xFF2E3192),
                      size: 20,
                    ),
                    onPressed: isToday
                        ? null
                        : () {
                            HapticFeedback.lightImpact();
                            controller.changeDate(1);
                          },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.8,
                children: [
                  _buildSummaryCard(
                    "Toplam Ciro",
                    summary.totalCiro,
                    Colors.blue[800]!,
                    Icons.analytics,
                  ),
                  _buildSummaryCard(
                    "Kredi Kartı",
                    summary.salesByMethod['kart'] ?? 0,
                    Colors.orange[700]!,
                    Icons.credit_card,
                  ),
                  _buildSummaryCard(
                    "Net Kasa (Nakit)",
                    summary.netKasa,
                    Colors.green[700]!,
                    Icons.payments,
                  ),
                  _buildSummaryCard(
                    "Toplam Gider",
                    summary.toplamGider,
                    Colors.red[700]!,
                    Icons.trending_down,
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 5.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "İşlem Kayıtları",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            Expanded(
              child: summary.transactions.isEmpty
                  ? const Center(
                      child: Text(
                        "Bu tarihte işlem yok.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(
                        bottom: 120,
                        left: 10,
                        right: 10,
                      ),
                      itemCount: summary.transactions.length,
                      itemBuilder: (context, index) {
                        final item = summary.transactions[index];
                        String time =
                            "${item.date.hour.toString().padLeft(2, '0')}:${item.date.minute.toString().padLeft(2, '0')}";
                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: item.isIncome
                                  ? Colors.green[50]
                                  : Colors.red[50],
                              child: Icon(
                                item.isIncome
                                    ? (item.paymentMethod == 'kart'
                                          ? Icons.credit_card
                                          : Icons.payments)
                                    : Icons.money_off,
                                color: item.isIncome
                                    ? Colors.green
                                    : Colors.red,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              item.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              "$time • İşlem: ${item.createdByName}",
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            trailing: Text(
                              "${item.isIncome ? '+' : '-'} ₺${item.amount.toStringAsFixed(2)}",
                              style: TextStyle(
                                color: item.isIncome
                                    ? Colors.green[700]
                                    : Colors.red[700],
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBossReportTab() {
    return Consumer<FinanceController>(
      builder: (context, controller, child) {
        if (controller.isReportLoading || controller.bossSummary == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final summary = controller.bossSummary!;
        String rangeText =
            "${controller.selectedRange.start.day}/${controller.selectedRange.start.month} - ${controller.selectedRange.end.day}/${controller.selectedRange.end.month}";

        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 120),
          child: Column(
            children: [
              InkWell(
                onTap: () => _pickDateRange(controller),
                child: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.date_range, color: Color(0xFF2E3192)),
                      const SizedBox(width: 10),
                      Text(
                        "Tarih Aralığı: $rangeText",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1C1C1E),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green[700]!, Colors.green[500]!],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      controller.selectedShopId == null
                          ? "HOLDİNG KONSOLİDE NET KÂR"
                          : "ŞUBE NET KÂRI",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "₺${summary.netProfit.toStringAsFixed(2)}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Divider(color: Colors.white54, height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMiniStat("Ciro", summary.totalCiro),
                        _buildMiniStat("Maliyet", summary.totalCost),
                        _buildMiniStat("Gider", summary.totalExpense),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              //Yapay Zeka Analiz Kartı
              _buildAiAdviceCard(controller),

              const SizedBox(height: 10),

              const Text(
                "Finansal Dağılım",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              Container(
                height: 200,
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: summary.totalCiro > summary.totalExpense
                        ? (summary.totalCiro * 1.2 == 0
                              ? 100
                              : summary.totalCiro * 1.2)
                        : (summary.totalExpense * 1.2 == 0
                              ? 100
                              : summary.totalExpense * 1.2),
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (double value, TitleMeta meta) =>
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  value == 0 ? 'Ciro' : 'Gider',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: [
                      BarChartGroupData(
                        x: 0,
                        barRods: [
                          BarChartRodData(
                            toY: summary.totalCiro,
                            color: const Color(0xFF2E3192),
                            width: 30,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ],
                      ),
                      BarChartGroupData(
                        x: 1,
                        barRods: [
                          BarChartRodData(
                            toY: summary.totalExpense,
                            color: Colors.red,
                            width: 30,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "En Çok Satanlar (Top 10)",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),

              if (summary.top10Products.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    "Bu tarih aralığında satış verisi bulunamadı.",
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                ...summary.top10Products.asMap().entries.map((entry) {
                  int rank = entry.key + 1;
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      leading: Text(
                        "#$rank",
                        style: TextStyle(
                          color: rank <= 3
                              ? Colors.orange[800]
                              : Colors.grey[400],
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      title: Text(
                        entry.value.key,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1C1C1E),
                        ),
                      ),
                      trailing: Text(
                        "${entry.value.value} Adet",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF2E3192),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniStat(String title, double amount) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 2),
        Text(
          "₺${amount.toStringAsFixed(0)}",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    double amount,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            "₺${amount.toStringAsFixed(2)}",
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiAdviceCard(FinanceController controller) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.deepPurple.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.deepPurple),
              const SizedBox(width: 8),
              const Text(
                "Yapay Zeka Finansal Yorumu",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Colors.deepPurple,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              if (controller.aiAdvice != null && !controller.isAiLoading)
                InkWell(
                  onTap: () async {
                    HapticFeedback.lightImpact();

                    final inventoryCtrl = context.read<InventoryController>();
                    final creditCtrl = context.read<CreditController>();
                    final tasksCtrl = context.read<TasksController>();

                    // 1. Stoklar
                    final criticalList = inventoryCtrl.processedProducts
                        .where((p) => p.stock <= 10)
                        .take(3)
                        .map((p) => p.name)
                        .join(", ");

                    // 2. Veresiye Alacakları ve En Borçlu Müşteri
                    double tAlacak = 0.0;
                    String topDebtorInfo = "Yok";
                    try {
                      final accounts =
                          await creditCtrl.creditAccountsStream.first;
                      if (accounts.isNotEmpty) {
                        tAlacak = accounts.fold(
                          0.0,
                          (sum, acc) => sum + acc.totalDebt,
                        );
                        var topDebtor = accounts.reduce(
                          (a, b) => a.totalDebt > b.totalDebt ? a : b,
                        );
                        if (topDebtor.totalDebt > 0) {
                          topDebtorInfo =
                              "${topDebtor.name} (${topDebtor.totalDebt.toStringAsFixed(0)} TL)";
                        }
                      }
                    } catch (_) {}

                    // 3. Görevler / Ödemeler
                    double bOdeme = 0.0;
                    try {
                      // YZ artık UI'ın ne seçtiğine bakmıyor, doğrudan faturaları çeken yeni hattı kullanıyor!
                      final invoices = await tasksCtrl.invoicesStream.first;
                      bOdeme = invoices
                          .where((n) => !n.isDone)
                          .fold(0.0, (sum, n) => sum + n.budget);
                    } catch (_) {}

                    // YZ'yi 5 parametreyle ateşle
                    controller.generateAiAdvice(
                      kritikStoklar: criticalList.isEmpty
                          ? "Kritik stokta ürün yok."
                          : criticalList,
                      toplamAlacak: tAlacak,
                      bekleyenOdeme: bOdeme,
                      enBorcluMusteri: topDebtorInfo,
                    );
                  },
                  child: const Icon(
                    Icons.refresh,
                    color: Colors.deepPurple,
                    size: 20,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (controller.isAiLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(color: Colors.deepPurple),
              ),
            )
          else if (controller.aiAdvice == null)
            Column(
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 12.0, left: 4.0, right: 4.0),
                  child: Text(
                    "Lütfen yukarıdan analiz etmek istediğiniz tarih aralığını belirleyin, ardından yapay zeka asistanınızı çalıştırın.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.deepPurple,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Center(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      HapticFeedback.lightImpact();

                      final inventoryCtrl = context.read<InventoryController>();
                      final creditCtrl = context.read<CreditController>();
                      final tasksCtrl = context.read<TasksController>();

                      // 1. Kritik Stoklar
                      final criticalList = inventoryCtrl.processedProducts
                          .where((p) => p.stock <= 10)
                          .take(3)
                          .map((p) => p.name)
                          .join(", ");

                      // 2. Toplam Alacaklar ve En Borçlu Müşteri
                      double tAlacak = 0.0;
                      String topDebtorInfo = "Yok";
                      try {
                        final accounts =
                            await creditCtrl.creditAccountsStream.first;
                        if (accounts.isNotEmpty) {
                          tAlacak = accounts.fold(
                            0.0,
                            (sum, acc) => sum + acc.totalDebt,
                          );
                          var topDebtor = accounts.reduce(
                            (a, b) => a.totalDebt > b.totalDebt ? a : b,
                          );
                          if (topDebtor.totalDebt > 0) {
                            topDebtorInfo =
                                "${topDebtor.name} (${topDebtor.totalDebt.toStringAsFixed(0)} TL)";
                          }
                        }
                      } catch (_) {}

                      // 3. Bekleyen Giderler/Ödemeler
                      double bOdeme = 0.0;
                      try {
                        final invoices =
                            await tasksCtrl.invoicesStream.first; // DÜZELTİLDİ!
                        bOdeme = invoices
                            .where((n) => !n.isDone)
                            .fold(0.0, (sum, n) => sum + n.budget);
                      } catch (_) {}

                      // 4. Ateşle!
                      controller.generateAiAdvice(
                        kritikStoklar: criticalList.isEmpty
                            ? "Kritik stokta ürün yok."
                            : criticalList,
                        toplamAlacak: tAlacak,
                        bekleyenOdeme: bOdeme,
                        enBorcluMusteri: topDebtorInfo,
                      );
                    },
                    icon: const Icon(Icons.analytics, size: 18),
                    label: const Text("Seçili Tarihi Analiz Et"),
                  ),
                ),
              ],
            )
          else
            Builder(
              builder: (context) {
                String text = controller.aiAdvice!;
                bool hasWhatsAppTag = text.contains('[WHATSAPP_LINK]');

                String cleanText = text
                    .replaceAll('[WHATSAPP_LINK]', '')
                    .trim();

                // Butonun ismini dinamik yapmak için FutureBuilder veya basitçe await ile veriyi burada okumak yerine
                // Butonun kendi içindeki onPressed metodunda ismi yakalamıştık.
                // Arayüzde anlık göstermek için boş bir değişken tanımlayalım, butona tıklandığında yine en borçluyu bulacak.
                // Performans için arayüzü kilitlememek adına label'ı genel bırakıp veya asenkron çekebiliriz.
                // En güvenlisi genel bir başlık atıp, içinde ismi bulmaktır.

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cleanText,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (hasWhatsAppTag) ...[
                      const SizedBox(height: 15),
                      Center(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            HapticFeedback.lightImpact();

                            final creditCtrl = context.read<CreditController>();
                            String targetName = "Müşterimiz";
                            double maxDebt = 0.0;
                            try {
                              final accounts =
                                  await creditCtrl.creditAccountsStream.first;
                              if (accounts.isNotEmpty) {
                                var topDebtor = accounts.reduce(
                                  (a, b) => a.totalDebt > b.totalDebt ? a : b,
                                );
                                if (topDebtor.totalDebt > 0) {
                                  targetName = topDebtor.name;
                                  maxDebt = topDebtor.totalDebt;
                                }
                              }
                            } catch (_) {}

                            String message =
                                "Merhaba $targetName, işletmemizdeki hesabınızda ₺${maxDebt.toStringAsFixed(2)} tutarında gecikmiş bir bakiye bulunmaktadır. Müsait olduğunuzda ödemenizi rica ederiz. İyi günler dileriz!";

                            final Uri whatsappUri = Uri.parse(
                              "whatsapp://send?text=${Uri.encodeComponent(message)}",
                            );

                            try {
                              await launchUrl(whatsappUri);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "WhatsApp bulunamadı veya açılamadı!",
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.chat, size: 20),
                          label: const Text("En Borçlu Müşteriye Yaz"),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
