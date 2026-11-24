import 'package:flutter/material.dart';

import 'package:agrochat_app/core/theme/app_colors.dart';
import 'package:agrochat_app/features/auth/models/auth_user.dart';
import 'package:agrochat_app/features/officer/models/assistance_request_model.dart';
import 'package:agrochat_app/features/officer/models/officer_profile_model.dart';
import 'package:agrochat_app/features/officer/presentation/screens/request_detail_screen.dart';
import 'package:agrochat_app/features/officer/repositories/officer_repository.dart';
import 'package:agrochat_app/shared/widgets/responsive_container.dart';
import 'package:agrochat_app/shared/widgets/status_feedback.dart';

/// The Home Dashboard view for authenticated Agricultural Officers.
/// Displays jurisdictional greetings, request metrics, quick action buttons, and recent farmer requests.
class OfficerDashboardView extends StatefulWidget {
  const OfficerDashboardView({
    super.key,
    required this.session,
    required this.repository,
    required this.onNavigateToTab,
  });

  final AuthSession session;
  final OfficerRepository repository;
  final void Function(int tabIndex) onNavigateToTab;

  @override
  State<OfficerDashboardView> createState() => _OfficerDashboardViewState();
}

class _OfficerDashboardViewState extends State<OfficerDashboardView> {
  bool _isLoading = true;
  String? _errorMessage;
  OfficerProfileModel? _profile;
  List<AssistanceRequestModel> _recentRequests = [];
  OfficerRequestStats _stats = const OfficerRequestStats(
    total: 0,
    pending: 0,
    accepted: 0,
    inProgress: 0,
    resolved: 0,
    rejected: 0,
  );
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
      final profileFuture = widget.repository
          .getProfile()
          .then<OfficerProfileModel?>((p) => p)
          .catchError((_) => null);
      final requestsFuture = widget.repository.listRequests(scope: 'all');
      final notificationsFuture = widget.repository.listNotifications();

      final results = await Future.wait([
        profileFuture,
        requestsFuture,
        notificationsFuture,
      ]);

