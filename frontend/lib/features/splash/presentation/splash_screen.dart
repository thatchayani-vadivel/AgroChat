import 'dart:async';

import 'package:flutter/material.dart';

import 'package:agrochat_app/core/config/app_config.dart';
import 'package:agrochat_app/core/constants/api_endpoints.dart';
import 'package:agrochat_app/core/constants/user_role.dart';
import 'package:agrochat_app/core/network/api_client.dart';
import 'package:agrochat_app/core/network/api_exception.dart';
import 'package:agrochat_app/core/theme/app_colors.dart';
import 'package:agrochat_app/features/auth/models/auth_user.dart';
import 'package:agrochat_app/features/auth/presentation/login_screen.dart';
import 'package:agrochat_app/features/auth/presentation/register_screen.dart';
import 'package:agrochat_app/features/auth/repositories/auth_repository.dart';
import 'package:agrochat_app/features/advisory/presentation/farmer_advisory_screen.dart';
import 'package:agrochat_app/features/advisory/repositories/advisory_repository.dart';
import 'package:agrochat_app/features/farmer/presentation/farmer_home_screen.dart';
import 'package:agrochat_app/features/officer/presentation/officer_home_screen.dart';
import 'package:agrochat_app/shared/widgets/agro_logo.dart';
import 'package:agrochat_app/shared/widgets/responsive_container.dart';

