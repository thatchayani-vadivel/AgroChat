import 'package:flutter/material.dart';

import 'package:agrochat_app/core/theme/app_colors.dart';
import 'package:agrochat_app/features/officer/models/notification_model.dart';
import 'package:agrochat_app/features/officer/presentation/screens/request_detail_screen.dart';
import 'package:agrochat_app/features/officer/repositories/officer_repository.dart';
import 'package:agrochat_app/shared/widgets/responsive_container.dart';
import 'package:agrochat_app/shared/widgets/status_feedback.dart';

/// Screen displaying officer in-app notifications with read/unread markers and quick actions.
class OfficerNotificationsView extends StatefulWidget {
  const OfficerNotificationsView({super.key, required this.repository});

  final OfficerRepository repository;

  @override
  State<OfficerNotificationsView> createState() =>
      OfficerNotificationsViewState();
}

class OfficerNotificationsViewState extends State<OfficerNotificationsView> {
  bool _isLoading = true;
  String? _errorMessage;
  List<NotificationItemModel> _notifications = [];
  int _unreadCount = 0;
  bool _unreadOnly = false;

  @override
  void initState() {
    super.initState();
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await widget.repository.listNotifications(
        unreadOnly: _unreadOnly,
      );
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
      await widget.repository.markAllNotificationsRead();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read.'),
          backgroundColor: AppColors.primaryGreenDark,
        ),
      );
      await loadNotifications();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _onNotificationTap(NotificationItemModel item) async {
    if (!item.isRead) {
      try {
        await widget.repository.markNotificationRead(item.id);
        setState(() {
          final idx = _notifications.indexWhere((n) => n.id == item.id);
          if (idx != -1) {
            _notifications[idx] = item.copyWith(isRead: true);
            if (_unreadCount > 0) _unreadCount--;
          }
        });
      } catch (_) {}
    }

    if (item.relatedRequestId != null && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RequestDetailScreen(
            requestId: item.relatedRequestId!,
            repository: widget.repository,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(onRefresh: loadNotifications, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const AgroLoadingView(message: 'Loading notifications...');
    }

    if (_errorMessage != null && _notifications.isEmpty) {
      return AgroEmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Unable to Load Notifications',
        description: _errorMessage!,
        actionLabel: 'Retry',
        onAction: loadNotifications,
      );
    }

    return ResponsiveContainer(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    FilterChip(
                      selected: !_unreadOnly,
                      label: const Text('All'),
                      onSelected: (_) {
                        setState(() => _unreadOnly = false);
                        loadNotifications();
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      selected: _unreadOnly,
                      label: Text('Unread ($_unreadCount)'),
                      selectedColor: AppColors.softMint,
                      onSelected: (_) {
                        setState(() => _unreadOnly = true);
                        loadNotifications();
                      },
                    ),
                  ],
                ),
                if (_unreadCount > 0)
                  TextButton.icon(
                    onPressed: _markAllRead,
                    icon: const Icon(Icons.done_all_rounded, size: 16),
                    label: const Text('Mark All Read'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _notifications.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 24,
                      top: 4,
                    ),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      return _buildNotificationCard(_notifications[index]);
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
              Icons.notifications_none_rounded,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              _unreadOnly ? 'No Unread Notifications' : 'No Notifications Yet',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _unreadOnly ? 'All notifications have been reviewed.' : 'You will receive updates here when farmers submit new requests or send consultation messages.',
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

  Widget _buildNotificationCard(NotificationItemModel item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: item.isRead ? AppColors.surfaceWhite : const Color(0xFFF0FDF4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: item.isRead
              ? AppColors.border
              : AppColors.primaryGreen.withValues(alpha: 0.4),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: item.isRead
              ? AppColors.softMint
              : const Color(0xFFDCFCE7),
          child: Icon(
            item.relatedRequestId != null
                ? Icons.assignment_outlined
                : Icons.notifications_active_outlined,
            color: AppColors.primaryGreen,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item.title,
                style: TextStyle(
                  fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            if (!item.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primaryGreen,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              item.message,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.createdAt != null
                  ? item.createdAt!
                        .toLocal()
                        .toString()
                        .split(".")[0]
                        .substring(0, 16)
                  : '',
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        onTap: () => _onNotificationTap(item),
      ),
    );
  }
}
