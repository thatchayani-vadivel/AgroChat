import 'package:flutter/material.dart';

import 'package:agrochat_app/core/theme/app_colors.dart';
import 'package:agrochat_app/features/officer/models/assistance_request_model.dart';
import 'package:agrochat_app/features/officer/presentation/screens/request_detail_screen.dart';
import 'package:agrochat_app/features/officer/repositories/officer_repository.dart';
import 'package:agrochat_app/shared/widgets/responsive_container.dart';
import 'package:agrochat_app/shared/widgets/status_feedback.dart';

/// Screen allowing the Agricultural Officer to browse, filter, inspect, and respond to
/// farmer assistance requests.
class OfficerRequestsView extends StatefulWidget {
  const OfficerRequestsView({super.key, required this.repository});

  final OfficerRepository repository;

  @override
  State<OfficerRequestsView> createState() => OfficerRequestsViewState();
}

class OfficerRequestsViewState extends State<OfficerRequestsView> {
  bool _isLoading = true;
  String? _errorMessage;
  List<AssistanceRequestModel> _requests = [];
  String _selectedScope = 'all';
  String _selectedStatus = 'all';
  String _searchQuery = '';

  static const List<String> _statusFilters = [
    'all',
    'pending',
    'accepted',
    'in_progress',
    'resolved',
    'rejected',
  ];

  @override
  void initState() {
    super.initState();
    loadRequests();
  }

  Future<void> loadRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final reqs = await widget.repository.listRequests(
        scope: _selectedScope,
        status: _selectedStatus == 'all' ? null : _selectedStatus,
      );
      if (mounted) {
        setState(() {
          _requests = reqs;
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

  List<AssistanceRequestModel> get _filteredRequests {
    if (_searchQuery.trim().isEmpty) return _requests;
    final q = _searchQuery.toLowerCase();
    return _requests.where((r) {
      return r.title.toLowerCase().contains(q) ||
          r.category.toLowerCase().contains(q) ||
          (r.farmerName?.toLowerCase().contains(q) ?? false) ||
          (r.cropName?.toLowerCase().contains(q) ?? false) ||
          (r.farmName?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(onRefresh: loadRequests, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const AgroLoadingView(message: 'Loading farmer requests...');
    }

    if (_errorMessage != null && _requests.isEmpty) {
      return AgroEmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Unable to Load Requests',
        description: _errorMessage!,
        actionLabel: 'Retry',
        onAction: loadRequests,
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
                    hintText: 'Search by issue, farmer name, crop...',
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
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'all', label: Text('All')),
                          ButtonSegment(
                            value: 'open',
                            label: Text('Open / Pending'),
                          ),
                          ButtonSegment(
                            value: 'assigned',
                            label: Text('My Assigned'),
                          ),
                        ],
                        selected: {_selectedScope},
                        onSelectionChanged: (set) {
                          setState(() => _selectedScope = set.first);
                          loadRequests();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _statusFilters.map((s) {
                      final isSelected = _selectedStatus == s;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          selected: isSelected,
                          label: Text(
                            s == 'all'
                                ? 'All Status'
                                : s.replaceAll('_', ' ').toUpperCase(),
                          ),
                          selectedColor: AppColors.softMint,
                          checkmarkColor: AppColors.primaryGreenDark,
                          labelStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? AppColors.primaryGreenDark
                                : AppColors.textPrimary,
                          ),
                          onSelected: (_) {
                            setState(() => _selectedStatus = s);
                            loadRequests();
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
            child: _filteredRequests.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 24,
                      top: 4,
                    ),
                    itemCount: _filteredRequests.length,
                    itemBuilder: (context, index) {
                      return _buildRequestCard(_filteredRequests[index]);
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
              Icons.inbox_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No requests match "$_searchQuery"'
                  : 'No Requests Found',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try adjusting your search query or filter tags.'
                  : 'There are currently no farmer requests under the selected scope/status filter.',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(AssistanceRequestModel req) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
              builder: (_) => RequestDetailScreen(
                requestId: req.id,
                repository: widget.repository,
              ),
            ),
          );
          loadRequests();
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
                      color: req.isPending
                          ? const Color(0xFFFFF3E0)
                          : AppColors.softMint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      req.isPending
                          ? Icons.pending_actions_rounded
                          : Icons.support_agent_rounded,
                      color: req.isPending
                          ? AppColors.warning
                          : AppColors.primaryGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          req.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Farmer: ${req.farmerName ?? "#${req.farmerId}"}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _statusBadge(req.status),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _priorityBadge(req.priority),
                  _badge(req.category, AppColors.primaryGreenDark),
                  if (req.cropName != null && req.cropName!.isNotEmpty)
                    _badge('Crop: ${req.cropName}', const Color(0xFF2E7D32)),
                  if (req.farmName != null && req.farmName!.isNotEmpty)
                    _badge('Farm: ${req.farmName}', AppColors.warning),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                req.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const Divider(height: 20, color: AppColors.border),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    req.createdAt != null
                        ? 'Submitted: ${req.createdAt!.toLocal().toString().split(".")[0].substring(0, 16)}'
                        : '',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Row(
                    children: [
                      Text(
                        'Review & Action',
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

  Widget _statusBadge(String status) {
    Color bg;
    Color fg;

    switch (status.toLowerCase()) {
      case 'pending':
        bg = const Color(0xFFFFF3E0);
        fg = AppColors.warning;
        break;
      case 'accepted':
      case 'in_progress':
        bg = AppColors.softMint;
        fg = AppColors.primaryGreenDark;
        break;
      case 'resolved':
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF2E7D32);
        break;
      case 'rejected':
      case 'cancelled':
        bg = const Color(0xFFFFEBEE);
        fg = AppColors.error;
        break;
      default:
        bg = AppColors.softMint;
        fg = AppColors.textPrimary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  Widget _priorityBadge(String priority) {
    final p = priority.toLowerCase();
    Color color = AppColors.textSecondary;
    if (p == 'urgent' || p == 'high') color = AppColors.error;
    if (p == 'medium') color = AppColors.warning;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        'Priority: ${priority.toUpperCase()}',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
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
