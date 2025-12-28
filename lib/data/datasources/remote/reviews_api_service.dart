import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:auto_service/core/config/api_config.dart';
import 'package:auto_service/core/utils/api_logger.dart';
import 'package:auto_service/data/models/review_model.dart';
import 'package:auto_service/data/models/auto_service_model.dart';

class ReviewsApiService {
  final String _baseUrl = ApiConfig.apiUrl;

  // ====================== Review Management ======================

  /// Get reviews for a specific service
  Future<List<Review>> getServiceReviews(
    int serviceId, {
    int page = 1,
    String? token,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/service/$serviceId/reviews/',
    ).replace(queryParameters: {'page': page.toString()});

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
        List<dynamic> results = [];

        // Handle nested data structure: { "data": { "results": [...] } }
        if (data is Map) {
          if (data.containsKey('data') && data['data'] is Map) {
            results = (data['data']['results'] as List? ?? []);
          } else if (data.containsKey('results')) {
            results = (data['results'] as List? ?? []);
          }
        } else if (data is List) {
          results = data;
        }

        final reviews = results.map((e) => Review.fromJson(e)).toList();
        ApiLogger.logSuccess('Loaded ${reviews.length} reviews');
        return reviews;
      } else if (response.statusCode == 401) {
        ApiLogger.logError('GET', uri, 'Unauthorized', response: response);
        throw Exception('401');
      }
      ApiLogger.logError('GET', uri, 'Get reviews failed', response: response);
      return [];
    } catch (e, stackTrace) {
      stopwatch.stop();
      ApiLogger.logError('GET', uri, e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get rating statistics for a service
  Future<ServiceRatingStats?> getServiceRatingStats(
    int serviceId, {
    String? token,
  }) async {
    final uri = Uri.parse('$_baseUrl/service/$serviceId/rating-stats/');

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
        final stats = ServiceRatingStats.fromJson(data);
        ApiLogger.logSuccess('Rating stats loaded for service $serviceId');
        return stats;
      } else if (response.statusCode == 401) {
        ApiLogger.logError('GET', uri, 'Unauthorized', response: response);
        throw Exception('401');
      }
      ApiLogger.logError(
        'GET',
        uri,
        'Get rating stats failed',
        response: response,
      );
      return null;
    } catch (e, stackTrace) {
      stopwatch.stop();
      ApiLogger.logError('GET', uri, e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Create a review
  Future<Review?> createReview({
    required String token,
    required ReviewCreate review,
  }) async {
    final uri = Uri.parse('$_baseUrl/service/reviews/');
    final stopwatch = Stopwatch()..start();
    ApiLogger.logRequest(
      'POST',
      uri,
      headers: {'Authorization': 'Bearer $token'},
      body: review.toJson(),
    );

    try {
      final response = await http
          .post(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(review.toJson()),
          )
          .timeout(ApiConfig.connectionTimeout);

      stopwatch.stop();
      ApiLogger.logResponse('POST', uri, response, stopwatch.elapsed);

      if (response.statusCode == 201) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        ApiLogger.logSuccess('Review created successfully');
        return Review.fromJson(data);
      }
      ApiLogger.logError(
        'POST',
        uri,
        'Create review failed',
        response: response,
      );
      return null;
    } catch (e, stackTrace) {
      stopwatch.stop();
      ApiLogger.logError('POST', uri, e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Update a review
  Future<bool> updateReview({
    required String token,
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
    final uri = Uri.parse('$_baseUrl/service/reviews/$reviewId/');
    final body = <String, dynamic>{};

    if (title != null) body['title'] = title;
    if (comment != null) body['comment'] = comment;
    if (overallRating != null) body['overall_rating'] = overallRating;
    if (qualityRating != null) body['quality_rating'] = qualityRating;
    if (priceRating != null) body['price_rating'] = priceRating;
    if (locationRating != null) body['location_rating'] = locationRating;
    if (staffRating != null) body['staff_rating'] = staffRating;
    if (isPublic != null) body['is_public'] = isPublic;

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
        ApiLogger.logSuccess('Review updated successfully');
        return true;
      }
      ApiLogger.logError(
        'PATCH',
        uri,
        'Update review failed',
        response: response,
      );
      return false;
    } catch (e, stackTrace) {
      stopwatch.stop();
      ApiLogger.logError('PATCH', uri, e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Delete a review
  Future<bool> deleteReview({
    required String token,
    required int reviewId,
  }) async {
    final uri = Uri.parse('$_baseUrl/service/reviews/$reviewId/');
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
        ApiLogger.logSuccess('Review deleted successfully');
        return true;
      }
      ApiLogger.logError(
        'DELETE',
        uri,
        'Delete review failed',
        response: response,
      );
      return false;
    } catch (e, stackTrace) {
      stopwatch.stop();
      ApiLogger.logError('DELETE', uri, e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Like or dislike a review
  Future<bool> toggleReviewLike({
    required String token,
    required int reviewId,
    bool isLike = true,
  }) async {
    final uri = Uri.parse('$_baseUrl/service/reviews/like/').replace(
      queryParameters: {
        'review_id': reviewId.toString(),
        'is_like': isLike.toString(),
      },
    );

    final stopwatch = Stopwatch()..start();
    ApiLogger.logRequest(
      'GET',
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    try {
      final response = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(ApiConfig.connectionTimeout);

      stopwatch.stop();
      ApiLogger.logResponse('GET', uri, response, stopwatch.elapsed);

      if (response.statusCode == 200) {
        ApiLogger.logSuccess('Review like toggled successfully');
        return true;
      }
      ApiLogger.logError('GET', uri, 'Toggle like failed', response: response);
      return false;
    } catch (e, stackTrace) {
      stopwatch.stop();
      ApiLogger.logError('GET', uri, e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Create a response to a review (service owner only)
  Future<ReviewResponse?> createReviewResponse({
    required String token,
    required int reviewId,
    required String responseText,
  }) async {
    final uri = Uri.parse('$_baseUrl/service/reviews/response/');
    final body = {'review': reviewId, 'response_text': responseText};

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
        ApiLogger.logSuccess('Review response created successfully');
        return ReviewResponse.fromJson(data);
      }
      ApiLogger.logError(
        'POST',
        uri,
        'Create response failed',
        response: response,
      );
      return null;
    } catch (e, stackTrace) {
      stopwatch.stop();
      ApiLogger.logError('POST', uri, e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Delete a review response (service owner only)
  Future<bool> deleteReviewResponse({
    required String token,
    required int responseId,
  }) async {
    final uri = Uri.parse('$_baseUrl/service/reviews/response/$responseId/');
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
        ApiLogger.logSuccess('Review response deleted successfully');
        return true;
      }
      ApiLogger.logError(
        'DELETE',
        uri,
        'Delete response failed',
        response: response,
      );
      return false;
    } catch (e, stackTrace) {
      stopwatch.stop();
      ApiLogger.logError('DELETE', uri, e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Get review categories
  Future<List<ReviewCategory>> getReviewCategories({String? token}) async {
    final uri = Uri.parse('$_baseUrl/service/reviews/categories/');

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
        final results = data is Map ? (data['results'] as List? ?? []) : data;
        final categories = results
            .map((e) => ReviewCategory.fromJson(e))
            .toList();
        ApiLogger.logSuccess('Loaded ${categories.length} review categories');
        return categories;
      }
      ApiLogger.logError(
        'GET',
        uri,
        'Get categories failed',
        response: response,
      );
      return [];
    } catch (e, stackTrace) {
      stopwatch.stop();
      ApiLogger.logError('GET', uri, e, stackTrace: stackTrace);
      return [];
    }
  }
}
