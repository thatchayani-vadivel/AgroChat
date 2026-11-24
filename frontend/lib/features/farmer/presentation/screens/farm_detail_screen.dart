import 'package:flutter/material.dart';

import 'package:agrochat_app/core/theme/app_colors.dart';
import 'package:agrochat_app/features/farmer/models/farm_model.dart';
import 'package:agrochat_app/features/farmer/presentation/widgets/add_edit_crop_dialog.dart';
import 'package:agrochat_app/features/farmer/presentation/widgets/add_livestock_dialog.dart';
import 'package:agrochat_app/features/farmer/repositories/farmer_repository.dart';
import 'package:agrochat_app/shared/widgets/status_feedback.dart';

/// Screen displaying detailed information, crops, and livestock for a specific Farm.
class FarmDetailScreen extends StatefulWidget {
  const FarmDetailScreen({
    super.key,
    required this.farm,
    required this.repository,
  });

  final FarmModel farm;
  final FarmerRepository repository;

  @override
  State<FarmDetailScreen> createState() => _FarmDetailScreenState();
}

class _FarmDetailScreenState extends State<FarmDetailScreen> {
  late FarmModel _farm;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _farm = widget.farm;
  }

  Future<void> _refreshFarm() async {
    setState(() => _isLoading = true);
    try {
      final farms = await widget.repository.listFarms();
      final updated = farms.firstWhere(
        (f) => f.id == _farm.id,
        orElse: () => _farm,
      );
      if (mounted) {
        setState(() {
          _farm = updated;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addCrop() async {
    final result = await showDialog<CropModel>(
      context: context,
      builder: (_) => AddEditCropDialog(farmId: _farm.id),
    );
    if (result == null || !mounted) return;

    try {
      await widget.repository.addCrop(_farm.id, result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Crop "${result.cropName}" registered successfully!'),
          backgroundColor: AppColors.primaryGreenDark,
        ),
      );
      await _refreshFarm();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save crop: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _editCrop(CropModel crop) async {
    final result = await showDialog<CropModel>(
      context: context,
      builder: (_) => AddEditCropDialog(farmId: _farm.id, existingCrop: crop),
    );
    if (result == null || !mounted) return;

    try {
      await widget.repository.updateCrop(_farm.id, crop.id, result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Crop details updated!'),
          backgroundColor: AppColors.primaryGreenDark,
        ),
      );
      await _refreshFarm();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update crop: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _deleteCrop(CropModel crop) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Crop?'),
        content: Text(
          'Are you sure you want to remove "${crop.cropName}" from this farm?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await widget.repository.deleteCrop(_farm.id, crop.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Removed ${crop.cropName}')));
      await _refreshFarm();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove crop: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _addLivestock() async {
    final result = await showDialog<LivestockModel>(
      context: context,
      builder: (_) => AddLivestockDialog(farmId: _farm.id),
    );
    if (result == null || !mounted) return;

    try {
      await widget.repository.addLivestock(_farm.id, result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${result.category} added to farm!'),
          backgroundColor: AppColors.primaryGreenDark,
        ),
      );
      await _refreshFarm();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save livestock: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _deleteLivestock(LivestockModel livestock) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Livestock Record?'),
        content: Text(
          'Are you sure you want to remove ${livestock.count} ${livestock.category}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await widget.repository.deleteLivestock(_farm.id, livestock.id);
      if (!mounted) return;
      await _refreshFarm();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_farm.farmName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refreshFarm,
          ),
        ],
      ),
      body: _isLoading
          ? const AgroLoadingView(message: 'Refreshing farm details...')
          : RefreshIndicator(
              onRefresh: _refreshFarm,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Farm Overview Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const CircleAvatar(
                                  backgroundColor: AppColors.softMint,
                                  child: Icon(
                                    Icons.terrain_rounded,
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _farm.farmName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      Text(
                                        '${_farm.location}, ${_farm.district}, ${_farm.state}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24, color: AppColors.border),
                            _detailRow(
                              context,
                              'Total Land Area',
                              '${_farm.totalAreaAcres} Acres',
                            ),
                            _detailRow(context, 'Soil Type', _farm.soilType),
                            _detailRow(
                              context,
                              'Irrigation Type',
                              _farm.irrigationType,
                            ),
                            if (_farm.waterSource != null &&
                                _farm.waterSource!.isNotEmpty)
                              _detailRow(
                                context,
                                'Water Source',
                                _farm.waterSource!,
                              ),
                            if (_farm.ownershipType != null)
                              _detailRow(
                                context,
                                'Land Ownership',
                                _farm.ownershipType!,
                              ),
                            if (_farm.notes != null && _farm.notes!.isNotEmpty)
                              _detailRow(context, 'Notes', _farm.notes!),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section: Cultivated Crops
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Cultivated Crops (${_farm.crops.length})',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        TextButton.icon(
                          onPressed: _addCrop,
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Add Crop'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_farm.crops.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Text(
                              'No crops currently listed on this farm.\nTap "Add Crop" to register your crop variety.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _farm.crops.length,
                        itemBuilder: (context, idx) {
                          final c = _farm.crops[idx];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: AppColors.softMint,
                                child: Icon(
                                  Icons.grass_rounded,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                              title: Text(
                                c.cropName +
                                    (c.variety != null && c.variety!.isNotEmpty
                                        ? ' (${c.variety})'
                                        : ''),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                'Season: ${c.season} • Area: ${c.areaAcres} Acres\n'
                                'Stage: ${c.growthStage ?? "Growing"}'
                                '${c.sowingDate != null ? " • Sown: ${c.sowingDate}" : ""}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit_rounded,
                                      size: 20,
                                      color: AppColors.textSecondary,
                                    ),
                                    onPressed: () => _editCrop(c),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      size: 20,
                                      color: AppColors.error,
                                    ),
                                    onPressed: () => _deleteCrop(c),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 20),

                    // Section: Livestock & Allied
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Livestock & Allied (${_farm.livestock.length})',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        TextButton.icon(
                          onPressed: _addLivestock,
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Add Livestock'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_farm.livestock.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Text(
                              'No livestock or allied activities recorded for this farm.\nTap "Add Livestock" to record cattle, poultry, or dairy.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _farm.livestock.length,
                        itemBuilder: (context, idx) {
                          final l = _farm.livestock[idx];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFFFF3E0),
                                child: Icon(
                                  Icons.pets_rounded,
                                  color: AppColors.warning,
                                ),
                              ),
                              title: Text(
                                '${l.count}x ${l.category}${l.breedOrType != null && l.breedOrType!.isNotEmpty ? ' (${l.breedOrType})' : ''}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                'Purpose: ${l.purpose ?? "General"} • Status: ${l.healthStatus}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 20,
                                  color: AppColors.error,
                                ),
                                onPressed: () => _deleteLivestock(l),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
