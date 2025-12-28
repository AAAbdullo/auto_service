import 'package:auto_service/data/datasources/remote/reviews_api_service.dart';
import 'package:auto_service/data/datasources/local/local_storage.dart';
import 'package:auto_service/data/models/review_model.dart';
import 'package:auto_service/data/datasources/repositories/auth_repositories.dart';
import 'package:auto_service/data/models/auto_service_model.dart';
import 'package:auto_service/core/utils/data_validator.dart';

class ReviewsRepository {
  final ReviewsApiService _apiService = ReviewsApiService();
  final LocalStorage _localStorage = LocalStorage();
  late final AuthRepository _authRepository;

  ReviewsRepository() {
    _authRepository = AuthRepository(_localStorage);
  }

  Future<T> _retryWithRefresh<T>(Future<T> Function(String? token) call) async {
    final token = await _localStorage.getAccessToken();
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

  // ====================== Review Management ======================

  /// Get reviews for a specific service
  Future<List<Review>> getServiceReviews(int serviceId, {int page = 1}) async {
    return await _retryWithRefresh(
      (token) =>
          _apiService.getServiceReviews(serviceId, page: page, token: token),
    );
  }

  /// Get rating statistics for a service
  Future<ServiceRatingStats?> getServiceRatingStats(int serviceId) async {
    return await _retryWithRefresh(
      (token) => _apiService.getServiceRatingStats(serviceId, token: token),
    );
  }

  Future<Review?> createReview(ReviewCreate review) async {
    // Validate the review before sending
    final validationError = review.validate();
    if (validationError != null) {
      throw ValidationError(validationError);
    }

    return await _retryWithRefresh(
      (token) => _apiService.createReview(token: token ?? '', review: review),
    );
  }

  Future<bool> updateReview({
    required int reviewId,
    String? title,
    String? comment,
    int? overallRating,
    int? qualityRating,
    int? priceRating,
    int? locationRating,
    int? staffRating,
    bool? isPublic,
  }) async {
    return await _retryWithRefresh(
      (token) => _apiService.updateReview(
        token: token ?? '',
        reviewId: reviewId,
        title: title,
        comment: comment,
        overallRating: overallRating,
        qualityRating: qualityRating,
        priceRating: priceRating,
        locationRating: locationRating,
        staffRating: staffRating,
        isPublic: isPublic,
      ),
    );
  }

  Future<bool> deleteReview(int reviewId) async {
    return await _retryWithRefresh(
      (token) =>
          _apiService.deleteReview(token: token ?? '', reviewId: reviewId),
    );
  }

  Future<bool> toggleReviewLike({
    required int reviewId,
    bool isLike = true,
  }) async {
    return await _retryWithRefresh(
      (token) => _apiService.toggleReviewLike(
        token: token ?? '',
        reviewId: reviewId,
        isLike: isLike,
      ),
    );
  }

  Future<ReviewResponse?> createReviewResponse({
    required int reviewId,
    required String responseText,
  }) async {
    return await _retryWithRefresh(
      (token) => _apiService.createReviewResponse(
        token: token ?? '',
        reviewId: reviewId,
        responseText: responseText,
      ),
    );
  }

  Future<bool> deleteReviewResponse(int responseId) async {
    return await _retryWithRefresh(
      (token) => _apiService.deleteReviewResponse(
        token: token ?? '',
        responseId: responseId,
      ),
    );
  }

  Future<List<ReviewCategory>> getReviewCategories() async {
    return await _retryWithRefresh(
      (token) => _apiService.getReviewCategories(token: token),
    );
  }
}
