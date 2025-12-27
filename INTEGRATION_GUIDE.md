# Backend Optimization - Integration Guide

This guide shows how to integrate the new utilities into your existing code.

---

## 1. Using ReviewCategoryProvider

### In main.dart or app.dart - Add to MultiProvider:

```dart
import 'package:auto_service/presentation/providers/review_category_provider.dart';

MultiProvider(
  providers: [
    // ... existing providers
    ChangeNotifierProvider(
      create: (_) => ReviewCategoryProvider(),
    ),
  ],
  child: MyApp(),
)
```

### In review creation screen:

```dart
import 'package:auto_service/presentation/providers/review_category_provider.dart';

class ReviewFormScreen extends StatefulWidget {
  @override
  State<ReviewFormScreen> createState() => _ReviewFormScreenState();
}

class _ReviewFormScreenState extends State<ReviewFormScreen> {
  List<int> _selectedCategoryIds = [];

  @override
  void initState() {
    super.initState();
    // Load categories on init
    Future.microtask(() {
      final provider = context.read<ReviewCategoryProvider>();
      provider.initializeCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReviewCategoryProvider>(
      builder: (context, categoryProvider, _) {
        if (categoryProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          children: [
            // ... other form fields
            
            // Categories selection
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Select Categories'),
                  Wrap(
                    children: categoryProvider.categories.map((category) {
                      final isSelected = _selectedCategoryIds.contains(category.id);
                      return Padding(
                        padding: const EdgeInsets.all(4),
                        child: FilterChip(
                          label: Text(category.name),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedCategoryIds.add(category.id);
                              } else {
                                _selectedCategoryIds.remove(category.id);
                              }
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
```

---

## 2. Using RatingsProvider

### In main.dart - Add to MultiProvider:

```dart
import 'package:auto_service/presentation/providers/ratings_provider.dart';

MultiProvider(
  providers: [
    // ... existing providers
    ChangeNotifierProvider(
      create: (_) => RatingsProvider(),
    ),
  ],
  child: MyApp(),
)
```

### In service details screen:

```dart
import 'package:auto_service/presentation/providers/ratings_provider.dart';

class ServiceDetailsScreen extends StatefulWidget {
  final int serviceId;
  
  const ServiceDetailsScreen({required this.serviceId});

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  @override
  void initState() {
    super.initState();
    // Load ratings on init
    Future.microtask(() {
      final ratingProvider = context.read<RatingsProvider>();
      ratingProvider.fetchRatingStats(widget.serviceId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RatingsProvider>(
      builder: (context, ratingProvider, _) {
        final stats = ratingProvider.getRatingStats(widget.serviceId);
        final isLoading = ratingProvider.isLoading(widget.serviceId);

        return ListView(
          children: [
            // ... other service details
            
            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              )
            else if (stats != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rating Statistics',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    
                    // Overall rating
                    Text('Average Rating: ${stats.averageRating.toStringAsFixed(1)}/5'),
                    Text('Total Reviews: ${stats.totalReviews}'),
                    
                    // Rating breakdown
                    if (stats.ratingBreakdown != null) ...[
                      const SizedBox(height: 16),
                      Text('Rating Breakdown:'),
                      ...stats.ratingBreakdown!.entries.map((entry) {
                        final stars = entry.key;
                        final count = entry.value;
                        return Text('$stars★: $count reviews');
                      }).toList(),
                    ],
                    
                    // Detailed ratings
                    if (stats.detailedRatings != null) ...[
                      const SizedBox(height: 16),
                      Text('Detailed Ratings:'),
                      Text('Quality: ${(stats.detailedRatings!['quality'] ?? 0).toStringAsFixed(1)}'),
                      Text('Price: ${(stats.detailedRatings!['price'] ?? 0).toStringAsFixed(1)}'),
                      Text('Location: ${(stats.detailedRatings!['location'] ?? 0).toStringAsFixed(1)}'),
                      Text('Staff: ${(stats.detailedRatings!['staff'] ?? 0).toStringAsFixed(1)}'),
                    ],
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
```

---

## 3. Using RetryHelper

### In repositories:

```dart
import 'package:auto_service/core/utils/retry_helper.dart';
import 'package:auto_service/core/utils/api_exceptions.dart';

class AutoServicesRepository {
  Future<List<AutoServiceModel>> getAllServices({
    int page = 1,
    String? search,
  }) async {
    return RetryHelper.retry(
      () async {
        final token = await _localStorage.getAccessToken();
        return await _apiService.getAllServices(
          page: page,
          search: search,
          token: token,
        );
      },
      onRetry: (attempt, delay) {
        ApiLogger.logWarning(
          'Retry attempt $attempt for getAllServices, waiting ${delay.inMilliseconds}ms',
        );
      },
    );
  }
}
```

---

## 4. Using DataValidator

### In model fromJson:

