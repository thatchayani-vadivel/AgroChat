import 'package:flutter/material.dart';

import 'package:agrochat_app/core/theme/app_colors.dart';
import 'package:agrochat_app/features/advisory/presentation/farmer_advisory_screen.dart';
import 'package:agrochat_app/features/advisory/repositories/advisory_repository.dart';
import 'package:agrochat_app/features/auth/models/auth_user.dart';
import 'package:agrochat_app/features/farmer/models/farm_model.dart';
import 'package:agrochat_app/features/farmer/models/farmer_profile_model.dart';
import 'package:agrochat_app/features/farmer/presentation/screens/farm_detail_screen.dart';
import 'package:agrochat_app/features/farmer/presentation/screens/farmer_notifications_screen.dart';
import 'package:agrochat_app/features/farmer/presentation/screens/farmer_requests_screen.dart';
import 'package:agrochat_app/features/farmer/presentation/widgets/add_edit_farm_dialog.dart';
import 'package:agrochat_app/features/farmer/repositories/farmer_repository.dart';
import 'package:agrochat_app/features/marketplace/presentation/farmer_marketplace_screen.dart';
import 'package:agrochat_app/features/marketplace/repositories/marketplace_repository.dart';
import 'package:agrochat_app/shared/widgets/responsive_container.dart';
import 'package:agrochat_app/shared/widgets/status_feedback.dart';

/// The Home Dashboard view for authenticated Farmers.
/// Displays greetings, quick agricultural statistics, shortcut actions, and recent farms.
class FarmerDashboardView extends StatefulWidget {
  const FarmerDashboardView({
    super.key,
    required this.session,
    required this.repository,
    required this.onNavigateToTab,
  });

  final AuthSession session;
  final FarmerRepository repository;
  final void Function(int tabIndex) onNavigateToTab;

  @override
  State<FarmerDashboardView> createState() => _FarmerDashboardViewState();
}

class _FarmerDashboardViewState extends State<FarmerDashboardView> {
  bool _isLoading = true;
  String? _errorMessage;
  List<FarmModel> _farms = [];
  FarmerProfileModel? _profile;
  int _activeRequestsCount = 0;
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final farmsFuture = widget.repository.listFarms();
      final profileFuture = widget.repository
          .getFarmerProfile()
          .then<FarmerProfileModel?>((p) => p)
          .catchError((_) => null);
      final requestsFuture = widget.repository.getActiveRequestsCount();
      final notificationsFuture = widget.repository
          .getUnreadNotificationsCount();

      final results = await Future.wait([
        farmsFuture,
        profileFuture,
        requestsFuture,
        notificationsFuture,
      ]);

