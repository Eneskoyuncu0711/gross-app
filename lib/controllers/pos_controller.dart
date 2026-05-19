// lib/controllers/pos_controller.dart

import 'package:flutter/material.dart';
import 'package:gross/models/product_model.dart';
import 'package:gross/models/cart_item_model.dart';
import 'package:gross/services/finance_service.dart';
import 'package:gross/services/product_service.dart';
import 'package:gross/services/sale_service.dart';

// ChangeNotifier: Bu sınıf dinlenebilir (Provider) bir sınıftır.
class PosController extends ChangeNotifier {
  // Artık DatabaseService yok, her işin uzmanı var!
  final ProductService _productService = ProductService();
  final SaleService _saleService = SaleService();
  final FinanceService _financeService = FinanceService();

  // --- STATE (DURUMLAR) ---
  List<List<CartItem>> carts = [[], []];
  List<double> discountAmounts = [0.0, 0.0];
  int activeCartIndex = 0;
  bool isProcessing = false;

  // --- GETTER (OKUYUCULAR) ---
  List<CartItem> get activeCart => carts[activeCartIndex];
  double get activeDiscount => discountAmounts[activeCartIndex];

  // GENEL TOPLAM HESAPLAMA
  double get activeTotal {
    double subtotal = activeCart.fold(
      0,
      (sum, item) => sum + (item.product.price * item.quantity),
    );
    double finalTotal = subtotal - activeDiscount;
    return finalTotal > 0 ? finalTotal : 0.0;
  }

  // --- SEPET İŞLEMLERİ ---

  // Sepet Değiştirme
  void switchCart(int index) {
    activeCartIndex = index;
    notifyListeners();
  }

  // İndirim Uygulama
  void setDiscount(double amount) {
    discountAmounts[activeCartIndex] = amount;
    notifyListeners();
  }

  // Sepete Ürün Ekleme
  void addToCart(Product product) {
    var existingItem = activeCart
        .where((item) => item.product.barcode == product.barcode)
        .firstOrNull;

    if (existingItem != null) {
      existingItem.quantity++;
    } else {
      activeCart.add(CartItem(product: product));
    }
    notifyListeners();
  }

  // Ürün Adedini Artırma
  void increaseQuantity(int itemIndex) {
    activeCart[itemIndex].quantity++;
    notifyListeners();
  }

  // Ürün Adedini Azaltma veya Silme
  void decreaseQuantity(int itemIndex) {
    if (activeCart[itemIndex].quantity > 1) {
      activeCart[itemIndex].quantity--;
    } else {
      activeCart.removeAt(itemIndex);
      if (activeCart.isEmpty) {
        discountAmounts[activeCartIndex] = 0.0;
      }
    }
    notifyListeners();
  }

  // --- VERİTABANI İŞLEMLERİ (ASYNC) ---

  // Barkod Okutulduğunda Çalışacak Metod
  Future<bool> handleBarcode(String code) async {
    if (isProcessing) return false;

    isProcessing = true;
    notifyListeners();

    // DOĞRUSU: Ürün arama işini ProductService yapar
    Product? foundProduct = await _productService.getProductByBarcode(code);

    isProcessing = false;

    if (foundProduct != null) {
      addToCart(foundProduct);
      return true;
    } else {
      notifyListeners();
      return false;
    }
  }

  // Satışı Tamamlama (Veritabanına Yazma)
  Future<void> processSale(String method, {String? customerId}) async {
    if (activeCart.isEmpty) return;

    final double finalPrice = activeTotal;
    final List<CartItem> cartSnapshot = List.from(activeCart);

    // DOĞRUSU: Satış kaydetme işini SaleService yapar
    await _saleService.saveSale(cartSnapshot, method, finalPrice);

    // Veresiye ise borcu hesaba yaz
    if (method == 'veresiye' && customerId != null) {
      String cartDetail = cartSnapshot
          .map((item) => "${item.quantity}x ${item.product.name}")
          .join("\n");

      // DOĞRUSU: Borç/Finans işlemlerini FinanceService yapar
      await _financeService.addDebtToAccount(
        customerId,
        finalPrice,
        note: cartDetail,
      );
    }

    // Sepeti Temizle
    carts[activeCartIndex].clear();
    discountAmounts[activeCartIndex] = 0.0;
    notifyListeners();
  }

  // --- UI VERİ BESLEMELERİ (STREAMS) ---

  // DOĞRUSU: Hızlı ürünleri ProductService getirir
  Stream<List<Product>> get quickProductsStream =>
      _productService.getQuickProducts();

  // DOĞRUSU: Veresiye hesaplarını FinanceService getirir
  Stream<List<dynamic>> get creditAccountsStream =>
      _financeService.getCreditAccounts();

  // DOĞRUSU: Veresiye müşterisi oluşturmayı FinanceService yapar
  String createCreditAccount(String name) {
    return _financeService.addCreditAccount(name);
  }
}
