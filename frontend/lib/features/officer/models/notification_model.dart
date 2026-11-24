// Models representing in-app notifications and notification lists for Officers and Farmers.

class NotificationItemModel {
  const NotificationItemModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    this.notificationType = 'system',
    this.relatedRequestId,
    this.isRead = false,
    this.createdAt,
  });

  final int id;
  final int userId;
  final String title;
  final String message;
  final String notificationType;
  final int? relatedRequestId;
  final bool isRead;
  final DateTime? createdAt;

  factory NotificationItemModel.fromJson(Map<String, dynamic> json) {
    return NotificationItemModel(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      title: json['title'] as String? ?? 'Notification',
      message: json['message'] as String? ?? '',
      notificationType: json['notification_type'] as String? ?? 'system',
      relatedRequestId: json['related_request_id'] as int?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'notification_type': notificationType,
      'related_request_id': relatedRequestId,
      'is_read': isRead,
    };
  }

  NotificationItemModel copyWith({bool? isRead}) {
    return NotificationItemModel(
      id: id,
      userId: userId,
      title: title,
      message: message,
      notificationType: notificationType,
      relatedRequestId: relatedRequestId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}

class NotificationListModel {
  const NotificationListModel({required this.unreadCount, required this.items});

  final int unreadCount;
  final List<NotificationItemModel> items;

  factory NotificationListModel.fromJson(Map<String, dynamic> json) {
    return NotificationListModel(
      unreadCount: json['unread_count'] as int? ?? 0,
      items:
          (json['items'] as List<dynamic>?)
              ?.map(
                (item) => NotificationItemModel.fromJson(
                  item as Map<String, dynamic>,
                ),
              )
              .toList() ??
          const [],
    );
  }
}
