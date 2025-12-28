import 'package:flutter/material.dart';
import 'package:auto_service/data/models/product_model.dart';
import 'package:auto_service/data/repositories/market_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ProductsProvider with ChangeNotifier {
  List<ProductModel> _products = [];
  static const String _storageKey = 'employee_products';
  bool _isLoading = false;
  String? _error;

  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Демо образцы товаров для магазина
  static final List<ProductModel> _demoProducts = [
    ProductModel(
      id: 1,
      shopId: 1,
      categoryId: 1,
      name: 'Тормозные колодки',
      nameKey: 'brake_pad',
      year: 2024,
      description: 'Высококачественные тормозные колодки',
      descriptionKey: 'brake_pad_desc',
      originalPrice: 350000.0,
      discountPrice: 250000.0,
      imageUrl: 'https://images.unsplash.com/photo-1492144534655-ae79c964c9d7',
      rating: 4.9,
      reviewCount: 203,
      category: 'Remont',
      brand: 'Brembo',
      quantity: 15,
      inStock: true,
      ownerPhone: '+998901234567',
    ),
    ProductModel(
      id: 2,
      shopId: 1,
      categoryId: 2,
      name: 'Моторное масло',
      nameKey: 'engine_oil',
      year: 2024,
      description: 'Качественное моторное масло 5W-40',
      descriptionKey: 'engine_oil_desc',
      originalPrice: 550000.0,
      discountPrice: 450000.0,
      imageUrl: 'https://images.unsplash.com/photo-1486262715619-67b85e0b08d3',
      rating: 4.8,
      reviewCount: 156,
      category: 'Dvigatel',
      brand: 'Castrol',
      quantity: 25,
      inStock: true,
      ownerPhone: '+998901234567',
    ),
    ProductModel(
      id: 3,
      shopId: 1,
      categoryId: 3,
      name: 'Аккумулятор',
      nameKey: 'battery',
      year: 2024,
      description: 'Аккумулятор 120Ah с гарантией',
      descriptionKey: 'battery_desc',
      originalPrice: 950000.0,
      discountPrice: 850000.0,
      imageUrl: 'https://images.unsplash.com/photo-1593941707874-ef25b8b4a92b',
      rating: 4.8,
      reviewCount: 278,
      category: 'Elektronika',
      brand: 'Varta',
      quantity: 8,
      inStock: true,
      ownerPhone: '+998901234567',
    ),
  ];

  /// Fetch products from API
  Future<void> fetchApiProducts({bool useDemoOnError = true}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('🛒 Загрузка товаров из backend...');
      final backendProducts = await MarketRepository().getAllProducts();

      debugPrint('✅ Получено ${backendProducts.length} товаров с backend');

      if (backendProducts.isNotEmpty) {
        _products = backendProducts
            .map(
              (p) => ProductModel(
                id: p.id,
                shopId: p.shop,
                categoryId: p.category,
                name: p.name,
                year: p.year,
                description: p.description,
                color: p.color,
                model: p.model,
                features: p.features,
                advantages: p.advantages,
                originalPrice: _parsePrice(p.originalPrice),
                discountPrice: _parsePrice(p.discountPrice),
                imageUrl: p.image,
                rating: p.rating,
                reviewCount: p.reviewCount,
                category: p.category?.toString() ?? 'General',
                brand: null,
                quantity: p.stock,
                inStock: p.stock > 0,
                ownerPhone: null,
              ),
            )
            .toList();

        debugPrint('✅ Успешно загружено ${_products.length} товаров');
      } else {
        debugPrint('⚠️ Backend вернул пустой список товаров');
        if (useDemoOnError) {
          debugPrint('📦 Использую демо товары');
          _products = List.from(_demoProducts);
        } else {
          _products = [];
        }
      }
    } catch (e) {
      debugPrint('❌ Ошибка загрузки товаров из API: $e');
      _error = e.toString();

      // Используем демо товары при ошибке
      if (useDemoOnError) {
        debugPrint('📦 Использую демо товары из-за ошибки API');
        _products = List.from(_demoProducts);
        _error = null; // Очищаем ошибку, так как у нас есть демо данные
      } else {
        _products = [];
        // Если ошибка авторизации, показываем понятное сообщение
        if (e.toString().contains('авторизация') ||
            e.toString().contains('401')) {
          _error = 'Требуется авторизация. Пожалуйста, войдите в систему.';
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  static double _parsePrice(String? price) {
    if (price == null) return 0.0;
    return double.tryParse(price) ?? 0.0;
  }

  /// Получить товары конкретного сотрудника
  List<ProductModel> getProductsByOwner(String ownerPhone) {
    return _products.where((p) => p.ownerPhone == ownerPhone).toList();
  }

  /// Получить все товары для магазина (все сотрудники)
  List<ProductModel> getAllProducts() {
    return _products;
  }

  Future<void> init() async {
    debugPrint('🚀 Инициализация ProductsProvider...');
    await fetchApiProducts();
  }

  /// Загрузить демо товары (для тестирования)
  Future<void> loadDemoProducts() async {
    debugPrint('📦 Загрузка демо товаров...');
    _products = List.from(_demoProducts);
    await _saveProducts();
    notifyListeners();
    debugPrint('✅ Загружено ${_products.length} демо товаров');
  }

  /// Сохранить товары в локальное хранилище
  Future<void> _saveProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final productsJson = jsonEncode(_products.map((p) => p.toJson()).toList());
    await prefs.setString(_storageKey, productsJson);
  }

  /// Добавить новый товар
  Future<void> addProduct(ProductModel product) async {
    _products.add(product);
    await _saveProducts();
    notifyListeners();
  }

  /// Обновить существующий товар
  Future<void> updateProduct(
    int? productId,
    ProductModel updatedProduct,
  ) async {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index != -1) {
      _products[index] = updatedProduct;
      await _saveProducts();
      notifyListeners();
    }
  }

  /// Удалить товар
  Future<void> deleteProduct(int? productId) async {
    _products.removeWhere((p) => p.id == productId);
    await _saveProducts();
    notifyListeners();
  }

  /// Проверить, существует ли товар с таким именем у данного владельца
  ProductModel? findProductByName(String name, String ownerPhone) {
    try {
      return _products.firstWhere(
        (p) =>
            p.name.toLowerCase() == name.toLowerCase() &&
            p.ownerPhone == ownerPhone,
      );
    } catch (e) {
      return null;
    }
  }

  /// Увеличить количество существующего товара
  Future<void> increaseProductQuantity(
    int? productId,
    int additionalQuantity,
  ) async {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index != -1) {
      final currentProduct = _products[index];
      final updatedProduct = currentProduct.copyWith(
        quantity: currentProduct.quantity + additionalQuantity,
      );
      _products[index] = updatedProduct;
      await _saveProducts();
      notifyListeners();
    }
  }

  /// Обновить цену существующего товара
  Future<void> updateProductPrice(int? productId, double newPrice) async {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index != -1) {
      final currentProduct = _products[index];
      final updatedProduct = currentProduct.copyWith(discountPrice: newPrice);
      _products[index] = updatedProduct;
      await _saveProducts();
      notifyListeners();
    }
  }

  /// Получить товары с низким остатком для конкретного сотрудника
  List<ProductModel> getLowStockProducts(
    String ownerPhone, {
    int threshold = 5,
  }) {
    return _products
        .where(
          (product) =>
              product.ownerPhone == ownerPhone &&
              product.quantity > 0 &&
              product.quantity <= threshold,
        )
        .toList();
  }

  /// Получить количество товаров с низким остатком для конкретного сотрудника
  int getLowStockCount(String ownerPhone, {int threshold = 5}) {
    return getLowStockProducts(ownerPhone, threshold: threshold).length;
  }

  /// Очистить ошибку
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
