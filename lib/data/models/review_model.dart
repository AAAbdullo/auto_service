class Review {
  final int id;
  final int service;
  final String serviceName;
  final int user;
  final String userName;
  final String title;
  final String comment;
  final int overallRating;
  final int qualityRating;
  final int priceRating;
  final int locationRating;
  final int staffRating;
  final bool isVerified;
  final bool isPublic;
  final bool isFlagged;
  final String? flaggedReason;
  final List<ReviewCategory> reviewCategories;
  final List<ReviewResponse> responses;
  final String? averageDetailedRating;
  final int likesCount;
  final int dislikesCount;
  final bool userLike;
  final DateTime createdAt;
  final DateTime updatedAt;

  Review({
    required this.id,
    required this.service,
    required this.serviceName,
    required this.user,
    required this.userName,
    required this.title,
    required this.comment,
    required this.overallRating,
    required this.qualityRating,
    required this.priceRating,
    required this.locationRating,
    required this.staffRating,
    this.isVerified = false,
    this.isPublic = true,
    this.isFlagged = false,
    this.flaggedReason,
    this.reviewCategories = const [],
    this.responses = const [],
    this.averageDetailedRating,
    this.likesCount = 0,
    this.dislikesCount = 0,
    this.userLike = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: _toInt(json['id']),
      service: _toInt(json['service']),
      serviceName: (json['service_name'] ?? 'Unknown Service') as String,
      user: _toInt(json['user']),
      userName: (json['user_name'] ?? 'Anonymous') as String,
      title: (json['title'] ?? '') as String,
      comment: (json['comment'] ?? '') as String,
      overallRating: _toInt(json['overall_rating']),
      qualityRating: _toInt(json['quality_rating']),
      priceRating: _toInt(json['price_rating']),
      locationRating: _toInt(json['location_rating']),
      staffRating: _toInt(json['staff_rating']),
      isVerified: json['is_verified'] ?? false,
      isPublic: json['is_public'] ?? true,
      isFlagged: json['is_flagged'] ?? false,
      flaggedReason: json['flagged_reason'] != null
          ? json['flagged_reason'] as String
          : null,
      reviewCategories:
          (json['review_categories'] as List?)
              ?.map((e) => ReviewCategory.fromJson(e))
              .toList() ??
          [],
      responses:
          (json['responses'] as List?)
              ?.map((e) => ReviewResponse.fromJson(e))
              .toList() ??
          [],
      averageDetailedRating: json['average_detailed_rating']?.toString(),
      likesCount: json['likes_count'] ?? 0,
      dislikesCount: json['dislikes_count'] ?? 0,
      userLike: json['user_like'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  /// Helper method to convert double/int/String to int
  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class ReviewCreate {
  final int service;
  final String title;
  final String comment;
  final int overallRating;
  final int qualityRating;
  final int priceRating;
  final int locationRating;
  final int staffRating;
  final List<int>? reviewCategoryIds;

  ReviewCreate({
    required this.service,
    required this.title,
    required this.comment,
    required this.overallRating,
    required this.qualityRating,
    required this.priceRating,
    required this.locationRating,
    required this.staffRating,
    this.reviewCategoryIds,
  });

  /// Validate that all required fields are not empty
  String? validate() {
    if (title.trim().isEmpty) {
      return 'Title cannot be empty';
    }
    if (comment.trim().isEmpty) {
      return 'Comment cannot be empty';
    }
    if (overallRating < 1 || overallRating > 5) {
      return 'Overall rating must be between 1 and 5';
    }
    if (qualityRating < 1 || qualityRating > 5) {
      return 'Quality rating must be between 1 and 5';
    }
    if (priceRating < 1 || priceRating > 5) {
      return 'Price rating must be between 1 and 5';
    }
    if (locationRating < 1 || locationRating > 5) {
      return 'Location rating must be between 1 and 5';
    }
    if (staffRating < 1 || staffRating > 5) {
      return 'Staff rating must be between 1 and 5';
    }
    return null; // No validation errors
  }

  Map<String, dynamic> toJson() {
    return {
      'service': service,
      'title': title,
      'comment': comment,
      'overall_rating': overallRating,
      'quality_rating': qualityRating,
      'price_rating': priceRating,
      'location_rating': locationRating,
      'staff_rating': staffRating,
      if (reviewCategoryIds != null) 'review_category_ids': reviewCategoryIds,
    };
  }
}

class ReviewCategory {
  final int id;
  final String name;
  final String? description;
  final bool isActive;

  ReviewCategory({
    required this.id,
    required this.name,
    this.description,
    this.isActive = true,
  });

  factory ReviewCategory.fromJson(Map<String, dynamic> json) {
    return ReviewCategory(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      isActive: json['is_active'] ?? true,
    );
  }
}

class ReviewResponse {
  final int id;
  final int review;
  final int owner;
  final String ownerName;
  final String responseText;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReviewResponse({
    required this.id,
    required this.review,
    required this.owner,
    required this.ownerName,
    required this.responseText,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReviewResponse.fromJson(Map<String, dynamic> json) {
    return ReviewResponse(
      id: json['id'],
      review: json['review'],
      owner: json['owner'],
      ownerName: json['owner_name'],
      responseText: json['response_text'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}
