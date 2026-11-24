import 'package:flutter/material.dart';

import 'package:agrochat_app/core/theme/app_colors.dart';
import 'package:agrochat_app/features/auth/models/auth_user.dart';
import 'package:agrochat_app/features/auth/presentation/login_screen.dart';
import 'package:agrochat_app/features/auth/repositories/auth_repository.dart';
import 'package:agrochat_app/features/officer/presentation/views/officer_dashboard_view.dart';
import 'package:agrochat_app/features/officer/presentation/views/officer_notifications_view.dart';
import 'package:agrochat_app/features/officer/presentation/views/officer_profile_view.dart';
import 'package:agrochat_app/features/officer/presentation/views/officer_requests_view.dart';
import 'package:agrochat_app/features/officer/repositories/officer_repository.dart';

/// Primary Home Screen for authenticated Agricultural Officers with multi-tab navigation:
/// 1. Officer Dashboard (welcome, request metrics, quick action shortcuts, recent requests)
/// 2. Requests Management (browse, filter by open/assigned/status, view details, accept/reject)
/// 3. In-App Notifications (real-time request updates, chat message alerts, mark-as-read)
/// 4. Officer Profile (credentials, specialization, availability hours toggle, logout)
class OfficerHomeScreen extends StatefulWidget {
  const OfficerHomeScreen({
    super.key,
    required this.session,
    this.authRepository,
    this.officerRepository,
  });

  final AuthSession session;
  final AuthRepository? authRepository;
  final OfficerRepository? officerRepository;

  @override
  State<OfficerHomeScreen> createState() => _OfficerHomeScreenState();
}

class _OfficerHomeScreenState extends State<OfficerHomeScreen> {
  int _currentIndex = 0;
  late AuthSession _session;
  late OfficerRepository _officerRepository;

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _officerRepository =
        widget.officerRepository ??
        OfficerRepository(token: _session.accessToken);
  }

  void _onSessionUpdated(AuthSession updatedSession) {
    setState(() {
      _session = updatedSession;
      _officerRepository =
          widget.officerRepository ??
          OfficerRepository(token: _session.accessToken);
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
        content: const Text(
          'Are you sure you want to log out of the Officer Portal?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Log Out', style: TextStyle(color: Colors.white)),
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
        return 'Officer Dashboard';
      case 1:
        return 'Farmer Requests';
      case 2:
        return 'Notifications';
      case 3:
        return 'Officer Profile';
      default:
        return 'Agricultural Officer Portal';
    }
  }

  @override
  Widget build(BuildContext context) {
    final views = [
      OfficerDashboardView(
        session: _session,
        repository: _officerRepository,
        onNavigateToTab: _navigateToTab,
      ),
      OfficerRequestsView(repository: _officerRepository),
      OfficerNotificationsView(repository: _officerRepository),
      OfficerProfileView(
        session: _session,
        repository: _officerRepository,
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
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_user_rounded,
                  size: 14,
                  color: AppColors.primaryGreenDark,
                ),
                SizedBox(width: 4),
                Text(
                  'Officer Portal',
                  style: TextStyle(
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
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(
              Icons.assignment_rounded,
              color: AppColors.primaryGreenDark,
            ),
            label: 'Requests',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none_rounded),
            selectedIcon: Icon(
              Icons.notifications_rounded,
              color: AppColors.primaryGreenDark,
            ),
            label: 'Notifications',
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
