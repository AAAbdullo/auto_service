import 'package:auto_service/data/datasources/remote/auto_services_api_service.dart';
import 'package:auto_service/data/datasources/local/local_storage.dart';
import 'package:auto_service/data/models/auto_service_model.dart';
import 'package:auto_service/data/datasources/repositories/auth_repositories.dart';
<<<<<<< HEAD
=======
import 'package:auto_service/data/datasources/mock/mock_services_data.dart';
>>>>>>> 420a5290a84808305b67d14c3efa00a2302c11d1
import 'package:flutter/foundation.dart';

class AutoServicesRepository {
  final AutoServicesApiService _apiService = AutoServicesApiService();
  final LocalStorage _localStorage = LocalStorage();
  late final AuthRepository _authRepository;

  AutoServicesRepository() {
    _authRepository = AuthRepository(_localStorage);
  }

<<<<<<< HEAD
  Future<T> _retryWithRefresh<T>(
    Future<T> Function(String? token) call, {
    bool allowAnonymous = false,
  }) async {
=======
  Future<T> _retryWithRefresh<T>(Future<T> Function(String? token) call) async {
>>>>>>> 420a5290a84808305b67d14c3efa00a2302c11d1
    final token = await _localStorage.getAccessToken();
    try {
      return await call(token);
    } catch (e) {
      debugPrint('❌ API Error: $e');

<<<<<<< HEAD
      if (e.toString().contains('401')) {
        debugPrint('🔑 Token expired, attempting refresh...');
        final newToken = await _authRepository.refreshAccessToken();

        if (newToken != null) {
          debugPrint('🔄 Retry request with new token');
          return await call(newToken);
        } else if (allowAnonymous) {
          debugPrint(
            '⚠️ Token refresh failed, but anonymous access allowed. Retrying without token...',
          );
          return await call(null);
        }
      }

=======
      // 🎯 Fallback на demo данные если бэкэнд упал
      if (e.toString().contains('Connection refused') ||
          e.toString().contains('Connection failed') ||
          e.toString().contains('SocketException') ||
          e.toString().contains('HandshakeException') ||
          e.toString().contains('CERTIFICATE_VERIFY_FAILED') ||
          e.toString().contains('Failed host lookup')) {
        debugPrint('⚠️ Backend is unavailable, using demo data...');

        // Возвращаем demo данные вместо null
        if (T == List<AutoServiceModel>) {
          return MockServicesData.getDemoServices() as T;
        }
      }

      if (e.toString().contains('401')) {
        print('🔑 Token expired, attempting refresh...');
        final newToken = await _authRepository.refreshAccessToken();
        if (newToken != null) {
          print('🔄 Retry request with new token');
          return await call(newToken);
        }
      }
>>>>>>> 420a5290a84808305b67d14c3efa00a2302c11d1
      rethrow;
    }
  }

  Future<List<AutoServiceModel>> getAllServices({
    int page = 1,
    String? search,
    String? ordering,
    int? categoryId,
    String? name,
    String? address,
  }) async {
    return await _retryWithRefresh(
      (token) => _apiService.getAllServices(
        page: page,
        search: search,
        ordering: ordering,
        categoryId: categoryId,
        name: name,
        address: address,
        token: token,
      ),
<<<<<<< HEAD
      allowAnonymous: true,
=======
>>>>>>> 420a5290a84808305b67d14c3efa00a2302c11d1
    );
  }

  /// Get service details by ID
  Future<AutoServiceModel?> getServiceDetails(int serviceId) async {
    return await _retryWithRefresh(
      (token) => _apiService.getServiceDetails(serviceId, token: token),
<<<<<<< HEAD
      allowAnonymous: true,
=======
>>>>>>> 420a5290a84808305b67d14c3efa00a2302c11d1
    );
  }

  Future<List<AutoServiceModel>> getMyServices({
    int page = 1,
    String? search,
    String? ordering,
  }) async {
    return await _retryWithRefresh(
      (token) => _apiService.getMyServices(
        token: token ?? '',
        page: page,
        search: search,
        ordering: ordering,
      ),
    );
  }

  Future<List<AutoServiceModel>> getNearestServices({
    required double lat,
    required double lon,
    double radius = 5000,
    int? categoryId,
    int page = 1,
    int pageSize = 20,
  }) async {
    return await _retryWithRefresh(
      (token) => _apiService.getNearestServices(
        lat: lat,
        lon: lon,
        radius: radius,
        categoryId: categoryId,
        page: page,
        pageSize: pageSize,
        token: token,
      ),
<<<<<<< HEAD
      allowAnonymous: true,
=======
>>>>>>> 420a5290a84808305b67d14c3efa00a2302c11d1
    );
  }

  Future<AutoServiceModel?> createService({
    required Map<String, dynamic> serviceData,
  }) async {
    return await _retryWithRefresh(
      (token) => _apiService.createService(
        token: token ?? '',
        serviceData: serviceData,
      ),
    );
  }

  Future<bool> updateService({
    required int id,
    required Map<String, dynamic> data,
  }) async {
    return await _retryWithRefresh(
      (token) => _apiService.updateService(
        token: token ?? '',
        serviceId: id,
        data: data,
      ),
    );
  }

  Future<bool> deleteService({required int id}) async {
    return await _retryWithRefresh(
      (token) => _apiService.deleteService(token: token ?? '', serviceId: id),
    );
  }

  Future<bool> addServiceImage({
    required int serviceId,
    required String imagePath,
  }) async {
    return await _retryWithRefresh(
      (token) => _apiService.uploadServiceImage(
        token: token ?? '',
        serviceId: serviceId,
        imagePath: imagePath,
      ),
    );
  }

  Future<bool> deleteServiceImage({required int serviceId}) async {
    return await _retryWithRefresh(
      (token) => _apiService.deleteServiceImage(
        token: token ?? '',
        serviceId: serviceId,
      ),
    );
  }

  Future<List<ServiceCategory>> getServiceCategories() async {
    return await _retryWithRefresh(
      (token) => _apiService.getServiceCategories(token: token),
<<<<<<< HEAD
      allowAnonymous: true,
    );
=======
    ).catchError((_) {
      // Fallback на demo категории если бэкэнд упал
      debugPrint('⚠️ Backend unavailable, using demo categories...');
      return MockServicesData.getDemoCategories();
    });
>>>>>>> 420a5290a84808305b67d14c3efa00a2302c11d1
  }
}
