import 'package:flutter/material.dart';

import 'package:agrochat_app/core/theme/app_colors.dart';
import 'package:agrochat_app/features/officer/models/assistance_request_model.dart';
import 'package:agrochat_app/features/officer/presentation/screens/consultation_chat_screen.dart';
import 'package:agrochat_app/features/officer/presentation/screens/farmer_inspection_screen.dart';
import 'package:agrochat_app/features/officer/presentation/widgets/reject_request_dialog.dart';
import 'package:agrochat_app/features/officer/presentation/widgets/update_status_dialog.dart';
import 'package:agrochat_app/features/officer/repositories/officer_repository.dart';
import 'package:agrochat_app/shared/widgets/responsive_container.dart';
import 'package:agrochat_app/shared/widgets/status_feedback.dart';

/// Screen displaying the full information of an assistance request, attached photos,
/// farmer profile shortcut, accept/reject actions, and status updates.
class RequestDetailScreen extends StatefulWidget {
  const RequestDetailScreen({
    super.key,
    required this.requestId,
    required this.repository,
  });

  final int requestId;
  final OfficerRepository repository;

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  AssistanceRequestModel? _request;
  bool _isActionProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadRequest();
  }

  Future<void> _loadRequest() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final req = await widget.repository.getRequestDetails(widget.requestId);
      if (mounted) {
        setState(() {
          _request = req;
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

  Future<void> _acceptRequest() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Accept Assistance Request'),
        content: Text(
          'Are you sure you want to accept this request from ${_request?.farmerName ?? "the farmer"}?\n\n'
          'This will assign the request to you and open an active advisory consultation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Accept Request'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isActionProcessing = true);
    try {
      await widget.repository.acceptRequest(widget.requestId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Request accepted successfully. Active consultation opened!',
          ),
          backgroundColor: AppColors.primaryGreenDark,
        ),
      );
      await _loadRequest();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to accept request: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isActionProcessing = false);
    }
  }

  Future<void> _rejectRequest() async {
    if (_request == null) return;

    final reason = await showDialog<String>(
      context: context,
      builder: (_) => RejectRequestDialog(requestTitle: _request!.title),
    );

    if (reason == null || reason.trim().isEmpty || !mounted) return;

    setState(() => _isActionProcessing = true);
    try {
      await widget.repository.rejectRequest(widget.requestId, reason.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request rejected and explanation recorded.'),
          backgroundColor: AppColors.error,
        ),
      );
      await _loadRequest();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reject request: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isActionProcessing = false);
    }
  }

  Future<void> _updateStatus() async {
    if (_request == null) return;

    final result = await showDialog<RequestStatusUpdateResult>(
      context: context,
      builder: (_) => UpdateStatusDialog(
        currentStatus: _request!.status,
        existingNotes: _request!.officerNotes,
      ),
    );

    if (result == null || !mounted) return;

    setState(() => _isActionProcessing = true);
    try {
      await widget.repository.updateRequestStatus(
        widget.requestId,
        result.status,
        officerNotes: result.officerNotes,
        guidanceSummary: result.guidanceSummary,
        recommendations: result.recommendations,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Advisory status updated to "${result.status}"!'),
          backgroundColor: AppColors.primaryGreenDark,
        ),
      );
      await _loadRequest();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isActionProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadRequest,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const AgroLoadingView(message: 'Loading request information...');
    }

    if (_errorMessage != null || _request == null) {
      return AgroEmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Unable to Load Request',
        description: _errorMessage ?? 'Request not found.',
        actionLabel: 'Retry',
        onAction: _loadRequest,
      );
    }

    final req = _request!;

    return RefreshIndicator(
      onRefresh: _loadRequest,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: ResponsiveContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildFarmerBanner(req),
              const SizedBox(height: 14),
              _buildIssueCard(req),
              const SizedBox(height: 14),
              _buildAttachmentsSection(req),
              const SizedBox(height: 14),
              if (req.officerNotes != null || req.rejectionReason != null)
                _buildNotesCard(req),
              const SizedBox(height: 20),
              _buildActionButtons(req),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFarmerBanner(AssistanceRequestModel req) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.softMint,
              child: Icon(
                Icons.person_rounded,
                color: AppColors.primaryGreen,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    req.farmerName ?? 'Farmer #${req.farmerId}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (req.farmerPhone != null &&
                      req.farmerPhone!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Phone: ${req.farmerPhone}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FarmerInspectionScreen(
                      farmerUserId: req.farmerId,
                      repository: widget.repository,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.agriculture_rounded, size: 16),
              label: const Text('View Farms'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIssueCard(AssistanceRequestModel req) {
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    req.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _statusBadge(req.status),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _chip(
                  Icons.category_outlined,
                  req.category,
                  AppColors.primaryGreenDark,
                ),
                _priorityBadge(req.priority),
                if (req.farmName != null && req.farmName!.isNotEmpty)
                  _chip(
                    Icons.landscape_outlined,
                    req.farmName!,
                    AppColors.warning,
                  ),
                if (req.cropName != null && req.cropName!.isNotEmpty)
                  _chip(
                    Icons.grass_rounded,
                    req.cropName!,
                    const Color(0xFF2E7D32),
                  ),
              ],
            ),
            const Divider(height: 24, color: AppColors.border),
            const Text(
              'Problem Description & Field Observations:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              req.description,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            if (req.createdAt != null)
              Text(
                'Submitted on: ${req.createdAt!.toLocal().toString().split(".")[0]}',
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

  Widget _buildAttachmentsSection(AssistanceRequestModel req) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.attach_file_rounded,
                  size: 20,
                  color: AppColors.primaryGreen,
                ),
                const SizedBox(width: 8),
                Text(
                  'Attachments (${req.attachments.length})',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (req.attachments.isEmpty)
              const Text(
                'No crop disease photos or documents attached with this request.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              )
            else
              ...req.attachments.map((att) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.softMint,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        att.fileType == 'image'
                            ? Icons.image_rounded
                            : Icons.picture_as_pdf_rounded,
                        color: AppColors.primaryGreen,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              att.fileName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            if (att.description != null &&
                                att.description!.isNotEmpty)
                              Text(
                                att.description!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        '${(att.fileSizeBytes / 1024).toStringAsFixed(1)} KB',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard(AssistanceRequestModel req) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (req.rejectionReason != null) ...[
              const Row(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.error,
                    size: 18,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Rejection Reason',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(req.rejectionReason!, style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 12),
            ],
            if (req.officerNotes != null) ...[
              const Row(
                children: [
                  Icon(
                    Icons.notes_rounded,
                    color: AppColors.primaryGreen,
                    size: 18,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Officer Guidance & Notes',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreenDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(req.officerNotes!, style: const TextStyle(fontSize: 13)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(AssistanceRequestModel req) {
    if (_isActionProcessing) {
      return const Center(child: CircularProgressIndicator());
    }

    if (req.isPending) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _acceptRequest,
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text('Accept Request'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _rejectRequest,
              icon: const Icon(Icons.cancel_outlined, color: AppColors.error),
              label: const Text(
                'Reject',
                style: TextStyle(color: AppColors.error),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      );
    }

    if (req.isAccepted || req.isInProgress || req.isResolved) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ConsultationChatScreen(
                    requestId: req.id,
                    requestTitle: req.title,
                    farmerName: req.farmerName,
                    repository: widget.repository,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.chat_bubble_rounded),
            label: const Text('Open Consultation Chat'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          if (!req.isResolved) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _updateStatus,
              icon: const Icon(Icons.published_with_changes_rounded),
              label: const Text('Update Status & Recommendations'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ],
      );
    }

    return const SizedBox.shrink();
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  Widget _priorityBadge(String priority) {
    final p = priority.toLowerCase();
    Color color = AppColors.textSecondary;
    if (p == 'urgent' || p == 'high') color = AppColors.error;
    if (p == 'medium') color = AppColors.warning;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        'Priority: ${priority.toUpperCase()}',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
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