      if (mounted) {
        setState(() {
          _farms = results[0] as List<FarmModel>;
          _profile = results[1] as FarmerProfileModel?;
          _activeRequestsCount = results[2] as int;
          _unreadNotifications = results[3] as int;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addNewFarm() async {
    final result = await showDialog<FarmModel>(
      context: context,
      builder: (_) => const AddEditFarmDialog(),
    );
    if (result == null || !mounted) return;

    try {
      await widget.repository.createFarm(result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Farm "${result.farmName}" added successfully!'),
          backgroundColor: AppColors.primaryGreenDark,
        ),
      );
      await _loadDashboardData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add farm: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  double get _totalAreaAcres {
    return _farms.fold<double>(0.0, (sum, farm) => sum + farm.totalAreaAcres);
  }

  int get _totalCropsCount {
    return _farms.fold<int>(0, (sum, farm) => sum + farm.crops.length);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AgroLoadingView(
        message: 'Loading your agricultural dashboard...',
      );
    }

    if (_errorMessage != null && _farms.isEmpty) {
      return AgroEmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Unable to Load Dashboard',
        description: _errorMessage!,
        actionLabel: 'Retry',
        onAction: _loadDashboardData,
      );
    }

    final user = widget.session.user;

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: ResponsiveContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildWelcomeBanner(user),
              const SizedBox(height: 16),
              _buildStatsGrid(),
              const SizedBox(height: 20),
              _buildQuickActions(),
              const SizedBox(height: 24),
              _buildRecentFarmsHeader(),
              const SizedBox(height: 8),
              if (_farms.isEmpty)
                _buildEmptyFarmsCard()
              else
                ..._farms.take(3).map(_buildRecentFarmCard),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner(AuthUser user) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryGreenDark, AppColors.primaryGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x221B4332),
            offset: Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.surfaceWhite,
                child: Icon(
                  Icons.person_rounded,
                  size: 32,
                  color: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Namaste, ${user.fullName}!',
                      style: const TextStyle(
                        color: AppColors.surfaceWhite,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _profile?.district != null &&
                              _profile!.district!.isNotEmpty
                          ? '${_profile!.district}, ${_profile!.state ?? 'India'}'
                          : 'Farmer Advisory Portal',
                      style: const TextStyle(
                        color: AppColors.softMint,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  user.preferredLanguage,
                  style: const TextStyle(
                    color: AppColors.surfaceWhite,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Color(0x33FFFFFF), height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.shield_outlined,
                color: AppColors.softMint,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Direct Farmer–Agricultural Officer Communication',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (_unreadNotifications > 0)
                InkWell(
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => FarmerNotificationsScreen(
                          token: widget.session.accessToken,
                          farmerRepository: widget.repository,
                        ),
                      ),
                    );
                    _loadDashboardData();
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$_unreadNotifications new',
                      style: const TextStyle(
                        color: AppColors.surfaceWhite,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: cardWidth,
              child: _buildStatTile(
                title: 'My Farms',
                value: '${_farms.length}',
                subtitle: 'Registered plots',
                icon: Icons.landscape_rounded,
                iconColor: AppColors.primaryGreen,
                backgroundColor: AppColors.softMint,
                onTap: () => widget.onNavigateToTab(1),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildStatTile(
                title: 'Total Land',
                value: '${_totalAreaAcres.toStringAsFixed(1)} Ac',
                subtitle: 'Combined land area',
                icon: Icons.terrain_rounded,
                iconColor: AppColors.warning,
                backgroundColor: const Color(0xFFFBF4ED),
                onTap: () => widget.onNavigateToTab(1),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildStatTile(
                title: 'Crops',
                value: '$_totalCropsCount',
                subtitle: 'Active cultivations',
                icon: Icons.grass_rounded,
                iconColor: const Color(0xFF2E7D32),
                backgroundColor: const Color(0xFFE8F5E9),
                onTap: () => widget.onNavigateToTab(2),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildStatTile(
                title: 'Requests',
                value: '$_activeRequestsCount',
                subtitle: 'Officer advisories',
                icon: Icons.support_agent_rounded,
                iconColor: AppColors.info,
                backgroundColor: const Color(0xFFE3F2FD),
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          FarmerRequestsScreen(repository: widget.repository),
                    ),
                  );
                  _loadDashboardData();
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: iconColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Icon(icon, color: iconColor, size: 22),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Agricultural Actions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _addNewFarm,
                icon: const Icon(Icons.add_location_alt_rounded, size: 18),
                label: const Text('Add Farm'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: AppColors.surfaceWhite,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => widget.onNavigateToTab(2),
                icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                label: const Text('Add Crop'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: AppColors.primaryGreen),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          FarmerRequestsScreen(repository: widget.repository),
                    ),
                  );
                  _loadDashboardData();
                },
                icon: const Icon(Icons.support_agent_rounded, size: 18),
                label: const Text('Ask Officer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreenDark,
                  foregroundColor: AppColors.surfaceWhite,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FarmerAdvisoryScreen(
                        repository: AdvisoryRepository(
                          token: widget.session.accessToken,
                        ),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.policy_rounded, size: 18),
                label: const Text('Govt Schemes'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryGreenDark,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: AppColors.primaryGreenDark),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FarmerMarketplaceScreen(
                        repository: MarketplaceRepository(
                          token: widget.session.accessToken,
                        ),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.storefront_rounded, size: 18),
                label: const Text('Shop & Machinery'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: AppColors.surfaceWhite,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FarmerNotificationsScreen(
                        token: widget.session.accessToken,
                        farmerRepository: widget.repository,
                      ),
                    ),
                  );
                  _loadDashboardData();
                },
                icon: const Icon(Icons.notifications_active_rounded, size: 18),
                label: Text(
                  _unreadNotifications > 0
                      ? 'Alerts ($_unreadNotifications)'
                      : 'Alerts',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.warning,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: AppColors.warning),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentFarmsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'My Registered Farms',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        if (_farms.isNotEmpty)
          TextButton(
            onPressed: () => widget.onNavigateToTab(1),
            child: const Text('View All'),
          ),
      ],
    );
  }

  Widget _buildEmptyFarmsCard() {
    return Card(
      elevation: 0,
      color: AppColors.surfaceWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.agriculture_rounded,
              size: 54,
              color: AppColors.primaryGreenLight,
            ),
            const SizedBox(height: 12),
            const Text(
              'No Farms Registered Yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Add your agricultural plots to track crops, manage soil & irrigation, and request expert guidance from local agricultural officers.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _addNewFarm,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Register First Farm'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentFarmCard(FarmModel farm) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.softMint,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.landscape_rounded,
            color: AppColors.primaryGreen,
          ),
        ),
        title: Text(
          farm.farmName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${farm.location.isNotEmpty ? '${farm.location}, ' : ''}${farm.district}, ${farm.state}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              children: [
                _badge(
                  '${farm.totalAreaAcres} Acres',
                  AppColors.primaryGreenDark,
                ),
                _badge(farm.soilType, AppColors.warning),
                _badge('${farm.crops.length} Crops', const Color(0xFF2E7D32)),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  FarmDetailScreen(farm: farm, repository: widget.repository),
            ),
          );
          _loadDashboardData();
        },
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