      if (mounted) {
        final profile = results[0] as OfficerProfileModel?;
        final requests = results[1] as List<AssistanceRequestModel>;
        final notifs = results[2] as dynamic;

        setState(() {
          _profile = profile;
          _recentRequests = requests;
          _stats = OfficerRequestStats.fromRequests(requests);
          _unreadNotifications = notifs.unreadCount as int? ?? 0;
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

  Future<void> _toggleAvailability(bool newValue) async {
    try {
      final updated = await widget.repository.updateAvailability(newValue);
      if (mounted) {
        setState(() => _profile = updated);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Status updated: ${newValue ? "Available for Consultations" : "Currently Offline / Busy"}',
            ),
            backgroundColor: AppColors.primaryGreenDark,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update availability: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AgroLoadingView(message: 'Loading officer dashboard...');
    }

    if (_errorMessage != null && _recentRequests.isEmpty) {
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
              _buildOfficerBanner(user),
              const SizedBox(height: 16),
              _buildStatsGrid(),
              const SizedBox(height: 20),
              _buildQuickActions(),
              const SizedBox(height: 24),
              _buildRecentRequestsHeader(),
              const SizedBox(height: 8),
              if (_recentRequests.isEmpty)
                _buildEmptyRequestsCard()
              else
                ..._recentRequests.take(4).map(_buildRequestCard),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOfficerBanner(AuthUser user) {
    final designation = _profile?.designation ?? 'Agricultural Officer';
    final district = _profile?.district ?? '';
    final state = _profile?.state ?? '';
    final isAvailable = _profile?.isAvailable ?? true;

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
                  Icons.support_agent_rounded,
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
                      'Welcome, Officer ${user.fullName}!',
                      style: const TextStyle(
                        color: AppColors.surfaceWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$designation ${district.isNotEmpty ? '• $district, $state' : ''}',
                      style: const TextStyle(
                        color: AppColors.softMint,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Color(0x33FFFFFF), height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isAvailable
                        ? Icons.check_circle_rounded
                        : Icons.do_not_disturb_on_rounded,
                    color: isAvailable
                        ? AppColors.accentLeaf
                        : const Color(0xFFFFB74D),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isAvailable
                        ? 'Available for Consultations'
                        : 'Currently Offline',
                    style: const TextStyle(
                      color: AppColors.surfaceWhite,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Switch(
                value: isAvailable,
                activeThumbColor: AppColors.primaryGreenDark,
                activeTrackColor: AppColors.accentLeaf,
                onChanged: _toggleAvailability,
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
                title: 'Pending Review',
                value: '${_stats.pending}',
                subtitle: 'Awaiting officer action',
                icon: Icons.pending_actions_rounded,
                iconColor: AppColors.warning,
                backgroundColor: const Color(0xFFFFF8E1),
                onTap: () => widget.onNavigateToTab(1),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildStatTile(
                title: 'Active / Progress',
                value: '${_stats.accepted + _stats.inProgress}',
                subtitle: 'Active advisories',
                icon: Icons.chat_rounded,
                iconColor: AppColors.primaryGreen,
                backgroundColor: AppColors.softMint,
                onTap: () => widget.onNavigateToTab(1),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildStatTile(
                title: 'Resolved',
                value: '${_stats.resolved}',
                subtitle: 'Completed consultations',
                icon: Icons.task_alt_rounded,
                iconColor: const Color(0xFF2E7D32),
                backgroundColor: const Color(0xFFE8F5E9),
                onTap: () => widget.onNavigateToTab(1),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildStatTile(
                title: 'Total Handled',
                value: '${_stats.total}',
                subtitle: 'Jurisdictional requests',
                icon: Icons.assessment_rounded,
                iconColor: AppColors.info,
                backgroundColor: const Color(0xFFE3F2FD),
                onTap: () => widget.onNavigateToTab(1),
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
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
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
          'Officer Management Shortcuts',
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
                onPressed: () => widget.onNavigateToTab(1),
                icon: const Icon(Icons.assignment_outlined, size: 18),
                label: const Text('All Requests'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
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
                icon: const Icon(Icons.notifications_none_rounded, size: 18),
                label: Text(
                  _unreadNotifications > 0
                      ? 'Notifs ($_unreadNotifications)'
                      : 'Notifications',
                ),
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
      ],
    );
  }

  Widget _buildRecentRequestsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Recent Farmer Requests',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        if (_recentRequests.isNotEmpty)
          TextButton(
            onPressed: () => widget.onNavigateToTab(1),
            child: const Text('View All'),
          ),
      ],
    );
  }

  Widget _buildEmptyRequestsCard() {
    return Card(
      elevation: 0,
      color: AppColors.surfaceWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.inbox_rounded,
              size: 50,
              color: AppColors.primaryGreenLight,
            ),
            SizedBox(height: 12),
            Text(
              'No Requests In Your Queue',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 6),
            Text(
              'When farmers in your jurisdiction submit pest, disease, or advisory questions, they will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(AssistanceRequestModel req) {
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
            color: req.isPending ? const Color(0xFFFFF3E0) : AppColors.softMint,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            req.isPending ? Icons.pending_actions_rounded : Icons.chat_rounded,
            color: req.isPending ? AppColors.warning : AppColors.primaryGreen,
          ),
        ),
        title: Text(
          req.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Farmer: ${req.farmerName ?? "#${req.farmerId}"} • ${req.category}',
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
                  req.status.toUpperCase(),
                  req.isPending
                      ? AppColors.warning
                      : AppColors.primaryGreenDark,
                ),
                _badge(
                  'Priority: ${req.priority}',
                  req.priority == 'urgent'
                      ? AppColors.error
                      : AppColors.textSecondary,
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RequestDetailScreen(
                requestId: req.id,
                repository: widget.repository,
              ),
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
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
