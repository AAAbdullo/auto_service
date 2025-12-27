class UserProfile {
  final int id;
  final String fullName;
  final String phone;
  final String? image;
  final String? telegram;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSuperuser;

  UserProfile({
    required this.id,
    required this.fullName,
    required this.phone,
    this.image,
    this.telegram,
    required this.createdAt,
    required this.updatedAt,
    required this.isSuperuser,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      fullName: json['full_name'] ?? '',
      phone: json['phone'] ?? '',
      image: json['image'],
      telegram: json['telegram'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(
        json['update_at'],
      ), // Note: API says 'update_at' not 'updated_at'
      isSuperuser: json['is_superuser'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'phone': phone,
      'image': image,
      'telegram': telegram,
      'created_at': createdAt.toIso8601String(),
      'update_at': updatedAt.toIso8601String(),
      'is_superuser': isSuperuser,
    };
  }
}

class UserImage {
  final int id;
  final String? image;

  UserImage({required this.id, this.image});

  factory UserImage.fromJson(Map<String, dynamic> json) {
    return UserImage(id: json['id'], image: json['image']);
  }
}
