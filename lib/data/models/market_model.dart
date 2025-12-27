class Shop {
  final int id;
  final String name;
  final String address;
  final String phone;
  final String? description;

  Shop({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    this.description,
  });

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      phone: json['phone'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'description': description,
    };
  }
}

class Product {
  final int id;
  final int shop;
  final int? category;
  final String name;
  final int year;
  final String description;
  final String? color;
  final String? model;
  final String? features;
  final String? advantages;
  final String? originalPrice;
  final String? discountPrice;

  // Extra fields that might be in API or synthesized
  final String? image;
  final List<String> images;
  final int stock; // Quantity available
  final double rating;
  final int reviewCount;

  Product({
    required this.id,
    required this.shop,
    this.category,
    required this.name,
    required this.year,
    required this.description,
    this.color,
    this.model,
    this.features,
    this.advantages,
    this.originalPrice,
    required this.discountPrice,
    this.image,
    this.images = const [],
    this.stock = 0,
    this.rating = 0.0,
    this.reviewCount = 0,
  });

  double get priceValue {
    if (discountPrice != null) {
      return double.tryParse(discountPrice!) ?? 0.0;
    }
    if (originalPrice != null) {
      return double.tryParse(originalPrice!) ?? 0.0;
    }
    return 0.0;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      shop: json['shop'],
      category: json['category'],
      name: json['name'],
      year: json['year'],
      description: json['description'],
      color: json['color'],
      model: json['model'],
      features: json['features'],
      advantages: json['advantages'],
      originalPrice: json['original_price'],
      discountPrice: json['discount_price'],
      image: json['image'],
      images:
          (json['images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      stock: json['stock'] ?? 0,
      rating: (json['rating'] as num? ?? 0.0).toDouble(),
      reviewCount: json['review_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop': shop,
      'category': category,
      'name': name,
      'year': year,
      'description': description,
      'color': color,
      'model': model,
      'features': features,
      'advantages': advantages,
      'original_price': originalPrice,
      'discount_price': discountPrice,
      'image': image,
      'images': images,
      'stock': stock,
      'rating': rating,
      'review_count': reviewCount,
    };
  }
}

class ProductReservation {
  final int id;
  final Product product;
  final String status; // 'pending', 'confirmed', 'cancelled'
  final DateTime createdAt;

  ProductReservation({
    required this.id,
    required this.product,
    required this.status,
    required this.createdAt,
  });

  factory ProductReservation.fromJson(Map<String, dynamic> json) {
    return ProductReservation(
      id: json['id'],
      product: Product.fromJson(json['product']),
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
