class AutoServiceModel {
  final String id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;

  // Rating fields from API
  final double rating; // Старое поле для совместимости
  final double? averageRating; // API: average_rating
  final int? reviewCount; // API: review_count
  final int? verifiedReviewCount; // API: verified_review_count
  final Map<String, dynamic>? ratingBreakdown; // API: rating_breakdown
  final Map<String, dynamic>? detailedRatings; // API: detailed_ratings

  final String? imageUrl;
  final String? phone;
  final String? address;
  final List<String> services;
  final String? workingHours;

  // New API fields
  final ServiceCategory? category; // API: category object
  final String? status; // API: status (pending/enabled/disabled)
  final String? startTime; // API: start_time
  final String? endTime; // API: end_time
  final List<int>? workingDays; // API: working_days [1,2,3,4,5]
  final List<ExtraService>? extraServices; // API: extra_services
  final bool isActive; // API: is_active
  final DateTime? createdAt; // API: created_at
  final String? telegram; // API: telegram
  final double? distance; // API: distance (from nearest query)

  final int? ownerId;
  final List<ServiceImage> images;

  AutoServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.rating,
    this.averageRating,
    this.reviewCount,
    this.verifiedReviewCount,
    this.ratingBreakdown,
    this.detailedRatings,
    this.imageUrl,
    this.phone,
    this.address,
    this.services = const [],
    this.workingHours,
    this.category,
    this.status,
    this.startTime,
    this.endTime,
    this.workingDays,
    this.extraServices,
    this.isActive = true,
    this.createdAt,
    this.telegram,
    this.distance,
    this.ownerId,
    this.images = const [],
  });

  // Геттер для получения актуального рейтинга
  double get displayRating => averageRating ?? rating;

  // Геттер для получения количества отзывов
  int get displayReviewCount => reviewCount ?? 0;

  factory AutoServiceModel.fromJson(Map<String, dynamic> json) {
    return AutoServiceModel(
      id: json['id'].toString(),
      name: json['name'] as String? ?? 'Unknown Service',
      description: json['description'] as String? ?? '',

      // Support both possible API field names
      latitude:
          (num.tryParse(json['lat']?.toString() ?? '') ??
                  num.tryParse(json['latitude']?.toString() ?? '') ??
                  0.0)
              .toDouble(),
      longitude:
          (num.tryParse(json['lon']?.toString() ?? '') ??
                  num.tryParse(json['longitude']?.toString() ?? '') ??
                  0.0)
              .toDouble(),

      // Rating fields
      rating:
          (num.tryParse(json['overall_rating']?.toString() ?? '') ??
                  num.tryParse(json['rating']?.toString() ?? '') ??
                  num.tryParse(json['average_rating']?.toString() ?? '') ??
                  0.0)
              .toDouble(),
      averageRating: json['average_rating'] != null
          ? (num.tryParse(json['average_rating'].toString()) ?? 0.0).toDouble()
          : null,
      reviewCount: json['review_count'] as int?,
      verifiedReviewCount: json['verified_review_count'] as int?,
      ratingBreakdown: json['rating_breakdown'] as Map<String, dynamic>?,
      detailedRatings: json['detailed_ratings'] as Map<String, dynamic>?,

      // Contact info
      imageUrl: json['image'] ?? json['imageUrl'] as String?,
      phone: json['phone_number'] ?? json['phone'] as String?,
      address: json['address'] as String?,
      telegram: json['telegram'] as String?,

      // Working hours
      services:
          (json['services'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      workingHours: json['working_hours'] ?? json['workingHours'] as String?,
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      workingDays: (json['working_days'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList(),

      // New API fields
      category: json['category'] != null
          ? ServiceCategory.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      status: json['status'] as String?,
      extraServices: (json['extra_services'] as List<dynamic>?)
          ?.map((e) => ExtraService.fromJson(e as Map<String, dynamic>))
          .toList(),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      distance: json['distance'] != null
          ? (num.tryParse(json['distance'].toString()) ?? 0.0).toDouble()
          : null,

      ownerId: int.tryParse(json['owner']?.toString() ?? ''),
      images:
          (json['images'] as List<dynamic>?)
              ?.map((e) => ServiceImage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'lat': latitude,
      'lon': longitude,
      'latitude': latitude,
      'longitude': longitude,
      'rating': rating,
      if (averageRating != null) 'average_rating': averageRating,
      if (reviewCount != null) 'review_count': reviewCount,
      if (verifiedReviewCount != null)
        'verified_review_count': verifiedReviewCount,
      if (ratingBreakdown != null) 'rating_breakdown': ratingBreakdown,
      if (detailedRatings != null) 'detailed_ratings': detailedRatings,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'phone_number': phone,
      'address': address,
      'services': services,
      if (workingHours != null) 'working_hours': workingHours,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (workingDays != null) 'working_days': workingDays,
      if (category != null) 'category': category!.toJson(),
      if (status != null) 'status': status,
      if (extraServices != null)
        'extra_services': extraServices!.map((e) => e.toJson()).toList(),
      'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (telegram != null) 'telegram': telegram,
      if (distance != null) 'distance': distance,
      if (ownerId != null) 'owner': ownerId,
      'images': images
          .map(
            (e) => {
              'id': e.id,
              'image': e.image,
              'image_url': e.imageUrl,
              'is_active': e.isActive,
            },
          )
          .toList(),
    };
  }

  AutoServiceModel copyWith({
    String? name,
    String? description,
    String? phone,
    String? address,
    String? telegram,
    String? status,
    bool? isActive,
    List<ExtraService>? extraServices,
  }) {
    return AutoServiceModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      latitude: latitude,
      longitude: longitude,
      rating: rating,
      averageRating: averageRating,
      reviewCount: reviewCount,
      verifiedReviewCount: verifiedReviewCount,
      ratingBreakdown: ratingBreakdown,
      detailedRatings: detailedRatings,
      imageUrl: imageUrl,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      services: services,
      workingHours: workingHours,
      category: category,
      status: status ?? this.status,
      startTime: startTime,
      endTime: endTime,
      workingDays: workingDays,
      extraServices: extraServices ?? this.extraServices,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      telegram: telegram ?? this.telegram,
      distance: distance,
      ownerId: ownerId,
      images: images,
    );
  }
}

class ServiceImage {
  final int id;
  final String image;
  final String? imageUrl;
  final bool isActive;
  final DateTime? createdAt;

  ServiceImage({
    required this.id,
    required this.image,
    this.imageUrl,
    this.isActive = true,
    this.createdAt,
  });

  /// Получить полный URL изображения
  String getFullImageUrl() {
    const baseUrl = 'http://avtomakon.airi.uz';

    // Приоритет: imageUrl > image
    final url = imageUrl ?? image;

    // Если URL уже полный (начинается с http), возвращаем как есть
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    // Если начинается с /, добавляем baseUrl
    if (url.startsWith('/')) {
      return '$baseUrl$url';
    }

    // Иначе добавляем baseUrl с /
    return '$baseUrl/$url';
  }

  factory ServiceImage.fromJson(Map<String, dynamic> json) {
    return ServiceImage(
      id: json['id'],
      image: json['image'],
      imageUrl: json['image_url'],
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image': image,
      if (imageUrl != null) 'image_url': imageUrl,
      'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}

class ServiceRatingStats {
  final int serviceId;
  final double averageRating;
  final int totalReviews;
  final Map<String, dynamic> ratingBreakdown;
  final Map<String, dynamic> detailedRatings;

  ServiceRatingStats({
    required this.serviceId,
    required this.averageRating,
    required this.totalReviews,
    required this.ratingBreakdown,
    required this.detailedRatings,
  });

  factory ServiceRatingStats.fromJson(Map<String, dynamic> json) {
    return ServiceRatingStats(
      serviceId: json['service_id'],
      averageRating: (json['average_rating'] as num).toDouble(),
      totalReviews: json['total_reviews'],
      ratingBreakdown: json['rating_breakdown'],
      detailedRatings: json['detailed_ratings'],
    );
  }
}

class ExtraService {
  final int id;
  final String name;

  ExtraService({required this.id, required this.name});

  factory ExtraService.fromJson(Map<String, dynamic> json) {
    return ExtraService(id: json['id'], name: json['name']);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}

class ServiceCategory {
  final int id;
  final String name;
  final String slug;
  final String? icon;

  ServiceCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      icon: json['icon'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      if (icon != null) 'icon': icon,
    };
  }
}
