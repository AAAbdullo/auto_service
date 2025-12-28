class UserModel {
  final int? id;
  final String phone;
  final String? fullName; // API field: full_name
  final String? name; // Сохраняем для обратной совместимости
  final String? email; // Сохраняем для обратной совместимости
  final String? image; // API field: image (URL)
  final String? avatarUrl; // Сохраняем для обратной совместимости
  final String? telegram; // API field: telegram
  final DateTime? createdAt; // API field: created_at
  final DateTime? updatedAt; // API field: update_at
  final bool? isSuperuser; // API field: is_superuser

  UserModel({
    this.id,
    required this.phone,
    this.fullName,
    this.name,
    this.email,
    this.image,
    this.avatarUrl,
    this.telegram,
    this.createdAt,
    this.updatedAt,
    this.isSuperuser,
  });

  // Геттер для получения имени (приоритет fullName, потом name)
  String get displayName => fullName ?? name ?? 'User';

  // Геттер для получения аватара (приоритет image, потом avatarUrl)
  String? get displayAvatar => image ?? avatarUrl;

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'phone': phone,
      if (fullName != null) 'full_name': fullName,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (image != null) 'image': image,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (telegram != null) 'telegram': telegram,
      if (createdAt != null) 'created_at': createdAt?.toIso8601String(),
      if (updatedAt != null) 'update_at': updatedAt?.toIso8601String(),
      if (isSuperuser != null) 'is_superuser': isSuperuser,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int?,
      phone: json['phone'] as String,
      // Поддержка обоих форматов: full_name (API) и name (старый)
      fullName: json['full_name'] as String?,
      name: json['name'] as String?,
      email: json['email'] as String?,
      // Поддержка обоих форматов: image (API) и avatarUrl (старый)
      image: json['image'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      telegram: json['telegram'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['update_at'] != null
          ? DateTime.tryParse(json['update_at'] as String)
          : null,
      isSuperuser: json['is_superuser'] as bool?,
    );
  }

  UserModel copyWith({
    int? id,
    String? phone,
    String? fullName,
    String? name,
    String? email,
    String? image,
    String? avatarUrl,
    String? telegram,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSuperuser,
  }) {
    return UserModel(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      fullName: fullName ?? this.fullName,
      name: name ?? this.name,
      email: email ?? this.email,
      image: image ?? this.image,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      telegram: telegram ?? this.telegram,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSuperuser: isSuperuser ?? this.isSuperuser,
    );
  }
}
