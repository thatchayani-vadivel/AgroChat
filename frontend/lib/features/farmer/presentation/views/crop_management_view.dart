import 'package:flutter/material.dart';

import 'package:agrochat_app/core/theme/app_colors.dart';
import 'package:agrochat_app/features/farmer/models/farm_model.dart';
import 'package:agrochat_app/features/farmer/presentation/widgets/add_edit_crop_dialog.dart';
import 'package:agrochat_app/features/farmer/repositories/farmer_repository.dart';
import 'package:agrochat_app/shared/widgets/responsive_container.dart';
import 'package:agrochat_app/shared/widgets/status_feedback.dart';

/// Screen allowing the Farmer to view, add, edit, and delete agricultural crops across all their farms.
class CropManagementView extends StatefulWidget {
  const CropManagementView({
    super.key,
    required this.repository,
    this.onNavigateToFarms,
  });

  final FarmerRepository repository;
  final VoidCallback? onNavigateToFarms;

  @override
  State<CropManagementView> createState() => CropManagementViewState();
}

class CropItemEntry {
  const CropItemEntry({required this.crop, required this.farm});

  final CropModel crop;
  final FarmModel farm;
}

class CropManagementViewState extends State<CropManagementView> {
  bool _isLoading = true;
  String? _errorMessage;
  List<FarmModel> _farms = [];
  String _selectedSeason = 'All';
  String _searchQuery = '';

  static const List<String> _seasonFilters = [
    'All',
    'Kharif',
    'Rabi',
    'Zaid',
    'Perennial',
  ];

  @override
  void initState() {
    super.initState();
    loadCrops();
  }

  Future<void> loadCrops() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final farms = await widget.repository.listFarms();
      if (mounted) {
        setState(() {
          _farms = farms;
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

  List<CropItemEntry> get _allCropEntries {
    final list = <CropItemEntry>[];
    for (final farm in _farms) {
      for (final crop in farm.crops) {
        list.add(CropItemEntry(crop: crop, farm: farm));
      }
    }
    return list;
  }

  List<CropItemEntry> get _filteredCropEntries {
    return _allCropEntries.where((entry) {
      final matchesSeason =
          _selectedSeason == 'All' ||
          entry.crop.season.toLowerCase() == _selectedSeason.toLowerCase();
      final q = _searchQuery.toLowerCase();
      final matchesQuery =
          q.isEmpty ||
          entry.crop.cropName.toLowerCase().contains(q) ||
          (entry.crop.variety?.toLowerCase().contains(q) ?? false) ||
          entry.farm.farmName.toLowerCase().contains(q);
      return matchesSeason && matchesQuery;
    }).toList();
  }

  Future<void> _addNewCrop() async {
    if (_farms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please register at least one farm before adding crops.',
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      if (widget.onNavigateToFarms != null) {
        widget.onNavigateToFarms!();
      }
      return;
    }

    FarmModel selectedFarm;
    if (_farms.length == 1) {
      selectedFarm = _farms.first;
    } else {
      final picked = await showDialog<FarmModel>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Text('Select Farm for New Crop'),
          children: _farms.map((f) {
            return SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop(f),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.landscape_rounded,
                      color: AppColors.primaryGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f.farmName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${f.district}, ${f.totalAreaAcres} Acres',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      );
      if (picked == null || !mounted) return;
      selectedFarm = picked;
    }

    final result = await showDialog<CropModel>(
      context: context,
      builder: (_) => AddEditCropDialog(farmId: selectedFarm.id),
    );
    if (result == null || !mounted) return;

    try {
      await widget.repository.addCrop(selectedFarm.id, result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Crop "${result.cropName}" registered to ${selectedFarm.farmName}!',
          ),
          backgroundColor: AppColors.primaryGreenDark,
        ),
      );
      await loadCrops();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add crop: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _editCrop(CropItemEntry entry) async {
    final result = await showDialog<CropModel>(
      context: context,
      builder: (_) =>
          AddEditCropDialog(farmId: entry.farm.id, existingCrop: entry.crop),
    );
    if (result == null || !mounted) return;

    try {
      await widget.repository.updateCrop(entry.farm.id, entry.crop.id, result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Crop "${result.cropName}" details updated!'),
          backgroundColor: AppColors.primaryGreenDark,
        ),
      );
      await loadCrops();
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

  Future<void> _confirmDeleteCrop(CropItemEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Crop Record'),
        content: Text(
          'Are you sure you want to delete "${entry.crop.cropName}" from farm "${entry.farm.farmName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await widget.repository.deleteCrop(entry.farm.id, entry.crop.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Crop "${entry.crop.cropName}" removed.'),
          backgroundColor: AppColors.primaryGreenDark,
        ),
      );
      await loadCrops();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete crop: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewCrop,
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.surfaceWhite,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Crop'),
      ),
      body: RefreshIndicator(onRefresh: loadCrops, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const AgroLoadingView(message: 'Loading crops...');
    }

    if (_errorMessage != null && _allCropEntries.isEmpty) {
      return AgroEmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Unable to Load Crops',
        description: _errorMessage!,
        actionLabel: 'Retry',
        onAction: loadCrops,
      );
    }

    return ResponsiveContainer(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search crops by name, variety, or farm...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _seasonFilters.map((season) {
                      final isSelected = _selectedSeason == season;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          selected: isSelected,
                          label: Text(season),
                          selectedColor: AppColors.softMint,
                          checkmarkColor: AppColors.primaryGreenDark,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? AppColors.primaryGreenDark
                                : AppColors.textPrimary,
                          ),
                          onSelected: (_) {
                            setState(() => _selectedSeason = season);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _filteredCropEntries.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 88,
                      top: 4,
                    ),
                    itemCount: _filteredCropEntries.length,
                    itemBuilder: (context, index) {
                      return _buildCropCard(_filteredCropEntries[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.grass_rounded,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty || _selectedSeason != 'All'
                  ? 'No crops match your filter criteria'
                  : 'No Crops Registered Yet',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _farms.isEmpty
                  ? 'First register a farm plot, then start recording cultivated crops for stage tracking.'
                  : 'Add crops to track growth stages, sowing and harvest schedules, and receive targeted advisory.',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _addNewCrop,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                _farms.isEmpty ? 'Register a Farm First' : 'Add First Crop',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCropCard(CropItemEntry entry) {
    final crop = entry.crop;
    final farm = entry.farm;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.grass_rounded,
                    color: Color(0xFF2E7D32),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              crop.cropName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.softMint,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              crop.season,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryGreenDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (crop.variety != null && crop.variety!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Variety: ${crop.variety}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.landscape_rounded,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            farm.farmName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _badge(
                  'Area: ${crop.areaAcres} Acres',
                  AppColors.primaryGreenDark,
                ),
                if (crop.growthStage != null && crop.growthStage!.isNotEmpty)
                  _badge('Stage: ${crop.growthStage}', AppColors.info),
                if (crop.estimatedYieldKg != null)
                  _badge(
                    'Yield: ${crop.estimatedYieldKg} kg',
                    AppColors.warning,
                  ),
              ],
            ),
            if (crop.sowingDate != null ||
                crop.expectedHarvestDate != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (crop.sowingDate != null)
                    Expanded(
                      child: Text(
                        'Sown: ${crop.sowingDate}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  if (crop.expectedHarvestDate != null)
                    Expanded(
                      child: Text(
                        'Harvest: ${crop.expectedHarvestDate}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ],
            const Divider(height: 16, color: AppColors.border),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _editCrop(entry),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryGreen,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _confirmDeleteCrop(entry),
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                ),
              ],
            ),
          ],
        ),
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
