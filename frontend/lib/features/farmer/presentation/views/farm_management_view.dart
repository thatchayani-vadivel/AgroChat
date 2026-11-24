import 'package:flutter/material.dart';

import 'package:agrochat_app/core/theme/app_colors.dart';
import 'package:agrochat_app/features/farmer/models/farm_model.dart';
import 'package:agrochat_app/features/farmer/presentation/screens/farm_detail_screen.dart';
import 'package:agrochat_app/features/farmer/presentation/widgets/add_edit_farm_dialog.dart';
import 'package:agrochat_app/features/farmer/repositories/farmer_repository.dart';
import 'package:agrochat_app/shared/widgets/responsive_container.dart';
import 'package:agrochat_app/shared/widgets/status_feedback.dart';

/// Screen allowing the Farmer to view, add, edit, and delete their registered agricultural farms.
class FarmManagementView extends StatefulWidget {
  const FarmManagementView({super.key, required this.repository});

  final FarmerRepository repository;

  @override
  State<FarmManagementView> createState() => FarmManagementViewState();
}

class FarmManagementViewState extends State<FarmManagementView> {
  bool _isLoading = true;
  String? _errorMessage;
  List<FarmModel> _farms = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    loadFarms();
  }

  Future<void> loadFarms() async {
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

  Future<void> _addFarm() async {
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
          content: Text('Farm "${result.farmName}" created successfully!'),
          backgroundColor: AppColors.primaryGreenDark,
        ),
      );
      await loadFarms();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create farm: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _editFarm(FarmModel farm) async {
    final result = await showDialog<FarmModel>(
      context: context,
      builder: (_) => AddEditFarmDialog(existingFarm: farm),
    );
    if (result == null || !mounted) return;

    try {
      await widget.repository.updateFarm(farm.id, result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Farm "${result.farmName}" updated successfully!'),
          backgroundColor: AppColors.primaryGreenDark,
        ),
      );
      await loadFarms();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update farm: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _confirmDeleteFarm(FarmModel farm) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Farm'),
        content: Text(
          'Are you sure you want to delete "${farm.farmName}"?\n\n'
          'All ${farm.crops.length} associated crop records and '
          '${farm.livestock.length} livestock entries will also be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await widget.repository.deleteFarm(farm.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Farm "${farm.farmName}" deleted.'),
          backgroundColor: AppColors.primaryGreenDark,
        ),
      );
      await loadFarms();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete farm: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  List<FarmModel> get _filteredFarms {
    if (_searchQuery.trim().isEmpty) return _farms;
    final q = _searchQuery.toLowerCase();
    return _farms.where((f) {
      return f.farmName.toLowerCase().contains(q) ||
          f.district.toLowerCase().contains(q) ||
          f.state.toLowerCase().contains(q) ||
          f.soilType.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addFarm,
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.surfaceWhite,
        icon: const Icon(Icons.add_location_alt_rounded),
        label: const Text('Add Farm'),
      ),
      body: RefreshIndicator(onRefresh: loadFarms, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const AgroLoadingView(message: 'Loading farms...');
    }

    if (_errorMessage != null && _farms.isEmpty) {
      return AgroEmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Unable to Load Farms',
        description: _errorMessage!,
        actionLabel: 'Retry',
        onAction: loadFarms,
      );
    }

    return ResponsiveContainer(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search farms by name, district, or soil...',
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
          ),
          Expanded(
            child: _filteredFarms.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 88,
                      top: 8,
                    ),
                    itemCount: _filteredFarms.length,
                    itemBuilder: (context, index) {
                      return _buildFarmCard(_filteredFarms[index]);
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
              Icons.landscape_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No farms match "$_searchQuery"'
                  : 'No Agricultural Farms Registered Yet',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try searching with a different farm name or district.'
                  : 'Register your land plots to manage soil details, irrigation systems, crops, and livestock.',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _addFarm,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Your First Farm'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFarmCard(FarmModel farm) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  FarmDetailScreen(farm: farm, repository: widget.repository),
            ),
          );
          loadFarms();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.softMint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.agriculture_rounded,
                      color: AppColors.primaryGreen,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          farm.farmName,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${farm.location.isNotEmpty ? '${farm.location}, ' : ''}${farm.district}, ${farm.state}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: AppColors.textSecondary,
                    ),
                    onSelected: (val) {
                      if (val == 'edit') {
                        _editFarm(farm);
                      } else if (val == 'delete') {
                        _confirmDeleteFarm(farm);
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: AppColors.primaryGreen,
                            ),
                            SizedBox(width: 8),
                            Text('Edit Farm'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: AppColors.error,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Delete Farm',
                              style: TextStyle(color: AppColors.error),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _chip(
                    Icons.square_foot_rounded,
                    '${farm.totalAreaAcres} Acres',
                    AppColors.primaryGreenDark,
                  ),
                  _chip(
                    Icons.layers_outlined,
                    farm.soilType,
                    AppColors.warning,
                  ),
                  _chip(
                    Icons.water_drop_outlined,
                    farm.irrigationType,
                    AppColors.info,
                  ),
                  if (farm.ownershipType != null &&
                      farm.ownershipType!.isNotEmpty)
                    _chip(
                      Icons.verified_user_outlined,
                      farm.ownershipType!,
                      AppColors.primaryGreen,
                    ),
                ],
              ),
              const Divider(height: 20, color: AppColors.border),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.grass_rounded,
                        size: 16,
                        color: Colors.green.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${farm.crops.length} Crops',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade800,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Icon(
                        Icons.pets_rounded,
                        size: 16,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${farm.livestock.length} Livestock',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                  const Row(
                    children: [
                      Text(
                        'View Details',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: AppColors.primaryGreen,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
