// lib/ui/mobile/inventory/inventory_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gross/models/product_model.dart';
import 'package:gross/controllers/inventory_controller.dart';
import 'package:gross/ui/mobile/pos/scanner_screen.dart';
import 'dart:math';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      context.read<InventoryController>().updateSearchQuery(
        _searchController.text.trim().toLowerCase(),
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddCategoryDialog() {
    final controller = context.read<InventoryController>();
    final TextEditingController catController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          "Yeni Kategori Ekle",
          style: TextStyle(
            color: Color(0xFF2E3192),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: catController,
          decoration: const InputDecoration(
            labelText: "Kategori Adı",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E3192),
            ),
            onPressed: () {
              if (catController.text.trim().isNotEmpty) {
                controller.addCategory(catController.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text("Ekle", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showQuickEditDialog(Product p) {
    final controller = context.read<InventoryController>();
    TextEditingController quickStockCtrl = TextEditingController(
      text: p.stock.toString(),
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          "Hızlı Stok Güncelle",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: quickStockCtrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: "Yeni Stok Adedi",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E3192),
            ),
            onPressed: () {
              Product updatedProduct = Product(
                id: p.id,
                barcode: p.barcode,
                name: p.name,
                costPrice: p.costPrice,
                margin: p.margin,
                price: p.price,
                stock: int.tryParse(quickStockCtrl.text) ?? p.stock,
                category: p.category,
              );
              controller.addProduct(updatedProduct);
              Navigator.pop(context);
            },
            child: const Text(
              "Güncelle",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showProductSheet({
    Product? existingProduct,
    bool isFromCatalog = false,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) => ProductFormSheet(
        existingProduct: existingProduct,
        isFromCatalog: isFromCatalog,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: const Text(
          "Raf ve Depo",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF1C1C1E),
          ),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: Color(0xFF2E3192), size: 28),
            onSelected: (value) =>
                context.read<InventoryController>().updateSortOption(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'Varsayılan',
                child: Text("Son Eklenenler Üstte"),
              ),
              const PopupMenuItem(value: 'A-Z', child: Text("A'dan Z'ye")),
              const PopupMenuItem(
                value: 'Önce Bitenler',
                child: Text("Stoğu Azalanlar Önce"),
              ),
              const PopupMenuItem(
                value: 'En Karlılar',
                child: Text("En Çok Kâr Bırakanlar"),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // ARAMA ÇUBUĞU
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Ürün adı veya barkod...",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon:
                    context.select<InventoryController, bool>(
                      (c) => c.searchQuery.isNotEmpty,
                    )
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          FocusScope.of(context).unfocus();
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF2F2F7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // KATEGORİ ÇUBUĞU
          Container(
            color: Colors.white,
            height: 60,
            child: Consumer<InventoryController>(
              builder: (context, controller, child) {
                List<String> displayCategories = ['Tümü', '🚨 Kritik Stok'];
                displayCategories.addAll(controller.categories);

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  itemCount: displayCategories.length + 1,
                  itemBuilder: (context, index) {
                    if (index == displayCategories.length) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: ActionChip(
                          backgroundColor: Colors.orange[100],
                          side: BorderSide.none,
                          label: const Text(
                            "+ Yeni Kategori",
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: _showAddCategoryDialog,
                        ),
                      );
                    }
                    String cat = displayCategories[index];
                    bool isSelected = controller.categoryFilter == cat;
                    bool isCritical = cat == '🚨 Kritik Stok';

                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(
                          cat,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : (isCritical ? Colors.red : Colors.black87),
                            fontWeight: isSelected || isCritical
                                ? FontWeight.bold
                                : null,
                          ),
                        ),
                        selected: isSelected,
                        showCheckmark: false,
                        side: BorderSide.none,
                        selectedColor: isCritical
                            ? Colors.red
                            : const Color(0xFF2E3192),
                        backgroundColor: const Color(0xFFF2F2F7),
                        onSelected: (bool selected) =>
                            controller.updateCategoryFilter(cat),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // ÜRÜN LİSTESİ
          Expanded(
            child: Consumer<InventoryController>(
              builder: (context, controller, child) {
                final products = controller.processedProducts;

                if (products.isEmpty)
                  return const Center(
                    child: Text(
                      "Raf boş. Ürün ekleyin.",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 120, top: 10),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final p = products[index];
                    bool isLowStock = p.stock <= 10;
                    double netProfitTl = p.price - p.costPrice;

                    return Dismissible(
                      key: Key(p.barcode),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (dir) async {
                        return await showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text(
                              "Stoktan Sil",
                              style: TextStyle(color: Colors.red),
                            ),
                            content: Text(
                              "${p.name} rafınızdan tamamen kaldırılacak.",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text(
                                  "İptal",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text(
                                  "Sil",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (dir) {
                        controller.deleteProduct(p.barcode);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Ürün silindi."),
                            backgroundColor: Colors.red,
                          ),
                        );
                      },
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        elevation: 0,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isLowStock
                                ? Colors.red.withOpacity(0.3)
                                : Colors.grey.shade200,
                            width: 1.5,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _showProductSheet(existingProduct: p),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: isLowStock
                                        ? Colors.red[50]
                                        : const Color(
                                            0xFF2E3192,
                                          ).withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    isLowStock
                                        ? Icons.warning_amber_rounded
                                        : Icons.inventory_2,
                                    color: isLowStock
                                        ? Colors.red
                                        : const Color(0xFF2E3192),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Color(0xFF1C1C1E),
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "${p.category} • Barkod: ${p.barcode}",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      if (p.costPrice > 0)
                                        Text(
                                          "Alış: ₺${p.costPrice} | Kâr: %${p.margin} | Net: ₺${netProfitTl.toStringAsFixed(2)}",
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.green.shade700,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "₺${p.price.toStringAsFixed(2)}",
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 20,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        GestureDetector(
                                          onTap: () =>
                                              controller.toggleQuickAccess(
                                                p.barcode,
                                                p.isQuickAccess,
                                              ),
                                          child: Icon(
                                            p.isQuickAccess
                                                ? Icons.star
                                                : Icons.star_border,
                                            color: p.isQuickAccess
                                                ? Colors.orange
                                                : Colors.grey[300],
                                            size: 26,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        GestureDetector(
                                          onTap: () => _showQuickEditDialog(p),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isLowStock
                                                  ? Colors.red[100]
                                                  : Colors.blue[50],
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.edit,
                                                  size: 12,
                                                  color: isLowStock
                                                      ? Colors.red.shade700
                                                      : Colors.blue.shade700,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  "Stok: ${p.stock}",
                                                  style: TextStyle(
                                                    color: isLowStock
                                                        ? Colors.red.shade700
                                                        : Colors.blue.shade700,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0),
        child: FloatingActionButton.extended(
          onPressed: () => _showProductSheet(),
          backgroundColor: const Color(0xFF2E3192),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            "Ürün Ekle",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// FORM WIDGET'I (Hızlı Kategori Ekleme Butonu Geri Döndü!)
// ----------------------------------------------------------------------
class ProductFormSheet extends StatefulWidget {
  final Product? existingProduct;
  final bool isFromCatalog;

  const ProductFormSheet({
    super.key,
    this.existingProduct,
    this.isFromCatalog = false,
  });

  @override
  State<ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<ProductFormSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _marginController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();

  String? _selectedCategory;
  late bool _isEditing;

  @override
  void initState() {
    super.initState();
    _costController.addListener(_calculatePrice);
    _marginController.addListener(_calculatePrice);

    if (widget.existingProduct != null) {
      _isEditing = !widget.isFromCatalog;
      _barcodeController.text = widget.existingProduct!.barcode;
      _nameController.text = widget.existingProduct!.name;
      _costController.text = widget.existingProduct!.costPrice > 0
          ? widget.existingProduct!.costPrice.toString()
          : '';
      _marginController.text = widget.existingProduct!.margin > 0
          ? widget.existingProduct!.margin.toString()
          : '';
      _priceController.text = widget.existingProduct!.price.toString();
      _stockController.text = widget.existingProduct!.stock.toString();
      _selectedCategory = widget.existingProduct!.category;
    } else {
      _isEditing = false;
    }
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _nameController.dispose();
    _costController.dispose();
    _marginController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  void _calculatePrice() {
    double cost = double.tryParse(_costController.text) ?? 0.0;
    double margin = double.tryParse(_marginController.text) ?? 0.0;
    if (cost > 0) {
      double calculatedPrice = cost + (cost * margin / 100);
      _priceController.value = TextEditingValue(
        text: calculatedPrice.toStringAsFixed(2),
        selection: TextSelection.collapsed(
          offset: calculatedPrice.toStringAsFixed(2).length,
        ),
      );
    }
  }

  void _generateFakeBarcode() {
    _barcodeController.text =
        "869${Random().nextInt(99999).toString().padLeft(5, '0')}";
  }

  // BABA İŞTE DİALOG BURAYA GERİ GELDİ!
  void _showAddCategoryDialog(InventoryController controller) {
    final TextEditingController catController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          "Yeni Kategori Ekle",
          style: TextStyle(
            color: Color(0xFF2E3192),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: catController,
          decoration: const InputDecoration(
            labelText: "Kategori Adı",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("İptal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E3192),
            ),
            onPressed: () {
              if (catController.text.trim().isNotEmpty) {
                String newCat = catController.text.trim();
                controller.addCategory(newCat);
                // Kullanıcı dostu olsun diye eklediğini hemen seçiyoruz
                setState(() {
                  _selectedCategory = newCat;
                });
                Navigator.pop(dialogContext);
              }
            },
            child: const Text("Ekle", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Sadece Provider'ı okuyoruz, gereksiz ekran yenilemesi yok.
    final controller = context.watch<InventoryController>();

    // Dropdown çökmesin diye güvenli kategori listesi hazırlığı
    List<String> safeCategories = List.from(controller.categories);
    if (safeCategories.isEmpty) safeCategories.add("Genel");
    if (_selectedCategory != null &&
        !safeCategories.contains(_selectedCategory)) {
      safeCategories.add(_selectedCategory!);
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEditing ? "Ürün Güncelle" : "Yeni Ürün Ekle",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),
                  if (widget.isFromCatalog)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        "Katalogdan Bulundu",
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _barcodeController,
                      enabled: !_isEditing,
                      keyboardType: TextInputType.number,
                      validator: (val) => (val == null || val.isEmpty)
                          ? "Barkod zorunlu"
                          : null,
                      decoration: InputDecoration(
                        labelText: "Barkod *",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(
                            Icons.qr_code_scanner,
                            color: Color(0xFF2E3192),
                          ),
                          onPressed: () async {
                            final nav = Navigator.of(context);
                            final messenger = ScaffoldMessenger.of(context);
                            final scannedCode = await nav.push(
                              MaterialPageRoute(
                                builder: (_) => const ScannerScreen(),
                              ),
                            );

                            if (scannedCode != null) {
                              Product? found = await controller
                                  .getProductByBarcode(scannedCode.toString());
                              if (found != null && mounted) {
                                nav.pop();
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text("Ürün bulundu!"),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              } else {
                                _barcodeController.text = scannedCode
                                    .toString();
                              }
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  if (!_isEditing) ...[
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[100],
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _generateFakeBarcode,
                      child: const Text(
                        "Üret",
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _nameController,
                validator: (val) =>
                    (val == null || val.isEmpty) ? "Ürün adı zorunlu" : null,
                decoration: InputDecoration(
                  labelText: "Ürün Adı *",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // BABA İŞTE GERİ GELEN KISIM: Kategori Dropdown ve Hızlı Ekleme Butonu Yan Yana!
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      validator: (val) =>
                          val == null ? "Lütfen kategori seçin" : null,
                      decoration: InputDecoration(
                        labelText: "Kategori Seç *",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
                      items: safeCategories
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedCategory = val),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    height: 55, // Dropdown ile hizalamak için sabit yükseklik
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.add_circle,
                        color: Colors.orange,
                        size: 28,
                      ),
                      tooltip: "Yeni Kategori Ekle",
                      onPressed: () => _showAddCategoryDialog(controller),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _costController,
                            decoration: const InputDecoration(
                              labelText: "Alış (₺)",
                              filled: true,
                              fillColor: Colors.white,
                              border: InputBorder.none,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _marginController,
                            decoration: const InputDecoration(
                              labelText: "Kâr (%)",
                              filled: true,
                              fillColor: Colors.white,
                              border: InputBorder.none,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _priceController,
                      validator: (val) =>
                          (val == null || val.isEmpty) ? "Fiyat zorunlu" : null,
                      decoration: const InputDecoration(
                        labelText: "Satış Fiyatı (₺) *",
                        filled: true,
                        fillColor: Colors.white,
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.sell, color: Colors.green),
                      ),
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _stockController,
                validator: (val) =>
                    (val == null || val.isEmpty) ? "Stok zorunlu" : null,
                decoration: InputDecoration(
                  labelText: "Mevcut Stok Adedi *",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E3192),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    if (!_formKey.currentState!.validate()) return;

                    Product newProduct = Product(
                      id: _barcodeController.text,
                      barcode: _barcodeController.text,
                      name: _nameController.text,
                      costPrice: double.tryParse(_costController.text) ?? 0.0,
                      margin: double.tryParse(_marginController.text) ?? 0.0,
                      price: double.tryParse(_priceController.text) ?? 0.0,
                      stock: int.tryParse(_stockController.text) ?? 0,
                      category: _selectedCategory ?? "Genel",
                    );

                    controller.addProduct(newProduct);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _isEditing ? "Ürün güncellendi!" : "Ürün eklendi!",
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: Text(
                    _isEditing ? "Güncelle" : "Kaydet",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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
