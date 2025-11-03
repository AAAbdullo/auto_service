/// Модель детального бронирования для сотрудников автосервиса
class BookingDetailsModel {
  final String id;
  final String productId;
  final String productName;
  final String? productImage;
  final int quantity;
  final double pricePerUnit;
  final double totalPrice;
  final String customerPhone;
  final String employeePhone; // Телефон сотрудника, чей товар забронирован
  final DateTime bookedAt;
  final bool isNew; // Флаг для уведомления о новых бронированиях

  BookingDetailsModel({
    required this.id,
    required this.productId,
    required this.productName,
    this.productImage,
    required this.quantity,
    required this.pricePerUnit,
    required this.totalPrice,
    required this.customerPhone,
    required this.employeePhone,
    required this.bookedAt,
    this.isNew = true,
  });

  /// Копирование с изменением полей
  BookingDetailsModel copyWith({
    String? id,
    String? productId,
    String? productName,
    String? productImage,
    int? quantity,
    double? pricePerUnit,
    double? totalPrice,
    String? customerPhone,
    String? employeePhone,
    DateTime? bookedAt,
    bool? isNew,
  }) {
    return BookingDetailsModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      quantity: quantity ?? this.quantity,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      totalPrice: totalPrice ?? this.totalPrice,
      customerPhone: customerPhone ?? this.customerPhone,
      employeePhone: employeePhone ?? this.employeePhone,
      bookedAt: bookedAt ?? this.bookedAt,
      isNew: isNew ?? this.isNew,
    );
  }

  /// Из JSON
  factory BookingDetailsModel.fromJson(Map<String, dynamic> json) {
    return BookingDetailsModel(
      id: json['id'] as String,
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      productImage: json['productImage'] as String?,
      quantity: json['quantity'] as int,
      pricePerUnit: (json['pricePerUnit'] as num).toDouble(),
      totalPrice: (json['totalPrice'] as num).toDouble(),
      customerPhone: json['customerPhone'] as String,
      employeePhone: json['employeePhone'] as String,
      bookedAt: DateTime.parse(json['bookedAt'] as String),
      isNew: json['isNew'] as bool? ?? true,
    );
  }

  /// В JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'quantity': quantity,
      'pricePerUnit': pricePerUnit,
      'totalPrice': totalPrice,
      'customerPhone': customerPhone,
      'employeePhone': employeePhone,
      'bookedAt': bookedAt.toIso8601String(),
      'isNew': isNew,
    };
  }
}







