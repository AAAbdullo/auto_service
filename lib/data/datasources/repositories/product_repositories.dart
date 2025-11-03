import 'package:auto_service/data/datasources/local/local_storage.dart';
import 'package:auto_service/data/models/product_model.dart';

class ProductRepository {
  final LocalStorage _localStorage;

  ProductRepository(this._localStorage);

  // ===========================
  // Работа с продуктами
  // ===========================

  Future<List<ProductModel>> getProducts() async {
    final products = await _localStorage.getProducts();
    return products ?? [];
  }

  Future<void> addProduct(ProductModel product) async {
    final products = await _localStorage.getProducts() ?? [];
    products.add(product);
    await _localStorage.saveProducts(products);
  }

  Future<void> clearProducts() async {
    await _localStorage.clearProducts();
  }

  // ===========================
  // Работа с заказами
  // ===========================

  Future<List<ProductModel>> getOrders() async {
    final orders = await _localStorage.getOrders();
    return orders ?? [];
  }

  Future<void> addOrder(ProductModel product) async {
    await _localStorage.addOrder(product);
  }

  Future<void> clearOrders() async {
    await _localStorage.clearOrders();
  }
}
