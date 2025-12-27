class ProductModel {
  // API fields
  final int? id;
  final int shopId; // API field: shop
  final int? categoryId; // API field: category
  final String name;
  final int year; // API field: year
  final String description;
  final String? color; // API field: color
  final String? model; // API field: model
  final String? features; // API field: features (text)
  final String? advantages; // API field: advantages (text)
  final double originalPrice; // API field: original_price
  final double discountPrice; // API field: discount_price

  // Legacy fields (для обратной совместимости)
  final String? nameKey;
  final String? descriptionKey;
  final String? imageUrl;
  final double rating;
  final int reviewCount;
  final String category;
  final String? brand;
  final bool inStock;
  final String? warranty;
  final String? warrantyKey;
  final List<String> featuresList;
  final int quantity;
  final String? ownerPhone;

  ProductModel({
    this.id,
    required this.shopId,
    this.categoryId,
    required this.name,
    required this.year,
    required this.description,
    this.color,
    this.model,
    this.features,
    this.advantages,
    required this.originalPrice,
    required this.discountPrice,
    // Legacy fields
    this.nameKey,
    this.descriptionKey,
    this.imageUrl,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.category = '',
    this.brand,
    this.inStock = true,
    this.warranty,
    this.warrantyKey,
    this.featuresList = const [],
    this.quantity = 1,
    this.ownerPhone,
  });

  // Геттеры для удобства
  double get price => discountPrice;
  double? get oldPrice => originalPrice > discountPrice ? originalPrice : null;

  double? get discountPercentage {
    if (originalPrice > discountPrice) {
      return ((originalPrice - discountPrice) / originalPrice) * 100;
    }
    return null;
  }

  ProductModel copyWith({
    int? id,
    int? shopId,
    int? categoryId,
    String? name,
    int? year,
    String? description,
    String? color,
    String? model,
    String? features,
    String? advantages,
    double? originalPrice,
    double? discountPrice,
    int? quantity,
    String? ownerPhone,
    bool? inStock,
  }) {
    return ProductModel(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      year: year ?? this.year,
      description: description ?? this.description,
      color: color ?? this.color,
      model: model ?? this.model,
      features: features ?? this.features,
      advantages: advantages ?? this.advantages,
      originalPrice: originalPrice ?? this.originalPrice,
      discountPrice: discountPrice ?? this.discountPrice,
      // Legacy fields
      nameKey: nameKey,
      descriptionKey: descriptionKey,
      imageUrl: imageUrl,
      rating: rating,
      reviewCount: reviewCount,
      category: category,
      brand: brand,
      inStock: inStock ?? this.inStock,
      warranty: warranty,
      warrantyKey: warrantyKey,
      featuresList: featuresList,
      quantity: quantity ?? this.quantity,
      ownerPhone: ownerPhone ?? this.ownerPhone,
    );
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // Поддержка API формата
    if (json.containsKey('shop')) {
      return ProductModel(
        id: json['id'] as int?,
        shopId: json['shop'] as int,
        categoryId: json['category'] as int?,
        name: json['name'] as String,
        year: json['year'] as int,
        description: json['description'] as String,
        color: json['color'] as String?,
        model: json['model'] as String?,
        features: json['features'] as String?,
        advantages: json['advantages'] as String?,
        originalPrice: _parseDouble(json['original_price']),
        discountPrice: _parseDouble(json['discount_price']),
        imageUrl: json['imageUrl'] as String?,
        rating: _parseDouble(json['rating'] ?? 0.0),
        reviewCount: json['reviewCount'] as int? ?? 0,
        category: json['category']?.toString() ?? '',
        inStock: json['inStock'] as bool? ?? true,
      );
    }

    // Поддержка старого формата
    return ProductModel(
      id: int.tryParse(json['id']?.toString() ?? ''),
      shopId: 0, // Default для старого формата
      name: json['name'] as String,
      year: 2024, // Default для старого формата
      description: json['description'] as String,
      originalPrice: _parseDouble(json['oldPrice'] ?? json['price']),
      discountPrice: _parseDouble(json['price']),
      nameKey: json['nameKey'] as String?,
      descriptionKey: json['descriptionKey'] as String?,
      imageUrl: json['imageUrl'] as String?,
      rating: _parseDouble(json['rating']),
      reviewCount: json['reviewCount'] as int? ?? 0,
      category: json['category'] as String? ?? '',
      brand: json['brand'] as String?,
      inStock: json['inStock'] as bool? ?? true,
      warranty: json['warranty'] as String?,
      warrantyKey: json['warrantyKey'] as String?,
      featuresList:
          (json['features'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      quantity: json['quantity'] as int? ?? 1,
      ownerPhone: json['ownerPhone'] as String?,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'shop': shopId,
      if (categoryId != null) 'category': categoryId,
      'name': name,
      'year': year,
      'description': description,
      if (color != null) 'color': color,
      if (model != null) 'model': model,
      if (features != null) 'features': features,
      if (advantages != null) 'advantages': advantages,
      'original_price': originalPrice.toString(),
      'discount_price': discountPrice.toString(),
      // Legacy fields
      if (nameKey != null) 'nameKey': nameKey,
      if (descriptionKey != null) 'descriptionKey': descriptionKey,
      'price': discountPrice,
      if (oldPrice != null) 'oldPrice': oldPrice,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'rating': rating,
      'reviewCount': reviewCount,
      'category': category,
      if (brand != null) 'brand': brand,
      'inStock': inStock,
      if (warranty != null) 'warranty': warranty,
      if (warrantyKey != null) 'warrantyKey': warrantyKey,
      'features': featuresList,
      'quantity': quantity,
      if (ownerPhone != null) 'ownerPhone': ownerPhone,
    };
  }
}
