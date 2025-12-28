// Shop model for auto parts shop
class ShopModel {
  final int id;
  final String name;
  final String address;
  final String phone;
  final String? description;

  ShopModel({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    this.description,
  });

  factory ShopModel.fromJson(Map<String, dynamic> json) {
    return ShopModel(
      id: json['id'] as int,
      name: json['name'] as String,
      address: json['address'] as String,
      phone: json['phone'] as String,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      if (description != null) 'description': description,
    };
  }

  ShopModel copyWith({
    int? id,
    String? name,
    String? address,
    String? phone,
    String? description,
  }) {
    return ShopModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      description: description ?? this.description,
    );
  }
}

// Product reservation/booking model
class ProductReservationModel {
  final int id;
  final ProductReservationProduct product;
  final ProductReservationStatus status;
  final DateTime createdAt;

  ProductReservationModel({
    required this.id,
    required this.product,
    required this.status,
    required this.createdAt,
  });

  factory ProductReservationModel.fromJson(Map<String, dynamic> json) {
    return ProductReservationModel(
      id: json['id'] as int,
      product: ProductReservationProduct.fromJson(
        json['product'] as Map<String, dynamic>,
      ),
      status: _parseStatus(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static ProductReservationStatus _parseStatus(String status) {
    switch (status) {
      case 'pending':
        return ProductReservationStatus.pending;
      case 'confirmed':
        return ProductReservationStatus.confirmed;
      case 'cancelled':
        return ProductReservationStatus.cancelled;
      default:
        return ProductReservationStatus.pending;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product.toJson(),
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// Product info inside reservation
class ProductReservationProduct {
  final int id;
  final int shop;
  final int? category;
  final String name;
  final int year;
  final String description;
  final String? color;
  final String? model;
  final double originalPrice;
  final double discountPrice;

  ProductReservationProduct({
    required this.id,
    required this.shop,
    this.category,
    required this.name,
    required this.year,
    required this.description,
    this.color,
    this.model,
    required this.originalPrice,
    required this.discountPrice,
  });

  factory ProductReservationProduct.fromJson(Map<String, dynamic> json) {
    return ProductReservationProduct(
      id: json['id'] as int,
      shop: json['shop'] as int,
      category: json['category'] as int?,
      name: json['name'] as String,
      year: json['year'] as int,
      description: json['description'] as String,
      color: json['color'] as String?,
      model: json['model'] as String?,
      originalPrice: _parseDouble(json['original_price']),
      discountPrice: _parseDouble(json['discount_price']),
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
      'id': id,
      'shop': shop,
      if (category != null) 'category': category,
      'name': name,
      'year': year,
      'description': description,
      if (color != null) 'color': color,
      if (model != null) 'model': model,
      'original_price': originalPrice.toString(),
      'discount_price': discountPrice.toString(),
    };
  }
}

// Enum for reservation status
enum ProductReservationStatus {
  pending,
  confirmed,
  cancelled,
}

// Extension for localized status names
extension ProductReservationStatusExtension on ProductReservationStatus {
  String get displayName {
    switch (this) {
      case ProductReservationStatus.pending:
        return 'Pending';
      case ProductReservationStatus.confirmed:
        return 'Confirmed';
      case ProductReservationStatus.cancelled:
        return 'Cancelled';
    }
  }
}
