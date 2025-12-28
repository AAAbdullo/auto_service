import 'package:auto_service/data/datasources/repositories/product_repositories.dart';
import 'package:flutter/material.dart';
import 'package:auto_service/data/models/product_model.dart';

class OrdersProvider extends ChangeNotifier {
  final ProductRepository _productRepository;

  List<ProductModel> _orders = [];
  List<ProductModel> get orders => _orders;

  OrdersProvider(this._productRepository);

  Future<void> loadOrders() async {
    _orders = await _productRepository.getOrders();
    notifyListeners();
  }

  Future<void> addOrder(ProductModel product) async {
    await _productRepository.addOrder(product);
    _orders.insert(0, product); // Добавляем в начало списка
    notifyListeners();
  }

  Future<void> clearOrders() async {
    await _productRepository.clearOrders();
    _orders.clear();
    notifyListeners();
  }
}
