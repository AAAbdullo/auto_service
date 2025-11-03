class GasStationModel {
  final String id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final double rating;
  final String? imageUrl;
  final String? phone;
  final String? address;
  final List<String> fuelTypes;
  final String? workingHours;
  final double? pricePerLiter;
  final String? currency;

  GasStationModel({
    required this.id,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.rating,
    this.imageUrl,
    this.phone,
    this.address,
    this.fuelTypes = const [],
    this.workingHours,
    this.pricePerLiter,
    this.currency,
  });

  factory GasStationModel.fromJson(Map<String, dynamic> json) {
    return GasStationModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      rating: (json['rating'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      fuelTypes:
          (json['fuelTypes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      workingHours: json['workingHours'] as String?,
      pricePerLiter: json['pricePerLiter'] != null
          ? (json['pricePerLiter'] as num).toDouble()
          : null,
      currency: json['currency'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'rating': rating,
      'imageUrl': imageUrl,
      'phone': phone,
      'address': address,
      'fuelTypes': fuelTypes,
      'workingHours': workingHours,
      'pricePerLiter': pricePerLiter,
      'currency': currency,
    };
  }
}
