import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:agrochat_app/core/constants/api_endpoints.dart';
import 'package:agrochat_app/core/constants/user_role.dart';
import 'package:agrochat_app/core/network/api_client.dart';
import 'package:agrochat_app/features/auth/models/auth_user.dart';

/// Repository managing user authentication, registration, JWT tokens, and session persistence.
class AuthRepository {
  AuthRepository({ApiClient? apiClient, SharedPreferences? preferences})
    : _apiClient = apiClient ?? ApiClient(),
      _prefs = preferences;

  final ApiClient _apiClient;
  SharedPreferences? _prefs;

  static const String _keyToken = 'agrochat_access_token';
  static const String _keyUser = 'agrochat_user_json';
  static const String _keyTokenType = 'agrochat_token_type';
  static const String _keyExpiresIn = 'agrochat_expires_in';

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  /// Authenticate a Farmer account.
  Future<AuthSession> loginFarmer({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.loginFarmer,
      body: {'email': email.trim().toLowerCase(), 'password': password},
    );
    final session = AuthSession.fromJson(response as Map<String, dynamic>);
    await saveSession(session);
    return session;
  }

  /// Authenticate an Agricultural Officer account.
  Future<AuthSession> loginOfficer({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.loginOfficer,
      body: {'email': email.trim().toLowerCase(), 'password': password},
    );
    final session = AuthSession.fromJson(response as Map<String, dynamic>);
    await saveSession(session);
    return session;
  }

  /// Convenience login method routing to the role-specific endpoint.
  Future<AuthSession> login({
    required UserRole role,
    required String email,
    required String password,
  }) {
    if (role == UserRole.farmer) {
      return loginFarmer(email: email, password: password);
    } else {
      return loginOfficer(email: email, password: password);
    }
  }

  /// Register a new Farmer account.
  Future<AuthSession> registerFarmer({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required String preferredLanguage,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.registerFarmer,
      body: {
        'full_name': fullName.trim(),
        'email': email.trim().toLowerCase(),
        'phone_number': phoneNumber.trim(),
        'password': password,
        'preferred_language': preferredLanguage.trim(),
      },
    );
    final session = AuthSession.fromJson(response as Map<String, dynamic>);
    await saveSession(session);
    return session;
  }

  /// Register a new Agricultural Officer account.
  Future<AuthSession> registerOfficer({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required String preferredLanguage,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.registerOfficer,
      body: {
        'full_name': fullName.trim(),
        'email': email.trim().toLowerCase(),
        'phone_number': phoneNumber.trim(),
        'password': password,
        'preferred_language': preferredLanguage.trim(),
      },
    );
    final session = AuthSession.fromJson(response as Map<String, dynamic>);
    await saveSession(session);
    return session;
  }

  /// Convenience register method routing to the role-specific endpoint.
  Future<AuthSession> register({
    required UserRole role,
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required String preferredLanguage,
  }) {
    if (role == UserRole.farmer) {
      return registerFarmer(
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        password: password,
        preferredLanguage: preferredLanguage,
      );
    } else {
      return registerOfficer(
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        password: password,
        preferredLanguage: preferredLanguage,
      );
    }
  }

  /// Validate JWT token against the backend and fetch latest user profile.
  Future<AuthUser> getMe(String token) async {
    final response = await _apiClient.get(ApiEndpoints.me, token: token);
    return AuthUser.fromJson(response as Map<String, dynamic>);
  }

  /// Persist session tokens and user data in local storage.
  Future<void> saveSession(AuthSession session) async {
    final prefs = await _getPrefs();
    await prefs.setString(_keyToken, session.accessToken);
    await prefs.setString(_keyTokenType, session.tokenType);
    await prefs.setInt(_keyExpiresIn, session.expiresIn);
    await prefs.setString(_keyUser, jsonEncode(session.user.toJson()));
  }

  /// Load existing session if saved locally.
  Future<AuthSession?> loadSession() async {
    final prefs = await _getPrefs();
    final token = prefs.getString(_keyToken);
    final userRaw = prefs.getString(_keyUser);
    if (token == null || userRaw == null) {
      return null;
    }
    try {
      final userJson = jsonDecode(userRaw) as Map<String, dynamic>;
      final user = AuthUser.fromJson(userJson);
      final tokenType = prefs.getString(_keyTokenType) ?? 'bearer';
      final expiresIn = prefs.getInt(_keyExpiresIn) ?? 86400;
      return AuthSession(
        accessToken: token,
        tokenType: tokenType,
        expiresIn: expiresIn,
        user: user,
      );
    } catch (_) {
      await clearSession();
      return null;
    }
  }

  /// Clear session credentials upon user logout.
  Future<void> clearSession() async {
    final prefs = await _getPrefs();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyTokenType);
    await prefs.remove(_keyExpiresIn);
    await prefs.remove(_keyUser);
  }
}
