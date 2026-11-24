import 'package:agrochat_app/core/constants/user_role.dart';

/// Represents a registered AgroChat user profile.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.role,
    required this.preferredLanguage,
    required this.isActive,
    required this.createdAt,
  });

  final int id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final UserRole role;
  final String preferredLanguage;
  final bool isActive;
  final DateTime createdAt;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as int,
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phone_number'] as String? ?? '',
      role: UserRole.fromApiValue(json['role'] as String? ?? 'farmer'),
      preferredLanguage: json['preferred_language'] as String? ?? 'English',
      isActive: json['is_active'] as bool? ?? true,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber,
      'role': role.apiValue,
      'preferred_language': preferredLanguage,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  AuthUser copyWith({
    String? fullName,
    String? phoneNumber,
    String? preferredLanguage,
  }) {
    return AuthUser(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      isActive: isActive,
      createdAt: createdAt,
    );
  }
}

/// Represents an active authenticated session containing the JWT access token and user info.
class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
  });

  final String accessToken;
  final String tokenType;
  final int expiresIn;
  final AuthUser user;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String? ?? 'bearer',
      expiresIn: json['expires_in'] as int? ?? 86400,
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'token_type': tokenType,
      'expires_in': expiresIn,
      'user': user.toJson(),
    };
  }
}
