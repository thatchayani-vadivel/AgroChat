import 'package:flutter/material.dart';

import 'package:agrochat_app/core/theme/app_colors.dart';
import 'package:agrochat_app/features/farmer/models/farm_model.dart';
import 'package:agrochat_app/features/farmer/presentation/screens/farmer_request_detail_screen.dart';
import 'package:agrochat_app/features/farmer/presentation/widgets/create_request_dialog.dart';
import 'package:agrochat_app/features/farmer/repositories/farmer_repository.dart';
import 'package:agrochat_app/features/officer/models/assistance_request_model.dart';
import 'package:agrochat_app/shared/widgets/status_feedback.dart';

/// Screen listing all Assistance Requests created by the Farmer.
class FarmerRequestsScreen extends StatefulWidget {
  const FarmerRequestsScreen({super.key, required this.repository});

  final FarmerRepository repository;

  @override
  State<FarmerRequestsScreen> createState() => _FarmerRequestsScreenState();
}

class _FarmerRequestsScreenState extends State<FarmerRequestsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<AssistanceRequestModel> _requests = [];
  List<FarmModel> _farms = [];
  String _selectedStatus = 'all';
  String _searchQuery = '';

  final List<String> _statusFilters = [
    'all',
    'pending',
    'assigned',
    'in_progress',
    'resolved',
    'rejected',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final reqsFuture = widget.repository.listMyRequests();
      final farmsFuture = widget.repository.listFarms();
      final results = await Future.wait([reqsFuture, farmsFuture]);

      if (mounted) {
        setState(() {
          _requests = results[0] as List<AssistanceRequestModel>;
          _farms = results[1] as List<FarmModel>;
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

  Future<void> _openCreateDialog() async {
    final result = await showDialog<AssistanceRequestModel>(
      context: context,
      builder: (_) =>
          CreateRequestDialog(repository: widget.repository, farms: _farms),
    );

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Request "${result.title}" created successfully!'),
          backgroundColor: AppColors.primaryGreenDark,
        ),
      );
      _loadData();
    }
  }

  List<AssistanceRequestModel> get _filteredRequests {
    return _requests.where((r) {
      final matchStatus =
          _selectedStatus == 'all' ||
          r.status.toLowerCase() == _selectedStatus.toLowerCase();
      final matchSearch =
          _searchQuery.isEmpty ||
          r.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (r.category.toLowerCase().contains(_searchQuery.toLowerCase())) ||
          (r.cropName != null &&
              r.cropName!.toLowerCase().contains(_searchQuery.toLowerCase())) ||
          (r.officerName != null &&
              r.officerName!.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ));
      return matchStatus && matchSearch;
    }).toList();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.warning;
      case 'assigned':
      case 'accepted':
        return AppColors.info;
      case 'in_progress':
        return const Color(0xFF8E24AA);
      case 'resolved':
        return AppColors.primaryGreen;
      case 'rejected':
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistance Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.surfaceWhite,
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search requests by title, crop, officer...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _statusFilters.map((s) {
                      final isSelected = _selectedStatus == s;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          selected: isSelected,
                          label: Text(s.replaceAll('_', ' ').toUpperCase()),
                          labelStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? AppColors.surfaceWhite
                                : AppColors.textPrimary,
                          ),
                          backgroundColor: AppColors.background,
                          selectedColor: AppColors.primaryGreen,
                          onSelected: (_) =>
                              setState(() => _selectedStatus = s),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Requests list
          Expanded(
            child: _isLoading
                ? const AgroLoadingView(message: 'Loading requests...')
                : _errorMessage != null && _requests.isEmpty
                ? AgroEmptyState(
                    icon: Icons.error_outline_rounded,
                    title: 'Unable to Load Requests',
                    description: _errorMessage!,
                    actionLabel: 'Retry',
                    onAction: _loadData,
                  )
                : _filteredRequests.isEmpty
                ? AgroEmptyState(
                    icon: Icons.support_agent_rounded,
                    title: 'No Assistance Requests Found',
                    description: _requests.isEmpty
                        ? 'Need agricultural guidance for crop diseases, pest attacks, or soil health? Submit a request to connect directly with local extension officers.'
                        : 'No requests match your selected filters.',
                    actionLabel: 'Create Request',
                    onAction: _openCreateDialog,
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredRequests.length,
                      separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final req = _filteredRequests[index];
                        final statusColor = _getStatusColor(req.status);

                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: AppColors.border),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => FarmerRequestDetailScreen(
                                    requestId: req.id,
                                    repository: widget.repository,
                                  ),
                                ),
                              );
                              _loadData();
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          req.title,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: statusColor,
                                          ),
                                        ),
                                        child: Text(
                                          req.status.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: statusColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    req.description,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      if (req.cropName != null) ...[
                                        const Icon(
                                          Icons.grass_rounded,
                                          size: 14,
                                          color: AppColors.primaryGreen,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          req.cropName!,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                      ],
                                      if (req.officerName != null) ...[
                                        const Icon(
                                          Icons.person_pin_circle_rounded,
                                          size: 14,
                                          color: AppColors.info,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            'Officer: ${req.officerName}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.info,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ] else ...[
                                        const Expanded(
                                          child: Text(
                                            'Awaiting Officer Assignment',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textSecondary,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                      ],
                                      const Icon(
                                        Icons.chevron_right_rounded,
                                        color: AppColors.textSecondary,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.surfaceWhite,
        icon: const Icon(Icons.add_comment_rounded),
        label: const Text('Ask Officer'),
        onPressed: _openCreateDialog,
      ),
    );
  }
}
