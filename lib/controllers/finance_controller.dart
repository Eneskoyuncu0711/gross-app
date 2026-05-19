// lib/controllers/finance_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gross/models/transaction_model.dart';
import 'package:gross/models/sale_model.dart';
import 'package:gross/models/expense_model.dart';
import 'package:gross/services/report_service.dart';
import 'package:gross/models/finance_summary_model.dart';
import 'package:gross/services/ai_service.dart';

class FinanceController extends ChangeNotifier {
  final ReportService _reportService = ReportService();

  FinanceController();

  String _companyId = '';
  String? _selectedShopId;
  DateTime selectedDate = DateTime.now();
  DateTimeRange selectedRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 7)),
    end: DateTime.now(),
  );

  List<Map<String, dynamic>> shops = [];

  StreamSubscription? _salesSub;
  StreamSubscription? _expSub;

  List<Sale> _dailySales = [];
  List<Expense> _dailyExpenses = [];

  DailyCashSummary? dailySummary;
  BossReportSummary? bossSummary;

  bool isDailyLoading = true;
  bool isReportLoading = true;

  // --- YAPAY ZEKA DEĞİŞKENLERİ ---
  final AiService _aiService = AiService();
  String? aiAdvice; // AI'dan gelen tavsiye metni
  bool isAiLoading = false; // AI yükleniyor animasyonu için

  void init(String companyId, String defaultShopId) {
    if (_companyId.isNotEmpty) {
      return;
    }
    _companyId = companyId;
    _selectedShopId = defaultShopId;
    _loadShops();
    _listenDailyCash();
    _loadBossReport();
  }

  String? get selectedShopId => _selectedShopId;

  Future<void> _loadShops() async {
    shops = await _reportService.getShops(_companyId);
    notifyListeners();
  }

  void setShop(String? shopId) {
    _selectedShopId = shopId;
    _listenDailyCash();
    _loadBossReport();
  }

  void changeDate(int days) {
    selectedDate = selectedDate.add(Duration(days: days));
    _listenDailyCash();
  }

  void setDateRange(DateTimeRange range) {
    selectedRange = range;
    _loadBossReport();
  }

  Future<void> addExpense(
    String userName,
    String userId,
    String title,
    double amount,
  ) async {
    await _reportService.addExpense(
      _companyId,
      _selectedShopId ?? 'merkez',
      userName,
      userId,
      title,
      amount,
    );
  }

  void _listenDailyCash() {
    isDailyLoading = true;
    notifyListeners();

    _salesSub?.cancel();
    _expSub?.cancel();

    DateTime start = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    DateTime end = start.add(const Duration(days: 1));

    _salesSub = _reportService
        .getDailySales(_companyId, _selectedShopId, start, end)
        .listen((sales) {
          _dailySales = sales;
          _calculateDaily();
        });

    _expSub = _reportService
        .getDailyExpenses(_companyId, _selectedShopId, start, end)
        .listen((exps) {
          _dailyExpenses = exps;
          _calculateDaily();
        });
  }

  void _calculateDaily() {
    double totalCiro = 0, toplamGider = 0;
    Map<String, double> salesByMethod = {};
    List<TransactionItem> transactions = [];

    for (var s in _dailySales) {
      totalCiro += s.totalAmount;

      String method = s.paymentMethod;
      salesByMethod[method] = (salesByMethod[method] ?? 0) + s.totalAmount;

      transactions.add(
        TransactionItem(
          title: "Satış",
          amount: s.totalAmount,
          date: s.date,
          isIncome: true,
          paymentMethod: method,
          createdByName: 'Sistem',
        ),
      );
    }

    for (var e in _dailyExpenses) {
      toplamGider += e.amount;
      transactions.add(
        TransactionItem(
          title: e.title,
          amount: e.amount,
          date: e.date,
          isIncome: false,
          createdByName: 'Bilinmiyor',
        ),
      );
    }

    transactions.sort((a, b) => b.date.compareTo(a.date));

    double netKasa = (salesByMethod['nakit'] ?? 0) - toplamGider;

    dailySummary = DailyCashSummary(
      totalCiro: totalCiro,
      salesByMethod: salesByMethod,
      toplamGider: toplamGider,
      netKasa: netKasa,
      transactions: transactions,
    );

    isDailyLoading = false;
    notifyListeners();
  }

  Future<void> _loadBossReport() async {
    isReportLoading = true;
    notifyListeners();

    DateTime start = selectedRange.start;
    DateTime end = selectedRange.end.add(const Duration(days: 1));

    var sales = await _reportService.getSalesFuture(
      _companyId,
      _selectedShopId,
      start,
      end,
    );
    var exps = await _reportService.getExpensesFuture(
      _companyId,
      _selectedShopId,
      start,
      end,
    );

    double totalCiro = 0, totalCost = 0, totalExpense = 0;
    Map<String, int> productSales = {};

    for (var s in sales) {
      totalCiro += s.totalAmount;
      totalCost += s.totalCost;
      s.soldItems.forEach((key, val) {
        // 🔥 LİNTER HATASI ÇÖZÜLDÜ: if bloğu süslü paranteze alındı!
        if (!key.startsWith("Tahsilat")) {
          productSales[key] = (productSales[key] ?? 0) + val;
        }
      });
    }

    for (var e in exps) {
      totalExpense += e.amount;
    }

    var top10 = productSales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    top10 = top10.take(10).toList();

    bossSummary = BossReportSummary(
      totalCiro: totalCiro,
      totalCost: totalCost,
      totalExpense: totalExpense,
      netProfit: totalCiro - totalCost - totalExpense,
      top10Products: top10,
    );

    isReportLoading = false;
    notifyListeners();
  }

  Future<void> generateAiAdvice({
    String kritikStoklar = "Kritik stokta ürün yok.",
    double toplamAlacak = 0.0,
    double bekleyenOdeme = 0.0,
    String enBorcluMusteri = "Yok",
  }) async {
    if (bossSummary == null) return;

    if (bossSummary!.totalCiro == 0 &&
        toplamAlacak == 0 &&
        bekleyenOdeme == 0) {
      aiAdvice =
          "Patron, henüz sistemde analiz edilecek hareket yok. Kasa dolsun, buradayım!";
      notifyListeners();
      return;
    }

    isAiLoading = true;
    notifyListeners();

    String topProductsText = bossSummary!.top10Products
        .take(3)
        .map((e) => "${e.key} (${e.value} adet)")
        .join(", ");

    String prompt =
        """
    Sen bir işletmenin dijital finans asistanısın. Açık, net, anlaşılır ve çözüm odaklı bir dil kullan. 
    UYARI: "Likidite, revize, operasyonel, öngörülmektedir" gibi ağır kurumsal terimler kullanma. Aynı zamanda "Patron, halledelim, süper, kanka" gibi aşırı samimi, günlük konuşma ağzından da kesinlikle uzak dur. Tam bir profesyonel yazılım asistanı tonunda ol. KESİNLİKLE EMOJİ KULLANMA.
    
    Veriler:
    - Kasa (Ciro): ₺${bossSummary!.totalCiro.toStringAsFixed(2)}
    - Net Kâr: ₺${bossSummary!.netProfit.toStringAsFixed(2)}
    - Bekleyen Faturalar/Giderler: ₺${bekleyenOdeme.toStringAsFixed(2)}
    - Toplam Veresiye Alacağı: ₺${toplamAlacak.toStringAsFixed(2)}
    - En Yüksek Borçlu Müşteri: $enBorcluMusteri
    - Çok Satanlar: $topProductsText
    - Kritik Stok: $kritikStoklar

    Lütfen bu verileri aşağıdaki 3 başlık altında, kısa paragraflar halinde yorumla:
    
    Finansal Durum ve Faturalar:
    (Kasa durumu ile bekleyen faturaları karşılaştır. Kasadaki para faturalara yetmiyorsa net bir şekilde nakit açığı uyarısı yap. Cümleleri kısa tut.)
    
    Stok ve Satış Analizi:
    (Çok satan ürünlerin durumunu belirt. Kritik stoktaki ürünler varsa sipariş geçilmesi gerektiğini vurgula.)
    
    Aksiyon Önerisi:
    (Nakit ihtiyacı varsa, en yüksek borcu olan müşteriden tahsilat yapılmasını öner. Müşteriye gönderilecek mesajın metnini SEN YAZMA! Sadece ne yapılması gerektiğini söyle ve metnin KESİN OLARAK en sonuna [WHATSAPP_LINK] etiketini yapıştırıp bırak.)
    """;

    try {
      aiAdvice = await _aiService.getFinancialAdvice(prompt);
    } catch (e) {
      aiAdvice = "Patron, internette bir sorun var, piyasaya bağlanamadım.";
    }

    isAiLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _salesSub?.cancel();
    _expSub?.cancel();
    super.dispose();
  }
}
