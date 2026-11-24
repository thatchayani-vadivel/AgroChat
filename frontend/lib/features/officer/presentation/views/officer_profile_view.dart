import 'package:flutter/material.dart';

import 'package:agrochat_app/core/theme/app_colors.dart';
import 'package:agrochat_app/features/auth/models/auth_user.dart';
import 'package:agrochat_app/features/auth/presentation/login_screen.dart';
import 'package:agrochat_app/features/auth/repositories/auth_repository.dart';
import 'package:agrochat_app/features/officer/models/officer_profile_model.dart';
import 'package:agrochat_app/features/officer/presentation/widgets/edit_officer_profile_dialog.dart';
import 'package:agrochat_app/features/officer/repositories/officer_repository.dart';
import 'package:agrochat_app/shared/widgets/responsive_container.dart';
import 'package:agrochat_app/shared/widgets/status_feedback.dart';

/// Screen allowing the Agricultural Officer to view/edit their professional profile,
/// toggle availability hours, and log out securely.
class OfficerProfileView extends StatefulWidget {
  const OfficerProfileView({
    super.key,
    required this.session,
    required this.repository,
    this.authRepository,
    required this.onSessionUpdated,
  });

  final AuthSession session;
  final OfficerRepository repository;
  final AuthRepository? authRepository;
  final void Function(AuthSession updatedSession) onSessionUpdated;

  @override
  State<OfficerProfileView> createState() => OfficerProfileViewState();
}

class OfficerProfileViewState extends State<OfficerProfileView> {
  bool _isLoading = true;
  String? _errorMessage;
  OfficerProfileModel? _profile;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final p = await widget.repository.getProfile();
      if (mounted) {
        setState(() {
          _profile = p;
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

  Future<void> _editProfile() async {
    final current =
        _profile ??
        OfficerProfileModel(
          id: 0,
          userId: widget.session.user.id,
          designation: 'Agricultural Officer',
          specialization: 'General Agriculture',
          district: 'District',
          state: 'State',
        );

    final updated = await showDialog<OfficerProfileModel>(
      context: context,
      builder: (_) => EditOfficerProfileDialog(existingProfile: current),
    );

    if (updated == null || !mounted) return;

    try {
      final saved = await widget.repository.updateProfile(updated);
      if (mounted) {
        setState(() => _profile = saved);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Officer profile updated successfully!'),
            backgroundColor: AppColors.primaryGreenDark,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: AppColors.error,
          ),
        );
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
              'Availability status updated: ${newValue ? "Available" : "Offline"}',
            ),
            backgroundColor: AppColors.primaryGreenDark,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AgroLoadingView(message: 'Loading officer profile...');
    }

    if (_errorMessage != null && _profile == null) {
      return AgroEmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Unable to Load Profile',
        description: _errorMessage!,
        actionLabel: 'Retry',
        onAction: loadProfile,
      );
    }

    final user = widget.session.user;
    final p = _profile;

    return RefreshIndicator(
      onRefresh: loadProfile,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: ResponsiveContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildAccountCard(user),
              const SizedBox(height: 16),
              _buildProfessionalCard(p),
              const SizedBox(height: 16),
              _buildAvailabilityCard(p),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                label: const Text(
                  'Log Out',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountCard(AuthUser user) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.softMint,
                  child: Icon(
                    Icons.support_agent_rounded,
                    size: 36,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.softMint,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Role: Agricultural Officer',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGreenDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24, color: AppColors.border),
            _infoRow(Icons.email_outlined, 'Official Email', user.email),
            const SizedBox(height: 8),
            _infoRow(Icons.phone_outlined, 'Phone Number', user.phoneNumber),
            const SizedBox(height: 8),
            _infoRow(
              Icons.language_rounded,
              'System Language',
              user.preferredLanguage,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalCard(OfficerProfileModel? p) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.workspace_premium_rounded,
                        color: AppColors.primaryGreen,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Professional Credentials',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: _editProfile,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit'),
                ),
              ],
            ),
            const Divider(height: 16, color: AppColors.border),
            _infoRow(
              Icons.badge_outlined,
              'Designation',
              p?.designation ?? 'Agricultural Officer',
            ),
            const SizedBox(height: 8),
            _infoRow(
              Icons.business_outlined,
              'Department',
              p?.department ?? 'Agriculture & Farmers Welfare',
            ),
            const SizedBox(height: 8),
            _infoRow(
              Icons.psychology_outlined,
              'Specialization',
              p?.specialization ?? 'General Advisory',
            ),
            const SizedBox(height: 8),
            _infoRow(
              Icons.school_outlined,
              'Qualifications',
              p?.qualifications ?? 'Degree in Agriculture',
            ),
            const SizedBox(height: 8),
            _infoRow(
              Icons.timeline_rounded,
              'Experience',
              '${p?.experienceYears ?? 0} Years in Service',
            ),
            const SizedBox(height: 8),
            _infoRow(
              Icons.translate_rounded,
              'Languages',
              p?.languagesSpoken ?? 'English',
            ),
            const SizedBox(height: 8),
            _infoRow(
              Icons.location_on_outlined,
              'Office Address',
              p?.officeLocation ?? 'Sub-Divisional Krishi Bhavan',
            ),
            const SizedBox(height: 8),
            _infoRow(
              Icons.map_outlined,
              'Jurisdiction',
              '${p?.district ?? "District"}, ${p?.state ?? "State"}',
            ),
            if (p?.bio != null && p!.bio!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _infoRow(Icons.info_outline_rounded, 'Bio / Summary', p.bio!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilityCard(OfficerProfileModel? p) {
    final isAvailable = p?.isAvailable ?? true;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.schedule_rounded, color: AppColors.primaryGreen),
                SizedBox(width: 8),
                Text(
                  'Consultation Availability',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAvailable
                            ? 'Currently Available'
                            : 'Currently Offline / Busy',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isAvailable
                              ? AppColors.primaryGreenDark
                              : AppColors.warning,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        p?.availabilityHours != null &&
                                p!.availabilityHours!.isNotEmpty
                            ? 'Hours: ${p.availabilityHours}'
                            : 'General Office Hours: 09:30 AM - 05:30 PM',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
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
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
