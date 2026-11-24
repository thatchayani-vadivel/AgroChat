import 'package:flutter/material.dart';

import 'package:agrochat_app/core/constants/app_languages.dart';
import 'package:agrochat_app/core/theme/app_colors.dart';
import 'package:agrochat_app/features/auth/models/auth_user.dart';
import 'package:agrochat_app/features/auth/presentation/login_screen.dart';
import 'package:agrochat_app/features/auth/repositories/auth_repository.dart';
import 'package:agrochat_app/features/farmer/models/farmer_profile_model.dart';
import 'package:agrochat_app/features/farmer/repositories/farmer_repository.dart';
import 'package:agrochat_app/shared/widgets/responsive_container.dart';
import 'package:agrochat_app/shared/widgets/status_feedback.dart';

/// Screen allowing the Farmer to view/edit agricultural profile details, change preferred regional language, and log out.
class FarmerProfileView extends StatefulWidget {
  const FarmerProfileView({
    super.key,
    required this.session,
    required this.repository,
    this.authRepository,
    required this.onSessionUpdated,
  });

  final AuthSession session;
  final FarmerRepository repository;
  final AuthRepository? authRepository;
  final void Function(AuthSession updatedSession) onSessionUpdated;

  @override
  State<FarmerProfileView> createState() => _FarmerProfileViewState();
}

class _FarmerProfileViewState extends State<FarmerProfileView> {
  bool _isLoading = true;
  String? _errorMessage;
  FarmerProfileModel? _profile;
  late String _currentLanguage;
  bool _isSavingLanguage = false;

