import 'package:flutter/foundation.dart';
import 'package:auto_service/data/datasources/remote/reviews_api_service.dart';
import 'package:auto_service/data/models/auto_service_model.dart';
import 'package:auto_service/data/datasources/local/local_storage.dart';

class RatingsProvider with ChangeNotifier {
  final ReviewsApiService _apiService = ReviewsApiService();
  final LocalStorage _localStorage = LocalStorage();

  final Map<int, ServiceRatingStats> _ratingsCache = {};
  final Map<int, bool> _loadingStates = {};
  final Map<int, String?> _errorStates = {};

  /// Get rating stats for a service
  ServiceRatingStats? getRatingStats(int serviceId) {
    return _ratingsCache[serviceId];
  }

  /// Check if loading
  bool isLoading(int serviceId) {
    return _loadingStates[serviceId] ?? false;
  }

  /// Get error message
  String? getError(int serviceId) {
    return _errorStates[serviceId];
  }

  /// Fetch rating statistics for a service
  Future<ServiceRatingStats?> fetchRatingStats(int serviceId, {String? token}) async {
    // Check cache first
    if (_ratingsCache.containsKey(serviceId)) {
      return _ratingsCache[serviceId];
    }

    _loadingStates[serviceId] = true;
    _errorStates[serviceId] = null;
    notifyListeners();

    try {
      final accessToken = token ?? await _localStorage.getAccessToken();
      final stats = await _apiService.getServiceRatingStats(
        serviceId,
        token: accessToken,
      );

      if (stats != null) {
        _ratingsCache[serviceId] = stats;
        _errorStates[serviceId] = null;
      } else {
        _errorStates[serviceId] = 'Failed to load rating statistics';
      }

      return stats;
    } catch (e) {
      _errorStates[serviceId] = 'Error loading ratings: $e';
      return null;
    } finally {
      _loadingStates[serviceId] = false;
      notifyListeners();
    }
  }

  /// Clear cache for a service
  void clearCache(int serviceId) {
    _ratingsCache.remove(serviceId);
    _loadingStates.remove(serviceId);
    _errorStates.remove(serviceId);
    notifyListeners();
  }

  /// Clear all cache
  void clearAllCache() {
    _ratingsCache.clear();
    _loadingStates.clear();
    _errorStates.clear();
    notifyListeners();
  }

  /// Refresh rating stats (force reload from API)
  Future<ServiceRatingStats?> refreshRatingStats(int serviceId, {String? token}) async {
    clearCache(serviceId);
    return fetchRatingStats(serviceId, token: token);
  }
}
