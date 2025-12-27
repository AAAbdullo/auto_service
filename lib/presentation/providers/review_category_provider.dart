import 'package:flutter/foundation.dart';
import 'package:auto_service/data/datasources/remote/reviews_api_service.dart';
import 'package:auto_service/data/models/review_model.dart';
import 'package:auto_service/data/datasources/local/local_storage.dart';

class ReviewCategoryProvider with ChangeNotifier {
  final ReviewsApiService _apiService = ReviewsApiService();
  final LocalStorage _localStorage = LocalStorage();

  List<ReviewCategory> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<ReviewCategory> get categories => List.unmodifiable(_categories);
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Initialize and load review categories
  Future<void> initializeCategories({String? token}) async {
    if (_categories.isNotEmpty) return; // Already loaded
    await fetchCategories(token: token);
  }

  /// Fetch review categories from API
  Future<void> fetchCategories({String? token}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final accessToken = token ?? await _localStorage.getAccessToken();
      final fetchedCategories = await _apiService.getReviewCategories(token: accessToken);

      _categories = fetchedCategories;
      _error = null;
    } catch (e) {
      _error = 'Failed to load review categories: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get category by ID
  ReviewCategory? getCategoryById(int id) {
    try {
      return _categories.firstWhere((cat) => cat.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get categories by IDs
  List<ReviewCategory> getCategoriesByIds(List<int> ids) {
    return _categories.where((cat) => ids.contains(cat.id)).toList();
  }

  /// Clear categories
  void clearCategories() {
    _categories = [];
    _error = null;
    notifyListeners();
  }
}
