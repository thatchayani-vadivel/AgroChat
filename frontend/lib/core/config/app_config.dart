import 'package:flutter/foundation.dart';

/// Application-wide configuration for AgroChat.
class AppConfig {
  AppConfig._();

  static const String appName = 'AgroChat';
  static const String appTagline =
      'Digital Agriculture Advisory & Farmer–Officer Communication';

  /// Override at build/run time using:
  /// flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Runtime override for physical Android device testing on local Wi-Fi.
  static String? customBaseUrl;

  static const Duration requestTimeout = Duration(seconds: 12);

  /// Returns the FastAPI backend base URL appropriate for the active platform.
  /// - If [customBaseUrl] is set at runtime, it takes highest precedence.
  /// - If [API_BASE_URL] environment variable is provided, it is used.
  /// - Android Emulator defaults to 10.0.2.2:8000 (maps to host machine).
  /// - Desktop, Web, and Test default to 127.0.0.1:8000.
  static String get baseUrl {
    if (customBaseUrl != null && customBaseUrl!.trim().isNotEmpty) {
      return customBaseUrl!.trim();
    }
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl;
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }
}
