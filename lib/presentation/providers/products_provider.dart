import 'package:flutter/material.dart';
import 'package:auto_service/data/models/product_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ProductsProvider with ChangeNotifier {
  List<ProductModel> _products = [];
  static const String _storageKey = 'employee_products';

  List<ProductModel> get products => _products;

  /// Получить товары конкретного сотрудника
  List<ProductModel> getProductsByOwner(String ownerPhone) {
    return _products.where((p) => p.ownerPhone == ownerPhone).toList();
  }

  /// Получить все товары для магазина (все сотрудники)
  List<ProductModel> getAllProducts() {
    return _products;
  }

  Future<void> init() async {
    await _loadProducts();
    await _createDemoProductsIfNeeded();
  }

  /// Создать демо-товары для сотрудников (только при первом запуске)
  Future<void> _createDemoProductsIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final demoCreated = prefs.getBool('demo_products_created') ?? false;

    if (!demoCreated) {
      // Демо-товары для первого сотрудника (+998901234567)
      final demoProducts1 = [
        ProductModel(
          id: 'demo_emp1_1',
          name: 'Тормозные диски Brembo',
          description:
              'Высококачественные тормозные диски для спортивных автомобилей',
          price: 850000,
          imageUrl: 'https://picsum.photos/400/300?random=101',
          rating: 4.8,
          reviewCount: 15,
          category: 'Remont',
          brand: 'Brembo',
          inStock: true,
          quantity: 2,
          ownerPhone: '+998901234567',
        ),
        ProductModel(
          id: 'demo_emp1_2',
          name: 'Свечи зажигания NGK',
          description: 'Комплект из 4 свечей зажигания премиум класса',
          price: 180000,
          imageUrl: 'https://picsum.photos/400/300?random=102',
          rating: 4.6,
          reviewCount: 28,
          category: 'Dvigatel',
          brand: 'NGK',
          inStock: true,
          quantity: 25,
          ownerPhone: '+998901234567',
        ),
        ProductModel(
          id: 'demo_emp1_3',
          name: 'Масляный фильтр Mann',
          description: 'Оригинальный масляный фильтр для немецких автомобилей',
          price: 95000,
          imageUrl: 'https://picsum.photos/400/300?random=103',
          rating: 4.7,
          reviewCount: 42,
          category: 'Dvigatel',
          brand: 'Mann',
          inStock: true,
          quantity: 35,
          ownerPhone: '+998901234567',
        ),
      ];

      // Демо-товары для второго сотрудника (+998903456789)
      final demoProducts2 = [
        ProductModel(
          id: 'demo_emp2_1',
          name: 'Аккумулятор Varta Blue',
          description: 'Надежный аккумулятор 60Ah с гарантией 2 года',
          price: 680000,
          imageUrl: 'https://picsum.photos/400/300?random=104',
          rating: 4.5,
          reviewCount: 33,
          category: 'Elektronika',
          brand: 'Varta',
          inStock: true,
          quantity: 4,
          ownerPhone: '+998903456789',
        ),
        ProductModel(
          id: 'demo_emp2_2',
          name: 'Передний бампер',
          description: 'Универсальный передний бампер, черный пластик',
          price: 1200000,
          imageUrl: 'https://picsum.photos/400/300?random=105',
          rating: 4.3,
          reviewCount: 8,
          category: 'Kuzov',
          brand: null,
          inStock: true,
          quantity: 5,
          ownerPhone: '+998903456789',
        ),
        ProductModel(
          id: 'demo_emp2_3',
          name: 'Воздушный фильтр K&N',
          description:
              'Спортивный воздушный фильтр многоразового использования',
          price: 320000,
          imageUrl: 'https://picsum.photos/400/300?random=106',
          rating: 4.9,
          reviewCount: 56,
          category: 'Dvigatel',
          brand: 'K&N',
          inStock: true,
          quantity: 18,
          ownerPhone: '+998903456789',
        ),
      ];

      // Добавляем все демо-товары
      _products.addAll([...demoProducts1, ...demoProducts2]);
      await _saveProducts();
      await prefs.setBool('demo_products_created', true);
      notifyListeners();
    }
  }

  /// Загрузить товары из локального хранилища
  Future<void> _loadProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final productsJson = prefs.getString(_storageKey);

    if (productsJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(productsJson);
        _products = decoded
            .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
            .toList();
        notifyListeners();
      } catch (e) {
        _products = [];
      }
    }
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
    String productId,
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
  Future<void> deleteProduct(String productId) async {
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
    String productId,
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
  Future<void> updateProductPrice(String productId, double newPrice) async {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index != -1) {
      final currentProduct = _products[index];
      final updatedProduct = currentProduct.copyWith(price: newPrice);
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

  /// Сбросить демо-данные (для тестирования)
  Future<void> resetDemoData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('demo_products_created');
    _products.clear();
    await _saveProducts();
    await _createDemoProductsIfNeeded();
  }
}