/// Initial screen verifying server health, restoring authenticated JWT sessions, or navigating to Login.
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.apiClient,
    this.authRepository,
    this.autoNavigate = true,
  });

  final ApiClient? apiClient;
  final AuthRepository? authRepository;
  final bool autoNavigate;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final ApiClient _apiClient;
  late final AuthRepository _authRepo;
  late final bool _ownsClient;

  bool _isLoading = true;
  bool _isHealthy = false;
  String _statusTitle = 'Checking AgroChat Backend...';
  String _statusDetail = 'Connecting to FastAPI & MySQL';
  String _databaseState = 'unknown';
  Timer? _navigateTimer;

  @override
  void initState() {
    super.initState();
    _ownsClient = widget.apiClient == null;
    _apiClient = widget.apiClient ?? ApiClient();
    _authRepo = widget.authRepository ?? AuthRepository(apiClient: _apiClient);
    _checkBackendHealthAndSession();
  }

  @override
  void dispose() {
    _navigateTimer?.cancel();
    if (_ownsClient) {
      _apiClient.dispose();
    }
    super.dispose();
  }

  Future<void> _checkBackendHealthAndSession() async {
    _navigateTimer?.cancel();
    setState(() {
      _isLoading = true;
      _statusTitle = 'Checking AgroChat Backend...';
      _statusDetail = 'Verifying ${AppConfig.baseUrl}${ApiEndpoints.health}';
    });

    try {
      final rootData = await _apiClient.get(ApiEndpoints.root);
      final healthData = await _apiClient.get(ApiEndpoints.health);

      if (!mounted) return;
      final appTitle = rootData is Map<String, dynamic>
          ? (rootData['app'] ?? 'AgroChat API')
          : 'AgroChat API';
      final dbStatus = healthData is Map<String, dynamic>
          ? (healthData['database'] ?? 'connected')
          : 'connected';

      setState(() {
        _isLoading = false;
        _isHealthy = true;
        _databaseState = dbStatus.toString();
        _statusTitle = '$appTitle Connected';
        _statusDetail = 'API & MySQL database are online and ready.';
      });

      // Direct page navigation shortcuts via URL query parameter: ?page=register or ?page=login
      final pageParam = Uri.base.queryParameters['page']?.toLowerCase();
      if (pageParam == 'register') {
        if (!mounted) return;
        final isOfficer = Uri.base.queryParameters['role']?.toLowerCase() == 'officer';
        _routeToDestination(
          RegisterScreen(
            initialRole: isOfficer ? UserRole.agriculturalOfficer : UserRole.farmer,
            authRepository: _authRepo,
          ),
        );
        return;
      }
      if (pageParam == 'login') {
        if (!mounted) return;
        final isOfficer = Uri.base.queryParameters['role']?.toLowerCase() == 'officer';
        _routeToDestination(
          LoginScreen(
            initialRole: isOfficer ? UserRole.agriculturalOfficer : UserRole.farmer,
            authRepository: _authRepo,
          ),
        );
        return;
      }
      if (pageParam == 'schemes' || pageParam == 'subsidies') {
        try {
          final demoSession = await _authRepo.loginFarmer(
            email: 'farmer@agrochat.com',
            password: 'Farmer@123',
          );
          if (!mounted) return;
          _routeToDestination(
            FarmerAdvisoryScreen(
              repository: AdvisoryRepository(token: demoSession.accessToken),
            ),
          );
          return;
        } catch (_) {}
      }

      // Quick demo role shortcut via URL query parameter: ?role=farmer or ?role=officer
      final roleParam = Uri.base.queryParameters['role']?.toLowerCase();
      if (roleParam == 'farmer') {
        try {
          final demoSession = await _authRepo.loginFarmer(
            email: 'farmer@agrochat.com',
            password: 'Farmer@123',
          );
          if (!mounted) return;
          _routeToDestination(
            FarmerHomeScreen(session: demoSession, authRepository: _authRepo),
          );
          return;
        } catch (_) {}
      } else if (roleParam == 'officer') {
        try {
          final demoSession = await _authRepo.loginOfficer(
            email: 'officer@agrochat.com',
            password: 'Officer@123',
          );
          if (!mounted) return;
          _routeToDestination(
            OfficerHomeScreen(session: demoSession, authRepository: _authRepo),
          );
          return;
        } catch (_) {}
      }

      // Check for an active persisted JWT session
      final session = await _authRepo.loadSession();
      if (session != null) {
        try {
          final verifiedUser = await _authRepo.getMe(session.accessToken);
          final updatedSession = AuthSession(
            accessToken: session.accessToken,
            tokenType: session.tokenType,
            expiresIn: session.expiresIn,
            user: verifiedUser,
          );
          await _authRepo.saveSession(updatedSession);
          if (!mounted) return;
          _routeToDestination(
            verifiedUser.role == UserRole.farmer
                ? FarmerHomeScreen(
                    session: updatedSession,
                    authRepository: _authRepo,
                  )
                : OfficerHomeScreen(
                    session: updatedSession,
                    authRepository: _authRepo,
                  ),
          );
          return;
        } catch (_) {
          // Token expired or invalid -> clear stale credentials
          await _authRepo.clearSession();
        }
      }

      // If auto-navigate enabled and unauthenticated, proceed to login
      if (widget.autoNavigate && mounted) {
        _navigateTimer = Timer(const Duration(milliseconds: 1400), () {
          if (mounted && _isHealthy) {
            _goToLogin();
          }
        });
      }
    } on ApiException catch (exc) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isHealthy = false;
        _databaseState = 'unreachable';
        _statusTitle = 'Backend Connection Issue';
        _statusDetail = exc.message;
      });
    }
  }

  void _goToLogin() {
    _navigateTimer?.cancel();
    _routeToDestination(LoginScreen(authRepository: _authRepo));
  }

  void _routeToDestination(Widget screen) {
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: ResponsiveContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                const AgroLogo(size: 84),
                const SizedBox(height: 8),
                Text(
                  AppConfig.appTagline,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                _buildConnectionCard(context),
                const SizedBox(height: 16),
                _buildRolesOverviewCard(context),
                const SizedBox(height: 24),
                if (_isHealthy)
                  ElevatedButton.icon(
                    onPressed: _goToLogin,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('Continue to Sign In'),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : _checkBackendHealthAndSession,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry Backend Connection'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionCard(BuildContext context) {
    final Color badgeColor = _isLoading
        ? AppColors.info
        : (_isHealthy ? AppColors.success : AppColors.warning);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: badgeColor.withValues(alpha: 0.12),
                  child: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: badgeColor,
                          ),
                        )
                      : Icon(
                          _isHealthy
                              ? Icons.cloud_done_rounded
                              : Icons.cloud_off_rounded,
                          color: badgeColor,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _statusTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _statusDetail,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24, color: AppColors.border),
            _infoRow(context, 'API Base URL', AppConfig.baseUrl),
            const SizedBox(height: 6),
            _infoRow(context, 'MySQL Status', _databaseState),
          ],
        ),
      ),
    );
  }

  Widget _buildRolesOverviewCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Supported Platform Roles',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'AgroChat connects farmers directly with agricultural officers. Exactly two roles are supported with dedicated portals.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _roleChip(
                    context,
                    icon: Icons.agriculture_rounded,
                    label: UserRole.farmer.displayName,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _roleChip(
                    context,
                    icon: Icons.support_agent_rounded,
                    label: UserRole.agriculturalOfficer.displayName,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleChip(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.softMint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primaryGreen, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Flexible(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
