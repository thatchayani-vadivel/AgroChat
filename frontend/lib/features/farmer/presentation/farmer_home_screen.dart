import 'package:flutter/material.dart';

import 'package:agrochat_app/core/theme/app_colors.dart';
import 'package:agrochat_app/features/auth/models/auth_user.dart';
import 'package:agrochat_app/features/auth/presentation/login_screen.dart';
import 'package:agrochat_app/features/auth/repositories/auth_repository.dart';
import 'package:agrochat_app/features/farmer/presentation/views/crop_management_view.dart';
import 'package:agrochat_app/features/farmer/presentation/views/farm_management_view.dart';
import 'package:agrochat_app/features/farmer/presentation/views/farmer_dashboard_view.dart';
import 'package:agrochat_app/features/farmer/presentation/views/farmer_profile_view.dart';
import 'package:agrochat_app/features/farmer/repositories/farmer_repository.dart';

/// Primary Home Screen for authenticated Farmers with multi-tab navigation:
/// 1. Home Dashboard (stats, quick actions, greetings, recent farms)
/// 2. Farm Management (list, add, edit, delete farms)
/// 3. Crop Management (crops across farms, stage tracking, season filters)
/// 4. Profile & Language Preferences (personal details, 11 Indic languages, logout)
class FarmerHomeScreen extends StatefulWidget {
  const FarmerHomeScreen({
    super.key,
    required this.session,
    this.authRepository,
    this.farmerRepository,
  });

  final AuthSession session;
  final AuthRepository? authRepository;
  final FarmerRepository? farmerRepository;

  @override
  State<FarmerHomeScreen> createState() => _FarmerHomeScreenState();
}

class _FarmerHomeScreenState extends State<FarmerHomeScreen> {
  int _currentIndex = 0;
  late AuthSession _session;
  late FarmerRepository _farmerRepository;

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _farmerRepository =
        widget.farmerRepository ??
        FarmerRepository(token: _session.accessToken);
  }

  void _onSessionUpdated(AuthSession updatedSession) {
    setState(() {
      _session = updatedSession;
      _farmerRepository =
          widget.farmerRepository ??
          FarmerRepository(token: _session.accessToken);
    });
  }

  void _navigateToTab(int index) {
    if (index >= 0 && index <= 3) {
      setState(() => _currentIndex = index);
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out of AgroChat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final repo = widget.authRepository ?? AuthRepository();
    await repo.clearSession();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  String get _appBarTitle {
    switch (_currentIndex) {
      case 0:
        return 'Farmer Dashboard';
      case 1:
        return 'My Farms';
      case 2:
        return 'Crop Management';
      case 3:
        return 'Farmer Profile';
      default:
        return 'AgroChat';
    }
  }

  @override
  Widget build(BuildContext context) {
    final views = [
      FarmerDashboardView(
        session: _session,
        repository: _farmerRepository,
        onNavigateToTab: _navigateToTab,
      ),
      FarmManagementView(repository: _farmerRepository),
      CropManagementView(
        repository: _farmerRepository,
        onNavigateToFarms: () => _navigateToTab(1),
      ),
      FarmerProfileView(
        session: _session,
        repository: _farmerRepository,
        authRepository: widget.authRepository,
        onSessionUpdated: _onSessionUpdated,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitle),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.softMint,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryGreen.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.language_rounded,
                  size: 14,
                  color: AppColors.primaryGreenDark,
                ),
                const SizedBox(width: 4),
                Text(
                  _session.user.preferredLanguage,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreenDark,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout_rounded),
            onPressed: _confirmLogout,
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: views),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        indicatorColor: AppColors.softMint,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(
              Icons.dashboard_rounded,
              color: AppColors.primaryGreenDark,
            ),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.landscape_outlined),
            selectedIcon: Icon(
              Icons.landscape_rounded,
              color: AppColors.primaryGreenDark,
            ),
            label: 'Farms',
          ),
          NavigationDestination(
            icon: Icon(Icons.grass_outlined),
            selectedIcon: Icon(
              Icons.grass_rounded,
              color: AppColors.primaryGreenDark,
            ),
            label: 'Crops',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(
              Icons.person_rounded,
              color: AppColors.primaryGreenDark,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
