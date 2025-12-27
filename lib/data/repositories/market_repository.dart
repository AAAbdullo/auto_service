import 'package:auto_service/data/datasources/remote/market_api_service.dart';
import 'package:auto_service/data/datasources/local/local_storage.dart';
import 'package:auto_service/data/models/market_model.dart';
import 'package:auto_service/data/datasources/repositories/auth_repositories.dart';

class MarketRepository {
  final MarketApiService _apiService = MarketApiService();
  final LocalStorage _localStorage = LocalStorage();
  late final AuthRepository _authRepository;

  MarketRepository() {
    _authRepository = AuthRepository(_localStorage);
  }

  Future<T> _retryWithRefresh<T>(Future<T> Function(String token) call) async {
    final token = await _localStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('401'); // Force refresh attempt if token missing
    }

    try {
      return await call(token);
    } catch (e) {
      if (e.toString().contains('401')) {
        print('🔑 Token expired, attempting refresh...');
        final newToken = await _authRepository.refreshAccessToken();
        if (newToken != null) {
          print('🔄 Retry request with new token');
          return await call(newToken);
        }
      }
      rethrow;
    }
  }

  // ====================== Public Methods ======================

  Future<List<Product>> getAllProducts({int page = 1}) async {
    return await _retryWithRefresh(
      (token) => _apiService.getAllProducts(page: page, token: token),
    );
  }

  // ====================== Shop Management ======================

  Future<Shop?> getMyShop() async {
    return await _retryWithRefresh((token) => _apiService.getMyShop(token));
  }

  Future<Shop?> createShop({
    required String name,
    required String address,
    required String phone,
    String? description,
  }) async {
    return await _retryWithRefresh(
      (token) => _apiService.createShop(
        token: token,
        name: name,
        address: address,
        phone: phone,
        description: description,
      ),
    );
  }

  Future<bool> updateShop({
    required int shopId,
    String? name,
    String? address,
    String? phone,
    String? description,
  }) async {
    return await _retryWithRefresh(
      (token) => _apiService.updateShop(
        token: token,
        shopId: shopId,
        name: name,
        address: address,
        phone: phone,
        description: description,
      ),
    );
  }

  // ====================== Product Management ======================

  Future<List<Product>> getMyProducts({int page = 1}) async {
    return await _retryWithRefresh(
      (token) => _apiService.getMyProducts(token, page: page),
    );
  }

  Future<Product?> createProduct({
    required int shopId,
    required String name,
    required int year,
    required String description,
    required double originalPrice,
    required double discountPrice,
    int? categoryId,
    String? color,
    String? model,
    String? features,
    String? advantages,
  }) async {
    return await _retryWithRefresh(
      (token) => _apiService.createProduct(
        token: token,
        shopId: shopId,
        name: name,
        year: year,
        description: description,
        originalPrice: originalPrice.toStringAsFixed(2),
        discountPrice: discountPrice.toStringAsFixed(2),
        categoryId: categoryId,
        color: color,
        model: model,
        features: features,
        advantages: advantages,
      ),
    );
  }

  Future<bool> updateProduct({
    required int productId,
    String? name,
    int? year,
    String? description,
    double? originalPrice,
    double? discountPrice,
    int? categoryId,
    String? color,
    String? model,
    String? features,
    String? advantages,
  }) async {
    return await _retryWithRefresh(
      (token) => _apiService.updateProduct(
        token: token,
        productId: productId,
        name: name,
        year: year,
        description: description,
        originalPrice: originalPrice?.toStringAsFixed(2),
        discountPrice: discountPrice?.toStringAsFixed(2),
        categoryId: categoryId,
        color: color,
        model: model,
        features: features,
        advantages: advantages,
      ),
    );
  }

  Future<bool> deleteProduct(int productId) async {
    return await _retryWithRefresh(
      (token) => _apiService.deleteProduct(token: token, productId: productId),
    );
  }

  // ====================== Product Reservations ======================

  Future<List<ProductReservation>> getMyReservations({int page = 1}) async {
    return await _retryWithRefresh(
      (token) => _apiService.getMyReservations(token, page: page),
    );
  }

  Future<bool> updateReservationStatus({
    required int reservationId,
    required String status,
  }) async {
    return await _retryWithRefresh(
      (token) => _apiService.updateReservationStatus(
        token: token,
        reservationId: reservationId,
        status: status,
      ),
    );
  }
}
