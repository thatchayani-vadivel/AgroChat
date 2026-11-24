import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:agrochat_app/app.dart';
import 'package:agrochat_app/core/network/api_client.dart';
import 'package:agrochat_app/core/theme/app_theme.dart';
import 'package:agrochat_app/features/splash/presentation/splash_screen.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('AgroChat app renders branding and strictly two roles', (
    tester,
  ) async {
    await tester.pumpWidget(const AgroChatApp());

    expect(find.text('AgroChat'), findsOneWidget);
    expect(find.text('Farmer'), findsOneWidget);
    expect(find.text('Agricultural Officer'), findsOneWidget);
    expect(find.textContaining('Admin'), findsNothing);
  });

  testWidgets('SplashScreen displays connected state when backend responds', (
    tester,
  ) async {
    final mockHttp = MockClient((request) async {
      if (request.url.path == '/') {
        return http.Response(jsonEncode({'app': 'AgroChat API'}), 200);
      }
      if (request.url.path == '/health') {
        return http.Response(
          jsonEncode({'status': 'healthy', 'database': 'connected'}),
          200,
        );
      }
      return http.Response('Not found', 404);
    });

    final client = ApiClient(
      baseUrl: 'http://127.0.0.1:8000',
      httpClient: mockHttp,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: SplashScreen(apiClient: client, autoNavigate: false),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('AgroChat API Connected'), findsOneWidget);
    expect(find.text('connected'), findsOneWidget);
  });
}
