import 'package:flutter/material.dart';

import 'package:agrochat_app/core/theme/app_colors.dart';
import 'package:agrochat_app/features/farmer/presentation/screens/farmer_request_detail_screen.dart';
import 'package:agrochat_app/features/farmer/repositories/farmer_repository.dart';
import 'package:agrochat_app/features/officer/models/notification_model.dart';
import 'package:agrochat_app/features/officer/repositories/officer_repository.dart';
import 'package:agrochat_app/shared/widgets/status_feedback.dart';

/// Screen displaying in-app notifications for authenticated Farmers.
class FarmerNotificationsScreen extends StatefulWidget {
  const FarmerNotificationsScreen({
    super.key,
    required this.token,
    required this.farmerRepository,
  });

  final String token;
  final FarmerRepository farmerRepository;

  @override
  State<FarmerNotificationsScreen> createState() =>
      _FarmerNotificationsScreenState();
}

class _FarmerNotificationsScreenState extends State<FarmerNotificationsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<NotificationItemModel> _notifications = [];
  int _unreadCount = 0;
  bool _unreadOnly = false;
  late OfficerRepository _notifRepo;

  @override
  void initState() {
    super.initState();
    _notifRepo = OfficerRepository(token: widget.token);
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _notifRepo.listNotifications(unreadOnly: _unreadOnly);
      if (mounted) {
        setState(() {
          _notifications = list.items;
          _unreadCount = list.unreadCount;
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

  Future<void> _markAllRead() async {
    try {
      await _notifRepo.markAllNotificationsRead();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read.'),
          backgroundColor: AppColors.primaryGreenDark,
        ),
      );
      _loadNotifications();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to mark all as read: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _onNotificationTap(NotificationItemModel item) async {
    if (!item.isRead) {
      try {
        await _notifRepo.markNotificationRead(item.id);
      } catch (_) {}
    }

    if (item.relatedRequestId != null && mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FarmerRequestDetailScreen(
            requestId: item.relatedRequestId!,
            repository: widget.farmerRepository,
          ),
        ),
      );
      _loadNotifications();
    } else {
      _loadNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _unreadCount > 0 ? 'Notifications ($_unreadCount)' : 'Notifications',
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text(
                'Mark All Read',
                style: TextStyle(color: AppColors.softMint, fontSize: 12),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.surfaceWhite,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Show Unread Only',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                Switch(
                  value: _unreadOnly,
                  activeThumbColor: AppColors.primaryGreen,
                  onChanged: (val) {
                    setState(() => _unreadOnly = val);
                    _loadNotifications();
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const AgroLoadingView(message: 'Loading notifications...')
                : _errorMessage != null && _notifications.isEmpty
                ? AgroEmptyState(
                    icon: Icons.error_outline_rounded,
                    title: 'Unable to Load Notifications',
                    description: _errorMessage!,
                    actionLabel: 'Retry',
                    onAction: _loadNotifications,
                  )
                : _notifications.isEmpty
                ? AgroEmptyState(
                    icon: Icons.notifications_none_rounded,
                    title: 'No Notifications',
                    description: _unreadOnly ? 'No unread alerts found.' : 'You will receive notifications when an Agricultural Officer reviews your request or sends guidance.',
                  )
                : RefreshIndicator(
                    onRefresh: _loadNotifications,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _notifications.length,
                      separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final n = _notifications[index];
                        return Card(
                          elevation: 0,
                          color: n.isRead
                              ? AppColors.surfaceWhite
                              : AppColors.softMint.withValues(alpha: 0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: n.isRead
                                  ? AppColors.border
                                  : AppColors.primaryGreen.withValues(
                                      alpha: 0.5,
                                    ),
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: n.isRead
                                  ? AppColors.background
                                  : AppColors.primaryGreen,
                              child: Icon(
                                Icons.notifications_active_rounded,
                                size: 20,
                                color: n.isRead
                                    ? AppColors.textSecondary
                                    : AppColors.surfaceWhite,
                              ),
                            ),
                            title: Text(
                              n.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: n.isRead
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  n.message,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                if (n.createdAt != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    '${n.createdAt!.day}/${n.createdAt!.month}/${n.createdAt!.year}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            trailing: n.isRead
                                ? null
                                : Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primaryGreen,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                            onTap: () => _onNotificationTap(n),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
