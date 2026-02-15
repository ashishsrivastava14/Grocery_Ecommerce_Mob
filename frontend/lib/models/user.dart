class User {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String? avatarUrl;
  final String role;
  final bool isActive;
  final bool isVerified;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.avatarUrl,
    required this.role,
    required this.isActive,
    required this.isVerified,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'],
      phone: json['phone'],
      avatarUrl: json['avatar_url'],
      role: json['role'],
      isActive: json['is_active'] ?? true,
      isVerified: json['is_verified'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'phone': phone,
        'avatar_url': avatarUrl,
        'role': role,
        'is_active': isActive,
        'is_verified': isVerified,
        'created_at': createdAt.toIso8601String(),
      };
}

class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final User user;

  AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['access_token'],
      refreshToken: json['refresh_token'],
      expiresIn: json['expires_in'],
      user: User.fromJson(json['user']),
    );
  }
}

class Address {
  final String id;
  final String label;
  final String fullAddress;
  final String city;
  final String state;
  final String postalCode;
  final double? latitude;
  final double? longitude;
  final bool isDefault;

  Address({
    required this.id,
    required this.label,
    required this.fullAddress,
    required this.city,
    required this.state,
    required this.postalCode,
    this.latitude,
    this.longitude,
    this.isDefault = false,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'],
      label: json['label'] ?? 'Home',
      fullAddress: json['full_address'],
      city: json['city'],
      state: json['state'],
      postalCode: json['postal_code'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      isDefault: json['is_default'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'full_address': fullAddress,
        'city': city,
        'state': state,
        'postal_code': postalCode,
        'latitude': latitude,
        'longitude': longitude,
        'is_default': isDefault,
      };
}
