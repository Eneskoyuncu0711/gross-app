// lib/controllers/inventory_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gross/models/product_model.dart';
import 'package:gross/services/product_service.dart';

class InventoryController extends ChangeNotifier {
  final ProductService _productService = ProductService();

  // --- HAM VERİLER (UI BUNLARI GÖRMEZ) ---
  List<Product> _rawProducts = [];
  List<String> _rawCategories = [];

  // Stream Abonelikleri (Arka planda Firebase'i dinler)
  StreamSubscription? _productsSub;
  StreamSubscription? _catsSub;

  // --- FİLTRE VE ARAMA DURUMLARI ---
  String searchQuery = '';
  String sortOption = 'Varsayılan';
  String categoryFilter = 'Tümü';

  InventoryController() {
    _initStreams();
  }

  // BABA İŞTE BURASI: UI'dan StreamBuilder ameleliğini aldık, beyin kendisi dinliyor!
  void _initStreams() {
    _productsSub = _productService.getProducts().listen((data) {
      _rawProducts = data;
      notifyListeners();
    });

    _catsSub = _productService.getCategories().listen((data) {
      _rawCategories = data;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _productsSub?.cancel();
    _catsSub?.cancel();
    super.dispose();
  }

  // --- UI SADECE BU İKİSİNİ OKUR ---
  List<String> get categories => _rawCategories;

  // UI İÇİNDEKİ SPAGETTİ BURAYA GELDİ: Tertemiz get fonksiyonu
  List<Product> get processedProducts {
    List<Product> result = List.from(_rawProducts);

    if (searchQuery.isNotEmpty) {
      result = result
          .where(
            (p) =>
                p.name.toLowerCase().contains(searchQuery) ||
                p.barcode.contains(searchQuery),
          )
          .toList();
    }

    if (categoryFilter == '🚨 Kritik Stok') {
      result = result.where((p) => p.stock <= 10).toList();
    } else if (categoryFilter != 'Tümü') {
      result = result.where((p) => p.category == categoryFilter).toList();
    }

    switch (sortOption) {
      case 'A-Z':
        result.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
      case 'Önce Bitenler':
        result.sort((a, b) => a.stock.compareTo(b.stock));
        break;
      case 'En Karlılar':
        result.sort(
          (a, b) => (b.price - b.costPrice).compareTo(a.price - a.costPrice),
        );
        break;
      case 'Varsayılan':
      default:
        result = result.reversed.toList();
        break;
    }
    return result;
  }

  // --- DURUM GÜNCELLEYİCİLER ---
  void updateSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  void updateSortOption(String option) {
    sortOption = option;
    notifyListeners();
  }

  void updateCategoryFilter(String category) {
    categoryFilter = category;
    notifyListeners();
  }

  // --- SERVİS ÇAĞRILARI ---
  Future<void> addCategory(String name) => _productService.addCategory(name);
  Future<void> addProduct(Product p) => _productService.addProduct(p);
  Future<void> deleteProduct(String barcode) =>
      _productService.deleteProduct(barcode);
  Future<void> toggleQuickAccess(String barcode, bool status) =>
      _productService.toggleQuickAccess(barcode, status);
  Future<Product?> getProductByBarcode(String barcode) =>
      _productService.getProductByBarcode(barcode);
}