```dart
import 'package:auto_service/core/utils/data_validator.dart';

class Review {
  final int id;
  final int service;
  final String title;
  final String comment;
  final int overallRating;

  Review({
    required this.id,
    required this.service,
    required this.title,
    required this.comment,
    required this.overallRating,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    try {
      return Review(
        id: DataValidator.validateId(json['id'] as int?, 'id'),
        service: DataValidator.validateId(json['service'] as int?, 'service'),
        title: DataValidator.validateNonEmptyString(json['title'] as String?, 'title'),
        comment: DataValidator.validateNonEmptyString(json['comment'] as String?, 'comment'),
        overallRating: DataValidator.validateRating(json['overall_rating'] as int?),
      );
    } catch (e) {
      throw ApiException(
        message: 'Failed to parse Review: ${e.toString()}',
        errorCode: ApiErrorCode.invalidResponse,
        originalError: e,
      );
    }
  }
}
```

---

## 5. Using HttpClientManager

### In API services (if not already using http package):

```dart
import 'package:auto_service/core/utils/http_client_manager.dart';

class MyApiService {
  Future<List<Item>> getItems() async {
    final client = HttpClientManager.client; // Reuse singleton
    
    try {
      final response = await client
          .get(uri, headers: headers)
          .timeout(ApiConfig.connectionTimeout);
      
      // Handle response
      return parseItems(response);
    } finally {
      // Client stays open for reuse!
    }
  }
}
```

---

## 6. Using HTTP Status Codes Enum

### In API response handling:

```dart
import 'package:auto_service/core/constants/http_status_codes.dart';
import 'package:auto_service/core/utils/api_exceptions.dart';

Future<T> handleResponse<T>(http.Response response, T Function() parser) {
  final statusCode = HttpStatusCode.fromCode(response.statusCode);
  
  if (statusCode?.isSuccess ?? false) {
    return parser();
  }
  
  if (statusCode?.isClientError ?? false) {
    if (response.statusCode == 401) {
      throw AuthenticationException();
    } else if (response.statusCode == 403) {
      throw AuthorizationException();
    } else if (response.statusCode == 404) {
      throw NotFoundException();
    }
  }
  
  if (statusCode?.isServerError ?? false) {
    throw ServerException(
      message: 'Server error: ${statusCode?.message}',
      statusCode: response.statusCode,
    );
  }
  
  throw ApiException(
    message: 'Unknown error: ${statusCode?.message}',
    statusCode: response.statusCode,
  );
}
```

---

## 7. Using CacheManager

### For general data caching:

```dart
import 'package:auto_service/core/utils/cache_manager.dart';

class ServiceCacheManager {
  static final CacheManager<int, AutoServiceModel> _cache = CacheManager();

  static void cacheService(int serviceId, AutoServiceModel service) {
    _cache.put(serviceId, service, ttl: const Duration(hours: 1));
  }

  static AutoServiceModel? getCachedService(int serviceId) {
    return _cache.get(serviceId);
  }

  static void clearServiceCache(int serviceId) {
    _cache.remove(serviceId);
  }
}
```

### For token caching (in AuthProvider):

```dart
import 'package:auto_service/core/utils/cache_manager.dart';

class AuthProvider with ChangeNotifier {
  final _tokenCache = TokenCacheManager();

  Future<String?> getAccessToken() async {
    // Check cache first
    final cached = _tokenCache.getCachedToken();
    if (cached != null) return cached;

    // Get from storage
    final token = await _localStorage.getAccessToken();
    if (token != null) {
      _tokenCache.cacheToken(token);
    }
    return token;
  }

  Future<void> logout() async {
    // Clear token cache on logout
    _tokenCache.clearCache();
    await _localStorage.clearAuthToken();
    notifyListeners();
  }
}
```

---

## 8. Custom Exceptions in Catch Blocks

```dart
import 'package:auto_service/core/utils/api_exceptions.dart';

try {
  final services = await repository.getAllServices();
} on AuthenticationException catch (e) {
  // Handle authentication - redirect to login
  Navigator.of(context).pushReplacementNamed('/login');
} on TimeoutException catch (e) {
  // Handle timeout - show retry button
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(e.message),
      action: SnackBarAction(
        label: 'Retry',
        onPressed: () { /* retry */ },
      ),
    ),
  );
} on NetworkException catch (e) {
  // Handle network error
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Network connection error')),
  );
} on ApiException catch (e) {
  // Handle other API errors
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(e.message)),
  );
}
```

---

## 🎯 Integration Priority

1. **High Priority** (Do First):
   - Add providers to MultiProvider
   - Add token caching to AuthProvider
   - Wrap critical API calls with RetryHelper

2. **Medium Priority** (Do Next):
   - Add UI for categories in review creation
   - Add UI for ratings in service details
   - Add like/dislike buttons for reviews

3. **Low Priority** (Nice to Have):
   - Add validation to model fromJson
   - Implement review response UI
   - Implement payment endpoints

---

**All utilities are ready to use! Just integrate them into your existing code.** ✨
