import 'package:flutter/material.dart';

import 'package:agrochat_app/core/config/app_config.dart';
import 'package:agrochat_app/core/theme/app_theme.dart';
import 'package:agrochat_app/features/splash/presentation/splash_screen.dart';

/// Root MaterialApp widget configuring the AgroChat theme and initial screen.
class AgroChatApp extends StatelessWidget {
  const AgroChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
