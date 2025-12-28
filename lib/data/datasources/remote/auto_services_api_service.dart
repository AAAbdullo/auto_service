import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:auto_service/core/config/api_config.dart';
import 'package:auto_service/core/utils/api_logger.dart';
import 'package:auto_service/data/models/auto_service_model.dart';
import 'package:flutter/foundation.dart';

/// API Service for Auto Services endpoints
class AutoServicesApiService {
  /// Get all services with pagination and filters
  Future<List<AutoServiceModel>> getAllServices({
    int page = 1,
    String? search,
    String? ordering,
    int? categoryId,
    String? name,
    String? address,
    String? token,
  }) async {
    final queryParams = <String, String>{'page': page.toString()};

    if (search != null) queryParams['search'] = search;
    if (ordering != null) queryParams['ordering'] = ordering;
    if (categoryId != null) queryParams['category'] = categoryId.toString();
    if (name != null) queryParams['name'] = name;
    if (address != null) queryParams['address'] = address;

    final uri = Uri.parse(
      '${ApiConfig.apiUrl}/service/',
    ).replace(queryParameters: queryParams);

    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
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
        final results = data is Map
            ? (data['results'] as List? ?? data['data'] as List? ?? [])
            : (data is List ? data : []);

        ApiLogger.logSuccess('Loaded ${results.length} services');

        return results
            .map((e) => AutoServiceModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 401) {
        ApiLogger.logError('GET', uri, 'Unauthorized', response: response);
        throw Exception('401');
      } else {
        ApiLogger.logError(
          'GET',
          uri,
          'Failed to load services',
          response: response,
        );
        return [];
      }
    } catch (e, stackTrace) {
      stopwatch.stop();
      ApiLogger.logError('GET', uri, e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get service details by ID
  Future<AutoServiceModel?> getServiceDetails(
    int serviceId, {
    String? token,
  }) async {
    final uri = Uri.parse('${ApiConfig.apiUrl}/service/$serviceId/');

    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
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
        ApiLogger.logSuccess('Loaded service details for ID: $serviceId');
<<<<<<< HEAD

        final serviceJson = data is Map && data.containsKey('data')
            ? data['data'] as Map<String, dynamic>
            : data as Map<String, dynamic>;

        return AutoServiceModel.fromJson(serviceJson);
=======
        return AutoServiceModel.fromJson(data as Map<String, dynamic>);
>>>>>>> 420a5290a84808305b67d14c3efa00a2302c11d1
      } else if (response.statusCode == 401) {
        ApiLogger.logError('GET', uri, 'Unauthorized', response: response);
        throw Exception('401');
      } else {
        ApiLogger.logError(
          'GET',
          uri,
          'Failed to load service details',
          response: response,
        );
        return null;
      }
    } catch (e, stackTrace) {
      stopwatch.stop();
      ApiLogger.logError('GET', uri, e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get current user's services
  Future<List<AutoServiceModel>> getMyServices({
    required String token,
    int page = 1,
    String? search,
    String? ordering,
  }) async {
    final queryParams = <String, String>{'page': page.toString()};

    if (search != null) queryParams['search'] = search;
    if (ordering != null) queryParams['ordering'] = ordering;

    final uri = Uri.parse(
      '${ApiConfig.apiUrl}/service/my/',
    ).replace(queryParameters: queryParams);

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
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
        final results = data is Map
            ? (data['results'] as List? ?? data['data'] as List? ?? [])
            : (data is List ? data : []);

        ApiLogger.logSuccess('Loaded ${results.length} user services');

        return results
            .map((e) => AutoServiceModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 401) {
        ApiLogger.logError('GET', uri, 'Unauthorized', response: response);
        throw Exception('401');
      } else {
        ApiLogger.logError(
          'GET',
          uri,
          'Failed to load user services',
          response: response,
        );
        return [];
      }
    } catch (e, stackTrace) {
      stopwatch.stop();
      ApiLogger.logError('GET', uri, e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get nearest services
  Future<List<AutoServiceModel>> getNearestServices({
    required double lat,
    required double lon,
    double radius = 5000,
    int? categoryId,
    int page = 1,
    int pageSize = 20,
    String? token,
  }) async {
    final queryParams = <String, String>{
      'lat': lat.toString(),
      'lon': lon.toString(),
      'radius': radius.toInt().toString(),
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };

    if (categoryId != null) {
      queryParams['category'] = categoryId.toString();
    }

    final uri = Uri.parse(
      '${ApiConfig.apiUrl}/service/nearest/',
    ).replace(queryParameters: queryParams);

    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
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
        final results = data is Map
            ? (data['results'] as List? ?? [])
            : (data is List ? data : []);

        ApiLogger.logSuccess('Loaded ${results.length} nearest services');

        return results
            .map((e) => AutoServiceModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 401) {
        ApiLogger.logError('GET', uri, 'Unauthorized', response: response);
        throw Exception('401');
      } else {
        ApiLogger.logError(
          'GET',
          uri,
          'Failed to load nearest services',
          response: response,
        );
        return [];
      }
    } catch (e, stackTrace) {
      stopwatch.stop();
      ApiLogger.logError('GET', uri, e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Create a new service
  Future<AutoServiceModel?> createService({
    required String token,
    required Map<String, dynamic> serviceData,
  }) async {
    final uri = Uri.parse('${ApiConfig.apiUrl}/service/create/');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final stopwatch = Stopwatch()..start();
    ApiLogger.logRequest('POST', uri, headers: headers, body: serviceData);

    try {
      final response = await http
          .post(uri, headers: headers, body: jsonEncode(serviceData))
          .timeout(ApiConfig.connectionTimeout);

      stopwatch.stop();
      ApiLogger.logResponse('POST', uri, response, stopwatch.elapsed);

      if (response.statusCode == 201) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final serviceJson = data is Map && data.containsKey('data')
            ? data['data'] as Map<String, dynamic>
            : data as Map<String, dynamic>;

        ApiLogger.logSuccess('Service created successfully');
        return AutoServiceModel.fromJson(serviceJson);
      } else {
        ApiLogger.logError(
          'POST',
          uri,
          'Failed to create service',
          response: response,
        );
        return null;
      }
    } catch (e, stackTrace) {
      stopwatch.stop();
      ApiLogger.logError('POST', uri, e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Update a service
  Future<bool> updateService({
    required String token,
    required int serviceId,
    required Map<String, dynamic> data,
  }) async {
    final uri = Uri.parse('${ApiConfig.apiUrl}/service/$serviceId/');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final stopwatch = Stopwatch()..start();
    ApiLogger.logRequest('PATCH', uri, headers: headers, body: data);

    try {
      final response = await http
          .patch(uri, headers: headers, body: jsonEncode(data))
          .timeout(ApiConfig.connectionTimeout);

      stopwatch.stop();
      ApiLogger.logResponse('PATCH', uri, response, stopwatch.elapsed);

      if (response.statusCode == 200) {
        ApiLogger.logSuccess('Service updated successfully');
        return true;
      } else {
        ApiLogger.logError(
          'PATCH',
          uri,
          'Failed to update service',
          response: response,
        );
        return false;
      }
    } catch (e, stackTrace) {
      stopwatch.stop();
      ApiLogger.logError('PATCH', uri, e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Delete a service
  Future<bool> deleteService({
    required String token,
    required int serviceId,
  }) async {
    final uri = Uri.parse('${ApiConfig.apiUrl}/service/$serviceId/');

    final headers = <String, String>{'Authorization': 'Bearer $token'};

    final stopwatch = Stopwatch()..start();
    ApiLogger.logRequest('DELETE', uri, headers: headers);

    try {
      final response = await http
          .delete(uri, headers: headers)
          .timeout(ApiConfig.connectionTimeout);

      stopwatch.stop();
      ApiLogger.logResponse('DELETE', uri, response, stopwatch.elapsed);

      if (response.statusCode == 204) {
        ApiLogger.logSuccess('Service deleted successfully');
        return true;
      } else {
        ApiLogger.logError(
          'DELETE',
          uri,
          'Failed to delete service',
          response: response,
        );
        return false;
      }
    } catch (e, stackTrace) {
      stopwatch.stop();
      ApiLogger.logError('DELETE', uri, e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Upload service image
  Future<bool> uploadServiceImage({
    required String token,
    required int serviceId,
    required String imagePath,
  }) async {
    final uri = Uri.parse('${ApiConfig.apiUrl}/service/$serviceId/images/');

    final stopwatch = Stopwatch()..start();
    ApiLogger.logInfo('Uploading image for service $serviceId');
    debugPrint('📤 ========== ЗАГРУЗКА КАРТИНКИ ==========');
    debugPrint('   Service ID: $serviceId');
    debugPrint('   Image Path: $imagePath');
    debugPrint('   URL: $uri');

    try {
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';

      final file = await http.MultipartFile.fromPath('image', imagePath);
      debugPrint('   File size: ${file.length} bytes');
      debugPrint('   Content type: ${file.contentType}');
      request.files.add(file);

      final streamedResponse = await request.send().timeout(
        ApiConfig.connectionTimeout,
      );
      final response = await http.Response.fromStream(streamedResponse);

      stopwatch.stop();
      ApiLogger.logResponse('POST', uri, response, stopwatch.elapsed);

      debugPrint('   Response status: ${response.statusCode}');
      debugPrint('   Response body: ${response.body}');
      debugPrint('📤 ====================================');

      if (response.statusCode == 201) {
        ApiLogger.logSuccess('Service image uploaded successfully');
        debugPrint('✅ Картинка успешно загружена!');
        return true;
      } else {
        ApiLogger.logError(
          'POST',
          uri,
          'Failed to upload image',
          response: response,
        );
        debugPrint('❌ Ошибка загрузки картинки: ${response.statusCode}');
        debugPrint('   Body: ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      stopwatch.stop();
      ApiLogger.logError('POST', uri, e, stackTrace: stackTrace);
      debugPrint('❌ Исключение при загрузке картинки: $e');
      debugPrint('📤 ====================================');
      return false;
    }
  }

  /// Delete service image
  Future<bool> deleteServiceImage({
    required String token,
    required int serviceId,
  }) async {
    final uri = Uri.parse('${ApiConfig.apiUrl}/service/$serviceId/images/');

    final headers = <String, String>{'Authorization': 'Bearer $token'};

    final stopwatch = Stopwatch()..start();
    ApiLogger.logRequest('DELETE', uri, headers: headers);

    try {
      final response = await http
          .delete(uri, headers: headers)
          .timeout(ApiConfig.connectionTimeout);

      stopwatch.stop();
      ApiLogger.logResponse('DELETE', uri, response, stopwatch.elapsed);

      if (response.statusCode == 200) {
        ApiLogger.logSuccess('Service image deleted successfully');
        return true;
      } else {
        ApiLogger.logError(
          'DELETE',
          uri,
          'Failed to delete image',
          response: response,
        );
        return false;
      }
    } catch (e, stackTrace) {
      stopwatch.stop();
      ApiLogger.logError('DELETE', uri, e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Get service categories
  Future<List<ServiceCategory>> getServiceCategories({String? token}) async {
    // Пробуем несколько возможных эндпоинтов
    final possibleEndpoints = [
<<<<<<< HEAD
      '${ApiConfig.apiUrl}/service-category/',
      '${ApiConfig.apiUrl}/category/',
=======
>>>>>>> 420a5290a84808305b67d14c3efa00a2302c11d1
      '${ApiConfig.apiUrl}/categories/',
      '${ApiConfig.apiUrl}/service/categories/',
      '${ApiConfig.apiUrl}/service/category/',
      '${ApiConfig.apiUrl}/service-categories/',
<<<<<<< HEAD
      '${ApiConfig.apiUrl}/common/categories/',
      '${ApiConfig.apiUrl}/common/category/',
      '${ApiConfig.apiUrl}/service/category-list/',
      '${ApiConfig.apiUrl}/common/service-categories/',
      '${ApiConfig.apiUrl}/common/services/categories/',
      '${ApiConfig.apiUrl}/services/categories/',
=======
>>>>>>> 420a5290a84808305b67d14c3efa00a2302c11d1
    ];

    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    // Пробуем каждый эндпоинт
    for (final endpoint in possibleEndpoints) {
      try {
        final uri = Uri.parse(endpoint);
        final stopwatch = Stopwatch()..start();
        ApiLogger.logRequest('GET', uri, headers: headers);

        final response = await http
            .get(uri, headers: headers)
            .timeout(ApiConfig.connectionTimeout);

        stopwatch.stop();
        ApiLogger.logResponse('GET', uri, response, stopwatch.elapsed);

        if (response.statusCode == 200) {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          final results = data is List
              ? data
              : (data['results'] as List? ?? []);

          if (results.isNotEmpty) {
            ApiLogger.logSuccess(
              'Loaded ${results.length} service categories from $endpoint',
            );

            return results
                .map((e) => ServiceCategory.fromJson(e as Map<String, dynamic>))
                .toList();
          }
        }
      } catch (e) {
<<<<<<< HEAD
        // Just log info for probing failures, not error
        ApiLogger.logInfo('Probe failed for $endpoint: $e');
=======
        ApiLogger.logInfo('Trying next endpoint after error: $e');
>>>>>>> 420a5290a84808305b67d14c3efa00a2302c11d1
        continue;
      }
    }

<<<<<<< HEAD
    // Если ни один эндпоинт не сработал
=======
    // Если ни один эндпоинт не сработал, возвращаем дефолтные категории
>>>>>>> 420a5290a84808305b67d14c3efa00a2302c11d1
    ApiLogger.logWarning(
      'No category endpoint worked, using fallback categories',
    );
    return _getFallbackCategories();
  }

  /// Получить fallback категории, если API недоступен
  List<ServiceCategory> _getFallbackCategories() {
    return [
      ServiceCategory(
        id: 1,
        name: 'Диагностика',
        slug: 'diagnostics',
        icon: '🔍',
      ),
      ServiceCategory(
        id: 2,
        name: 'Ремонт двигателя',
        slug: 'engine-repair',
        icon: '🔧',
      ),
      ServiceCategory(
        id: 3,
        name: 'Замена масла',
        slug: 'oil-change',
        icon: '🛢️',
      ),
      ServiceCategory(
        id: 4,
        name: 'Шиномонтаж',
        slug: 'tire-service',
        icon: '🚗',
      ),
      ServiceCategory(
        id: 5,
        name: 'Ремонт тормозов',
        slug: 'brake-repair',
        icon: '🛑',
      ),
      ServiceCategory(
        id: 6,
        name: 'Кузовной ремонт',
        slug: 'body-repair',
        icon: '🔨',
      ),
      ServiceCategory(id: 7, name: 'Электрика', slug: 'electrical', icon: '⚡'),
      ServiceCategory(id: 8, name: 'Подвеска', slug: 'suspension', icon: '🔩'),
    ];
  }
}