  @override
  void initState() {
    super.initState();
    _currentLanguage = widget.session.user.preferredLanguage;
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await widget.repository.getFarmerProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
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

  Future<void> _updateLanguage(String newLanguage) async {
    if (newLanguage == _currentLanguage) return;

    setState(() => _isSavingLanguage = true);

    try {
      final updatedUser = await widget.repository.updatePreferredLanguage(
        newLanguage,
      );
      final newSession = AuthSession(
        accessToken: widget.session.accessToken,
        tokenType: widget.session.tokenType,
        expiresIn: widget.session.expiresIn,
        user: updatedUser,
      );

      final authRepo = widget.authRepository ?? AuthRepository();
      await authRepo.saveSession(newSession);

      if (mounted) {
        setState(() {
          _currentLanguage = newLanguage;
          _isSavingLanguage = false;
        });
        widget.onSessionUpdated(newSession);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Preferred language updated to "$newLanguage"'),
            backgroundColor: AppColors.primaryGreenDark,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSavingLanguage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update language: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _editProfileDialog() async {
    final current =
        _profile ?? FarmerProfileModel(id: 0, userId: widget.session.user.id);

    final villageCtrl = TextEditingController(text: current.village ?? '');
    final talukCtrl = TextEditingController(text: current.talukOrBlock ?? '');
    final districtCtrl = TextEditingController(text: current.district ?? '');
    final stateCtrl = TextEditingController(text: current.state ?? '');
    final pincodeCtrl = TextEditingController(text: current.pincode ?? '');
    final landCtrl = TextEditingController(
      text: current.totalLandholdingAcres != null
          ? '${current.totalLandholdingAcres}'
          : '',
    );
    final proofTypeCtrl = TextEditingController(
      text: current.identityProofType ?? 'Aadhaar Card',
    );
    final proofNumberCtrl = TextEditingController(
      text: current.identityProofNumber ?? '',
    );
    String commMode = current.preferredCommunicationMode;

    final formKey = GlobalKey<FormState>();

    final updated = await showDialog<FarmerProfileModel>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Agricultural Profile'),
            content: SizedBox(
              width: 480,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: villageCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Village',
                          prefixIcon: Icon(Icons.home_outlined),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: talukCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Taluk / Block / Tehsil',
                          prefixIcon: Icon(Icons.location_city_outlined),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: districtCtrl,
                              decoration: const InputDecoration(
                                labelText: 'District *',
                                prefixIcon: Icon(Icons.map_outlined),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: stateCtrl,
                              decoration: const InputDecoration(
                                labelText: 'State *',
                                prefixIcon: Icon(Icons.flag_outlined),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: pincodeCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Pincode',
                                prefixIcon: Icon(Icons.pin_drop_outlined),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: landCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Total Land (Acres)',
                                prefixIcon: Icon(Icons.terrain_outlined),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue:
                            const [
                              'Aadhaar Card',
                              'Voter ID',
                              'Kisan Credit Card',
                              'PAN Card',
                              'Ration Card',
                            ].contains(proofTypeCtrl.text)
                            ? proofTypeCtrl.text
                            : 'Aadhaar Card',
                        decoration: const InputDecoration(
                          labelText: 'Identity Proof Type',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        items:
                            const [
                                  'Aadhaar Card',
                                  'Voter ID',
                                  'Kisan Credit Card',
                                  'PAN Card',
                                  'Ration Card',
                                ]
                                .map(
                                  (t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(t),
                                  ),
                                )
                                .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => proofTypeCtrl.text = val);
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: proofNumberCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Identity Proof Number',
                          prefixIcon: Icon(Icons.numbers_outlined),
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: commMode,
                        decoration: const InputDecoration(
                          labelText: 'Preferred Communication Mode',
                          prefixIcon: Icon(Icons.chat_bubble_outline_rounded),
                        ),
                        items:
                            const [
                                  'In-App Message',
                                  'Phone Call',
                                  'WhatsApp',
                                  'SMS',
                                ]
                                .map(
                                  (m) => DropdownMenuItem(
                                    value: m,
                                    child: Text(m),
                                  ),
                                )
                                .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => commMode = val);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState?.validate() ?? false) {
                    final model = current.copyWith(
                      village: villageCtrl.text.trim(),
                      talukOrBlock: talukCtrl.text.trim(),
                      district: districtCtrl.text.trim(),
                      state: stateCtrl.text.trim(),
                      pincode: pincodeCtrl.text.trim(),
                      totalLandholdingAcres: double.tryParse(
                        landCtrl.text.trim(),
                      ),
                      identityProofType: proofTypeCtrl.text.trim(),
                      identityProofNumber: proofNumberCtrl.text.trim(),
                      preferredCommunicationMode: commMode,
                    );
                    Navigator.of(ctx).pop(model);
                  }
                },
                child: const Text('Save Profile'),
              ),
            ],
          );
        },
      ),
    );

    if (updated == null || !mounted) return;

    try {
      final saved = await widget.repository.updateFarmerProfile(updated);
      if (mounted) {
        setState(() => _profile = saved);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Agricultural profile updated successfully!'),
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
      return const AgroLoadingView(message: 'Loading farmer profile...');
    }

    if (_errorMessage != null && _profile == null) {
      return AgroEmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Unable to Load Profile',
        description: _errorMessage!,
        actionLabel: 'Retry',
        onAction: _loadProfile,
      );
    }

    final user = widget.session.user;

    return RefreshIndicator(
      onRefresh: _loadProfile,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: ResponsiveContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildAccountCard(user),
              const SizedBox(height: 16),
              _buildAgriculturalProfileCard(),
              const SizedBox(height: 16),
              _buildLanguageCard(),
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
                    Icons.person_rounded,
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
                          'Role: Farmer',
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
            _infoRow('Email', user.email, Icons.email_outlined),
            const SizedBox(height: 8),
            _infoRow('Phone', user.phoneNumber, Icons.phone_outlined),
            const SizedBox(height: 8),
            _infoRow(
              'Account Status',
              user.isActive ? 'Active' : 'Inactive',
              Icons.verified_user_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgriculturalProfileCard() {
    final p = _profile;
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
                        Icons.agriculture_rounded,
                        color: AppColors.primaryGreen,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Agricultural Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: _editProfileDialog,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit'),
                ),
              ],
            ),
            const Divider(height: 16, color: AppColors.border),
            _infoRow(
              'Village',
              p?.village ?? 'Not configured',
              Icons.home_outlined,
            ),
            const SizedBox(height: 8),
            _infoRow(
              'Taluk / Block',
              p?.talukOrBlock ?? 'Not configured',
              Icons.location_city_outlined,
            ),
            const SizedBox(height: 8),
            _infoRow(
              'Location',
              '${p?.district ?? 'District'}, ${p?.state ?? 'State'}${p?.pincode != null ? ' - ${p!.pincode}' : ''}',
              Icons.map_outlined,
            ),
            const SizedBox(height: 8),
            _infoRow(
              'Total Landholding',
              p?.totalLandholdingAcres != null
                  ? '${p!.totalLandholdingAcres} Acres'
                  : 'Not configured',
              Icons.terrain_outlined,
            ),
            const SizedBox(height: 8),
            _infoRow(
              'Identity Proof',
              p?.identityProofType != null
                  ? '${p!.identityProofType}: ${p.identityProofNumber ?? 'Registered'}'
                  : 'Not provided',
              Icons.badge_outlined,
            ),
            const SizedBox(height: 8),
            _infoRow(
              'Preferred Contact',
              p?.preferredCommunicationMode ?? 'In-App Message',
              Icons.chat_bubble_outline_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageCard() {
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
                Icon(Icons.translate_rounded, color: AppColors.primaryGreen),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Regional Language Preferences',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Select your preferred regional language for agricultural guidance, voice advisory, and officer communications.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            if (_isSavingLanguage)
              const LinearProgressIndicator(minHeight: 3)
            else
              DropdownButtonFormField<String>(
                initialValue: AppLanguages.supported.contains(_currentLanguage)
                    ? _currentLanguage
                    : AppLanguages.defaultLanguage,
                decoration: InputDecoration(
                  labelText: 'Preferred Language',
                  prefixIcon: const Icon(Icons.language_rounded),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                items: AppLanguages.supported.map((lang) {
                  return DropdownMenuItem(
                    value: lang,
                    child: Text(
                      lang,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) _updateLanguage(val);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, IconData icon) {
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
