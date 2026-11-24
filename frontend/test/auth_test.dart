import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agrochat_app/core/constants/user_role.dart';
import 'package:agrochat_app/core/network/api_client.dart';
import 'package:agrochat_app/core/theme/app_theme.dart';
import 'package:agrochat_app/features/auth/models/auth_user.dart';
import 'package:agrochat_app/features/auth/presentation/login_screen.dart';
import 'package:agrochat_app/features/auth/presentation/register_screen.dart';
import 'package:agrochat_app/features/auth/repositories/auth_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthUser & AuthSession serialization', () {
    test('parses farmer user and serializes accurately', () {
      final json = {
        'id': 10,
        'full_name': 'Ramesh Kumar',
        'email': 'ramesh@example.com',
        'phone_number': '+91 9876543210',
        'role': 'farmer',
        'preferred_language': 'Hindi',
        'is_active': true,
        'created_at': '2026-11-13T10:00:00Z',
      };

      final user = AuthUser.fromJson(json);
      expect(user.id, 10);
      expect(user.fullName, 'Ramesh Kumar');
      expect(user.role, UserRole.farmer);
      expect(user.preferredLanguage, 'Hindi');

      final serialized = user.toJson();
      expect(serialized['role'], 'farmer');
      expect(serialized['email'], 'ramesh@example.com');
    });

    test('parses agricultural officer session correctly', () {
      final json = {
        'access_token': 'jwt.token.mock',
        'token_type': 'bearer',
        'expires_in': 86400,
        'user': {
          'id': 20,
          'full_name': 'Dr. Sharma',
          'email': 'sharma@example.com',
          'phone_number': '+91 9123456789',
          'role': 'agricultural_officer',
          'preferred_language': 'English',
          'is_active': true,
          'created_at': '2026-11-13T10:00:00Z',
        },
      };

      final session = AuthSession.fromJson(json);
      expect(session.accessToken, 'jwt.token.mock');
      expect(session.user.role, UserRole.agriculturalOfficer);
      expect(session.user.fullName, 'Dr. Sharma');
    });
  });

  group('AuthRepository integration with MockClient & SharedPreferences', () {
    late AuthRepository repo;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();

      final mockHttp = MockClient((request) async {
        final path = request.url.path;

        if (path == '/api/auth/login/farmer' ||
            path == '/api/auth/register/farmer') {
          return http.Response(
            jsonEncode({
              'access_token': 'farmer_jwt_123',
              'token_type': 'bearer',
              'expires_in': 86400,
              'user': {
                'id': 1,
                'full_name': 'Ramesh Farmer',
                'email': 'farmer@example.com',
                'phone_number': '+91 9876543210',
                'role': 'farmer',
                'preferred_language': 'Marathi',
                'is_active': true,
                'created_at': '2026-11-13T10:00:00Z',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (path == '/api/auth/login/officer' ||
            path == '/api/auth/register/officer') {
          return http.Response(
            jsonEncode({
              'access_token': 'officer_jwt_456',
              'token_type': 'bearer',
              'expires_in': 86400,
              'user': {
                'id': 2,
                'full_name': 'Officer Anita',
                'email': 'officer@example.com',
                'phone_number': '+91 9123456780',
                'role': 'agricultural_officer',
                'preferred_language': 'English',
                'is_active': true,
                'created_at': '2026-11-13T10:00:00Z',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (path == '/api/auth/me') {
          return http.Response(
            jsonEncode({
              'id': 1,
              'full_name': 'Ramesh Farmer',
              'email': 'farmer@example.com',
              'phone_number': '+91 9876543210',
              'role': 'farmer',
              'preferred_language': 'Marathi',
              'is_active': true,
              'created_at': '2026-11-13T10:00:00Z',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        return http.Response(
          jsonEncode({'error': 'Not Found', 'detail': 'Route not found'}),
          404,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        baseUrl: 'http://127.0.0.1:8000',
        httpClient: mockHttp,
      );
      repo = AuthRepository(apiClient: apiClient, preferences: prefs);
    });

    test('loginFarmer authenticates and persists session', () async {
      final session = await repo.loginFarmer(
        email: 'farmer@example.com',
        password: 'Password123!',
      );

      expect(session.accessToken, 'farmer_jwt_123');
      expect(session.user.role, UserRole.farmer);

      final loaded = await repo.loadSession();
      expect(loaded, isNotNull);
      expect(loaded!.accessToken, 'farmer_jwt_123');
      expect(loaded.user.email, 'farmer@example.com');

      await repo.clearSession();
      expect(await repo.loadSession(), isNull);
    });

    test('loginOfficer authenticates and persists session', () async {
      final session = await repo.loginOfficer(
        email: 'officer@example.com',
        password: 'Password123!',
      );

      expect(session.accessToken, 'officer_jwt_456');
      expect(session.user.role, UserRole.agriculturalOfficer);
    });

    test('getMe retrieves profile with Bearer token', () async {
      final me = await repo.getMe('farmer_jwt_123');
      expect(me.id, 1);
      expect(me.fullName, 'Ramesh Farmer');
      expect(me.role, UserRole.farmer);
    });
  });

  group('LoginScreen widget testing', () {
    testWidgets('renders role selector and validates input fields', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.lightTheme, home: const LoginScreen()),
      );

      expect(find.text('AgroChat'), findsOneWidget);
      expect(find.text('Farmer'), findsOneWidget);
      expect(find.text('Agricultural Officer'), findsOneWidget);

      // Attempt submit without filling inputs
      await tester.ensureVisible(find.text('Sign In as Farmer'));
      await tester.tap(find.text('Sign In as Farmer'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email.'), findsOneWidget);
      expect(find.text('Please enter your password.'), findsOneWidget);

      // Switch to Agricultural Officer
      await tester.ensureVisible(find.text('Agricultural Officer'));
      await tester.tap(find.text('Agricultural Officer'));
      await tester.pumpAndSettle();

      expect(find.text('Sign In as Agricultural Officer'), findsOneWidget);
    });
  });

  group('RegisterScreen widget testing', () {
    testWidgets('renders all registration fields and language selector', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.lightTheme, home: const RegisterScreen()),
      );

      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Preferred Language'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);

      // Form validation check
      await tester.ensureVisible(find.text('Register as Farmer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Register as Farmer'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter at least 2 characters.'), findsOneWidget);
      expect(find.text('Please enter your email.'), findsOneWidget);
      expect(find.text('Please enter your phone number.'), findsOneWidget);
      expect(
        find.text('Password must be at least 8 characters.'),
        findsOneWidget,
      );
    });
  });
}
