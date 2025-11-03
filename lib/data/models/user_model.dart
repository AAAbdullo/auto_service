class UserModel {
  final String phone;
  final String? name;
  final String? email;
  final String? avatarUrl;

  UserModel({required this.phone, this.name, this.email, this.avatarUrl});

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      phone: json['phone'] as String,
      name: json['name'] as String?,
      email: json['email'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  UserModel copyWith({
    String? phone,
    String? name,
    String? email,
    String? avatarUrl,
  }) {
    return UserModel(
      phone: phone ?? this.phone,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
