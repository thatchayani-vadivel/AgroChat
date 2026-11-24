import 'package:flutter/material.dart';

import 'package:agrochat_app/core/theme/app_colors.dart';
import 'package:agrochat_app/features/officer/models/farmer_details_model.dart';
import 'package:agrochat_app/features/officer/repositories/officer_repository.dart';
import 'package:agrochat_app/shared/widgets/responsive_container.dart';
import 'package:agrochat_app/shared/widgets/status_feedback.dart';

/// Screen allowing an authorized Agricultural Officer to inspect a farmer's registered
/// profile, landholdings, farms, crops, and livestock.
class FarmerInspectionScreen extends StatefulWidget {
  const FarmerInspectionScreen({
    super.key,
    required this.farmerUserId,
    required this.repository,
  });

  final int farmerUserId;
  final OfficerRepository repository;

  @override
  State<FarmerInspectionScreen> createState() => _FarmerInspectionScreenState();
}

class _FarmerInspectionScreenState extends State<FarmerInspectionScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  FarmerInspectionModel? _farmerData;

  @override
  void initState() {
    super.initState();
    _loadFarmerDetails();
  }

  Future<void> _loadFarmerDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await widget.repository.getFarmerDetails(
        widget.farmerUserId,
      );
      if (mounted) {
        setState(() {
          _farmerData = data;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Farmer Inspection'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadFarmerDetails,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const AgroLoadingView(
        message: 'Loading farmer agricultural records...',
      );
    }

    if (_errorMessage != null || _farmerData == null) {
      return AgroEmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Unable to Load Farmer Details',
        description: _errorMessage ?? 'Farmer record not found.',
        actionLabel: 'Retry',
        onAction: _loadFarmerDetails,
      );
    }

    final farmer = _farmerData!;

    return RefreshIndicator(
      onRefresh: _loadFarmerDetails,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: ResponsiveContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildFarmerHeaderCard(farmer),
              const SizedBox(height: 16),
              _buildAgriculturalStats(farmer),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Registered Farms & Crops (${farmer.farms.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (farmer.farms.isEmpty)
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'This farmer has not registered any agricultural farm plots yet.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                )
              else
                ...farmer.farms.map(_buildFarmDetailTile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFarmerHeaderCard(FarmerInspectionModel farmer) {
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
                  radius: 28,
                  backgroundColor: AppColors.softMint,
                  child: Icon(
                    Icons.person_rounded,
                    size: 34,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        farmer.fullName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Farmer • Language: ${farmer.preferredLanguage}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.softMint,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Authorized',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreenDark,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24, color: AppColors.border),
            _infoRow(Icons.phone_outlined, 'Contact Phone', farmer.phoneNumber),
            const SizedBox(height: 6),
            _infoRow(Icons.email_outlined, 'Email Address', farmer.email),
            const SizedBox(height: 6),
            _infoRow(
              Icons.location_on_outlined,
              'Village & District',
              '${farmer.village.isNotEmpty ? '${farmer.village}, ' : ''}${farmer.talukOrBlock.isNotEmpty ? '${farmer.talukOrBlock}, ' : ''}${farmer.district}, ${farmer.state}${farmer.pincode != null ? ' - ${farmer.pincode}' : ''}',
            ),
            if (farmer.farmingExperienceYears != null) ...[
              const SizedBox(height: 6),
              _infoRow(
                Icons.work_history_outlined,
                'Farming Experience',
                '${farmer.farmingExperienceYears} years',
              ),
            ],
            if (farmer.bio != null && farmer.bio!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Farmer Bio: ${farmer.bio}',
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAgriculturalStats(FarmerInspectionModel farmer) {
    return Row(
      children: [
        Expanded(
          child: _statBox(
            'Farms',
            '${farmer.farms.length}',
            Icons.landscape_rounded,
            AppColors.primaryGreen,
            AppColors.softMint,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statBox(
            'Land Area',
            '${farmer.totalLandAcres.toStringAsFixed(1)} Ac',
            Icons.terrain_rounded,
            AppColors.warning,
            const Color(0xFFFBF4ED),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statBox(
            'Crops',
            '${farmer.totalCropsCount}',
            Icons.grass_rounded,
            const Color(0xFF2E7D32),
            const Color(0xFFE8F5E9),
          ),
        ),
      ],
    );
  }

  Widget _statBox(
    String label,
    String value,
    IconData icon,
    Color color,
    Color bg,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmDetailTile(dynamic farm) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.softMint,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.agriculture_rounded,
            color: AppColors.primaryGreen,
            size: 22,
          ),
        ),
        title: Text(
          farm.farmName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${farm.totalAreaAcres} Acres • ${farm.soilType} • ${farm.irrigationType}',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const Divider(height: 12, color: AppColors.border),
          if (farm.waterSource != null && farm.waterSource.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _infoRow(
                Icons.water_drop_outlined,
                'Water Source',
                farm.waterSource,
              ),
            ),
          if (farm.location.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _infoRow(Icons.place_outlined, 'Location', farm.location),
            ),
          const SizedBox(height: 6),
          const Text(
            'Cultivated Crops:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          if (farm.crops.isEmpty)
            const Text(
              'No crops recorded on this plot.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            )
          else
            ...farm.crops.map((crop) {
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FAF7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.grass_rounded,
                      size: 16,
                      color: Color(0xFF2E7D32),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${crop.cropName}${crop.variety != null && crop.variety.isNotEmpty ? ' (${crop.variety})' : ''}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${crop.season} • ${crop.areaAcres} Ac',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }),
          if (farm.livestock.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              'Livestock & Allied:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            ...farm.livestock.map((live) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.pets_rounded,
                      size: 14,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${live.count}x ${live.category} (${live.healthStatus})',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
