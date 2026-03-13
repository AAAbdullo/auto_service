import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:auto_service/core/config/api_config.dart';
import 'package:auto_service/data/models/market_model.dart';
import 'package:auto_service/core/utils/api_logger.dart';

class MarketApiService {
  final String _baseUrl = ApiConfig.apiUrl;

  // ====================== Public Methods ======================

  /// Get all products (requires auth)
  /// Используем /market/my/products/ для получения товаров текущего пользователя
  Future<List<Product>> getAllProducts({int page = 1, String? token}) async {
    final uri = Uri.parse(
      '$_baseUrl/market/my/products/',
    ).replace(queryParameters: {'page': page.toString()});

    final headers = <String, String>{'Content-Type': 'application/json'};

    // Добавляем токен если он есть
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
      print(
        '🔑 Токен добавлен в заголовки: Bearer ${token.substring(0, 10)}...',
      );
    } else {
      print('⚠️ ВНИМАНИЕ: Токен отсутствует или пустой!');
    }

    final stopwatch = Stopwatch()..start();
    ApiLogger.logRequest('GET', uri, headers: headers);

    try {
      final response = await http
          .get(uri, headers: headers)
          .timeout(ApiConfig.connectionTimeout);

      stopwatch.stop();
      ApiLogger.logResponse('GET', uri, response, stopwatch.elapsed);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final results = data is Map ? (data['results'] as List? ?? []) : data;
        final products = (results as List)
            .map((e) => Product.fromJson(e as Map<String, dynamic>))
            .toList();
        ApiLogger.logSuccess('Загружено ${products.length} товаров');
        return products;
      } else if (response.statusCode == 401) {
        ApiLogger.logError('GET', uri, 'Unauthorized', response: response);
        throw Exception('401');
      } else if (response.statusCode == 405) {
        // Method Not Allowed - likely endpoint doesn't support GET or doesn't exist for listing
        ApiLogger.logError(
          'GET',
          uri,
          'Method 405 Not Allowed. Endpoint might be POST-only or invalid.',
          response: response,
        );
        // Return empty list instead of crashing, but log heavily
        print(
          '❌ ERROR: API returned 405 for getAllProducts. This endpoint may not support listing.',
        );
        return [];
      } else {
        ApiLogger.logError(
          'GET',
          uri,
          'Get all products failed',
          response: response,
        );
        throw Exception(
          'Не удалось загрузить товары. Статус: ${response.statusCode}',
        );
      }
    } catch (e, stackTrace) {
      stopwatch.stop();
      ApiLogger.logError('GET', uri, e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // ====================== Shop Management ======================

  /// Get my shop
  Future<Shop?> getMyShop(String token) async {
    final uri = Uri.parse('$_baseUrl/market/my/shop/');
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    final stopwatch = Stopwatch()..start();
    ApiLogger.logRequest('GET', uri, headers: headers);

    try {
      final response = await http
          .get(uri, headers: headers)
          .timeout(ApiConfig.connectionTimeout);

      stopwatch.stop();
      ApiLogger.logResponse('GET', uri, response, stopwatch.elapsed);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        ApiLogger.logSuccess('Shop data loaded successfully');
        return Shop.fromJson(data);
      }
      ApiLogger.logError('GET', uri, 'Get shop failed', response: response);
      return null;
    } catch (e, stackTrace) {
      stopwatch.stop();
      ApiLogger.logError('GET', uri, e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Create shop
  Future<Shop?> createShop({
    required String token,
    required String name,
    required String address,
    required String phone,
    String? description,
  }) async {
    final uri = Uri.parse('$_baseUrl/market/shops/');
    final body = {
      'name': name,
      'address': address,
      'phone': phone,
      'description': ?description,
    };

    final stopwatch = Stopwatch()..start();
    ApiLogger.logRequest(
      'POST',
      uri,
      headers: {'Authorization': 'Bearer $token'},
      body: body,
    );

    try {
      final response = await http
          .post(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.connectionTimeout);

      stopwatch.stop();
      ApiLogger.logResponse('POST', uri, response, stopwatch.elapsed);

      if (response.statusCode == 201) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        ApiLogger.logSuccess('Shop created successfully');
        return Shop.fromJson(data);
      }
      ApiLogger.logError('POST', uri, 'Create shop failed', response: response);
      return null;
    } catch (e, stackTrace) {
      stopwatch.stop();
      ApiLogger.logError('POST', uri, e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Update shop
  Future<bool> updateShop({
    required String token,
    required int shopId,
    String? name,
    String? address,
    String? phone,
    String? description,
  }) async {
    final uri = Uri.parse('$_baseUrl/market/shops/$shopId/');
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (address != null) body['address'] = address;
    if (phone != null) body['phone'] = phone;
    if (description != null) body['description'] = description;

    final stopwatch = Stopwatch()..start();
    ApiLogger.logRequest(
      'PATCH',
      uri,
      headers: {'Authorization': 'Bearer $token'},
      body: body,
    );

    try {
      final response = await http
          .patch(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.connectionTimeout);

      stopwatch.stop();
      ApiLogger.logResponse('PATCH', uri, response, stopwatch.elapsed);

      if (response.statusCode == 200) {
        ApiLogger.logSuccess('Shop updated successfully');
        return true;
      }
      ApiLogger.logError(
        'PATCH',
        uri,
        'Update shop failed',
        response: response,
      );
      return false;
    } catch (e, stackTrace) {
      stopwatch.stop();
      ApiLogger.logError('PATCH', uri, e, stackTrace: stackTrace);
      return false;
    }
  }

  // ====================== Product Management ======================

  /// Get my products
  Future<List<Product>> getMyProducts(String token, {int page = 1}) async {
    final uri = Uri.parse(
      '$_baseUrl/market/my/products/',
    ).replace(queryParameters: {'page': page.toString()});
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    final stopwatch = Stopwatch()..start();
    ApiLogger.logRequest('GET', uri, headers: headers);

    try {
      final response = await http
          .get(uri, headers: headers)
          .timeout(ApiConfig.connectionTimeout);

      stopwatch.stop();
      ApiLogger.logResponse('GET', uri, response, stopwatch.elapsed);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final results = data is Map ? (data['results'] as List? ?? []) : data;
        final products = (results as List)
            .map((e) => Product.fromJson(e as Map<String, dynamic>))
            .toList();
        ApiLogger.logSuccess('Loaded ${products.length} products');
        return products;
      }
      ApiLogger.logError('GET', uri, 'Get products failed', response: response);
      return [];
    } catch (e, stackTrace) {
      stopwatch.stop();
      ApiLogger.logError('GET', uri, e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Create product
  Future<Product?> createProduct({
    required String token,
    required int shopId,
    required String name,
    required int year,
    required String description,
    required String originalPrice,
    required String discountPrice,
    int? categoryId,
    String? color,
    String? model,
    String? features,
    String? advantages,
  }) async {
    final uri = Uri.parse('$_baseUrl/market/products/');
    final body = {
      'shop': shopId,
      'name': name,
      'year': year,
      'description': description,
      'original_price': originalPrice,
      'discount_price': discountPrice,
      'category': ?categoryId,
      'color': ?color,
      'model': ?model,
      'features': ?features,
      'advantages': ?advantages,
    };
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    final stopwatch = Stopwatch()..start();
    ApiLogger.logRequest('POST', uri, headers: headers, body: body);

    try {
      final response = await http
          .post(uri, headers: headers, body: jsonEncode(body))
          .timeout(ApiConfig.connectionTimeout);

      stopwatch.stop();
      ApiLogger.logResponse('POST', uri, response, stopwatch.elapsed);

      if (response.statusCode == 201) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        ApiLogger.logSuccess('Product created: $name');
        return Product.fromJson(data);
      }
      ApiLogger.logError(
        'POST',
        uri,
        'Create product failed',
        response: response,
      );
      return null;
    } catch (e, stackTrace) {
      stopwatch.stop();
      ApiLogger.logError('POST', uri, e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Update product
  Future<bool> updateProduct({
    required String token,
    required int productId,
    String? name,
    int? year,
    String? description,
    String? originalPrice,
    String? discountPrice,
    int? categoryId,
    String? color,
    String? model,
    String? features,
    String? advantages,
  }) async {
    final uri = Uri.parse('$_baseUrl/market/products/$productId/');
    final body = <String, dynamic>{};

    if (name != null) body['name'] = name;
    if (year != null) body['year'] = year;
    if (description != null) body['description'] = description;
    if (originalPrice != null) body['original_price'] = originalPrice;
    if (discountPrice != null) body['discount_price'] = discountPrice;
    if (categoryId != null) body['category'] = categoryId;
    if (color != null) body['color'] = color;
    if (model != null) body['model'] = model;
    if (features != null) body['features'] = features;
    if (advantages != null) body['advantages'] = advantages;

    final stopwatch = Stopwatch()..start();
    ApiLogger.logRequest(
      'PATCH',
      uri,
      headers: {'Authorization': 'Bearer $token'},
      body: body,
    );

    try {
      final response = await http
          .patch(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.connectionTimeout);

      stopwatch.stop();
      ApiLogger.logResponse('PATCH', uri, response, stopwatch.elapsed);

      if (response.statusCode == 200) {
        ApiLogger.logSuccess('Product updated successfully');
        return true;
      }
      ApiLogger.logError(
        'PATCH',
        uri,
        'Update product failed',
        response: response,
      );
      return false;
    } catch (e, stackTrace) {
      stopwatch.stop();
      ApiLogger.logError('PATCH', uri, e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Delete product
  Future<bool> deleteProduct({
    required String token,
    required int productId,
  }) async {
    final uri = Uri.parse('$_baseUrl/market/products/$productId/delete/');
    final stopwatch = Stopwatch()..start();
    ApiLogger.logRequest(
      'DELETE',
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    try {
      final response = await http
          .delete(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(ApiConfig.connectionTimeout);

      stopwatch.stop();
      ApiLogger.logResponse('DELETE', uri, response, stopwatch.elapsed);

      if (response.statusCode == 204) {
        ApiLogger.logSuccess('Product deleted successfully');
        return true;
      }
      ApiLogger.logError(
        'DELETE',
        uri,
        'Delete product failed',
        response: response,
      );
      return false;
    } catch (e, stackTrace) {
      stopwatch.stop();
      ApiLogger.logError('DELETE', uri, e, stackTrace: stackTrace);
      return false;
    }
  }

  // ====================== Product Reservations ======================

  /// Get my product reservations
  Future<List<ProductReservation>> getMyReservations(
    String token, {
    int page = 1,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/market/my/product-reservations/',
    ).replace(queryParameters: {'page': page.toString()});
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    final stopwatch = Stopwatch()..start();
    ApiLogger.logRequest('GET', uri, headers: headers);

    try {
      final response = await http
          .get(uri, headers: headers)
          .timeout(ApiConfig.connectionTimeout);

      stopwatch.stop();
      ApiLogger.logResponse('GET', uri, response, stopwatch.elapsed);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final results = data is Map ? (data['results'] as List? ?? []) : data;
        final reservations = results
            .map((e) => ProductReservation.fromJson(e))
            .toList();
        ApiLogger.logSuccess('Loaded ${reservations.length} reservations');
        return reservations;
      }
      ApiLogger.logError(
        'GET',
        uri,
        'Get reservations failed',
        response: response,
      );
      return [];
    } catch (e, stackTrace) {
      stopwatch.stop();
      ApiLogger.logError('GET', uri, e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Update reservation status
  Future<bool> updateReservationStatus({
    required String token,
    required int reservationId,
    required String status, // 'pending', 'confirmed', 'cancelled'
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/market/product-reservations/$reservationId/status/',
    );
    final body = {'status': status};

    final stopwatch = Stopwatch()..start();
    ApiLogger.logRequest(
      'PATCH',
      uri,
      headers: {'Authorization': 'Bearer $token'},
      body: body,
    );

    try {
      final response = await http
          .patch(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.connectionTimeout);

      stopwatch.stop();
      ApiLogger.logResponse('PATCH', uri, response, stopwatch.elapsed);

      if (response.statusCode == 200) {
        ApiLogger.logSuccess('Reservation status updated successfully');
        return true;
      }
      ApiLogger.logError(
        'PATCH',
        uri,
        'Update reservation failed',
        response: response,
      );
      return false;
    } catch (e, stackTrace) {
      stopwatch.stop();
      ApiLogger.logError('PATCH', uri, e, stackTrace: stackTrace);
      return false;
    }
  }
}
