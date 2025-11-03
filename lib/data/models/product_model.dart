class ProductModel {
  final String id;
  final String name;
  final String? nameKey; // Ключ для перевода названия
  final String description;
  final String? descriptionKey; // Ключ для перевода описания
  final double price;
  final double? oldPrice;
  final String? imageUrl;
  final double rating;
  final int reviewCount;
  final String category;
  final String? brand;
  final bool inStock;
  final String? warranty;
  final String? warrantyKey; // Ключ для перевода гарантии
  final List<String> features;

  final int quantity; // <--- добавляем поле количества
  final String? ownerPhone; // Номер телефона сотрудника, добавившего товар

  ProductModel({
    required this.id,
    required this.name,
    this.nameKey,
    required this.description,
    this.descriptionKey,
    required this.price,
    this.oldPrice,
    this.imageUrl,
    required this.rating,
    this.reviewCount = 0,
    required this.category,
    this.brand,
    this.inStock = true,
    this.warranty,
    this.warrantyKey,
    this.features = const [],
    this.quantity = 1, // по умолчанию 1
    this.ownerPhone, // Номер телефона владельца товара
  });

  double? get discountPercentage {
    if (oldPrice != null && oldPrice! > price) {
      return ((oldPrice! - price) / oldPrice!) * 100;
    }
    return null;
  }

  // Метод для создания копии с изменёнными параметрами
  ProductModel copyWith({
    int? quantity,
    double? price,
    String? ownerPhone,
    bool? inStock,
  }) {
    return ProductModel(
      id: id,
      name: name,
      nameKey: nameKey,
      description: description,
      descriptionKey: descriptionKey,
      price: price ?? this.price,
      oldPrice: oldPrice,
      imageUrl: imageUrl,
      rating: rating,
      reviewCount: reviewCount,
      category: category,
      brand: brand,
      inStock: inStock ?? this.inStock,
      warranty: warranty,
      warrantyKey: warrantyKey,
      features: features,
      quantity: quantity ?? this.quantity,
      ownerPhone: ownerPhone ?? this.ownerPhone,
    );
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      nameKey: json['nameKey'] as String?,
      description: json['description'] as String,
      descriptionKey: json['descriptionKey'] as String?,
      price: (json['price'] as num).toDouble(),
      oldPrice: json['oldPrice'] != null
          ? (json['oldPrice'] as num).toDouble()
          : null,
      imageUrl: json['imageUrl'] as String?,
      rating: (json['rating'] as num).toDouble(),
      reviewCount: json['reviewCount'] as int? ?? 0,
      category: json['category'] as String,
      brand: json['brand'] as String?,
      inStock: json['inStock'] as bool? ?? true,
      warranty: json['warranty'] as String?,
      warrantyKey: json['warrantyKey'] as String?,
      features:
          (json['features'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      quantity: json['quantity'] as int? ?? 1,
      ownerPhone: json['ownerPhone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nameKey': nameKey,
      'description': description,
      'descriptionKey': descriptionKey,
      'price': price,
      'oldPrice': oldPrice,
      'imageUrl': imageUrl,
      'rating': rating,
      'reviewCount': reviewCount,
      'category': category,
      'brand': brand,
      'inStock': inStock,
      'warranty': warranty,
      'warrantyKey': warrantyKey,
      'features': features,
      'quantity': quantity,
      'ownerPhone': ownerPhone,
    };
  }
}
