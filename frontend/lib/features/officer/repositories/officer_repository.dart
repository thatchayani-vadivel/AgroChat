import 'package:agrochat_app/core/constants/api_endpoints.dart';
import 'package:agrochat_app/core/network/api_client.dart';
import 'package:agrochat_app/features/officer/models/assistance_request_model.dart';
import 'package:agrochat_app/features/officer/models/chat_message_model.dart';
import 'package:agrochat_app/features/officer/models/farmer_details_model.dart';
import 'package:agrochat_app/features/officer/models/notification_model.dart';
import 'package:agrochat_app/features/officer/models/officer_profile_model.dart';

/// Aggregated counts of assistance requests for Officer Dashboard display.
class OfficerRequestStats {
  const OfficerRequestStats({
    required this.total,
    required this.pending,
    required this.accepted,
    required this.inProgress,
    required this.resolved,
    required this.rejected,
  });

  final int total;
  final int pending;
  final int accepted;
  final int inProgress;
  final int resolved;
  final int rejected;

  factory OfficerRequestStats.fromRequests(
    List<AssistanceRequestModel> requests,
  ) {
    int pending = 0;
    int accepted = 0;
    int inProgress = 0;
    int resolved = 0;
    int rejected = 0;

    for (final r in requests) {
      final s = r.status.toLowerCase();
      if (s == 'pending') {
        pending++;
      } else if (s == 'accepted') {
        accepted++;
      } else if (s == 'in_progress') {
        inProgress++;
      } else if (s == 'resolved') {
        resolved++;
      } else if (s == 'rejected') {
        rejected++;
      }
    }

    return OfficerRequestStats(
      total: requests.length,
      pending: pending,
      accepted: accepted,
      inProgress: inProgress,
      resolved: resolved,
      rejected: rejected,
    );
  }
}

/// Repository handling all Agricultural Officer network interactions with FastAPI.
class OfficerRepository implements ChatMessageProvider {
  OfficerRepository({ApiClient? apiClient, required this.token})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;
  final String token;

  // ==================== OFFICER PROFILE ====================

  Future<OfficerProfileModel> getProfile() async {
    final response = await _apiClient.get(
      ApiEndpoints.officerProfile,
      token: token,
    );
    if (response is Map<String, dynamic>) {
      return OfficerProfileModel.fromJson(response);
    }
    throw const FormatException('Unexpected response from officer profile API');
  }

  Future<OfficerProfileModel> updateProfile(OfficerProfileModel profile) async {
    final response = await _apiClient.put(
      ApiEndpoints.officerProfile,
      body: profile.toJson(),
      token: token,
    );
    if (response is Map<String, dynamic>) {
      return OfficerProfileModel.fromJson(response);
    }
    throw const FormatException('Unexpected response updating officer profile');
  }

  Future<OfficerProfileModel> updateAvailability(
    bool isAvailable, {
    String? availabilityHours,
  }) async {
    final response = await _apiClient.patch(
      ApiEndpoints.officerAvailability,
      body: {
        'is_available': isAvailable,
        if (availabilityHours != null && availabilityHours.isNotEmpty)
          'availability_hours': availabilityHours,
      },
      token: token,
    );
    if (response is Map<String, dynamic>) {
      return OfficerProfileModel.fromJson(response);
    }
    throw const FormatException('Unexpected response updating availability');
  }

  // ==================== ASSISTANCE REQUESTS ====================

  Future<List<AssistanceRequestModel>> listRequests({
    String scope = 'all',
    String? status,
  }) async {
    final queryParams = <String, String>{'scope': scope};
    if (status != null && status.isNotEmpty && status != 'all') {
      queryParams['status'] = status;
    }

    final queryString = Uri(queryParameters: queryParams).query;
    final endpoint = '${ApiEndpoints.officerRequests}?$queryString';

    final response = await _apiClient.get(endpoint, token: token);
    if (response is List<dynamic>) {
      return response
          .map(
            (item) =>
                AssistanceRequestModel.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    }
    return [];
  }

  Future<AssistanceRequestModel> getRequestDetails(int requestId) async {
    final response = await _apiClient.get(
      ApiEndpoints.requestDetails(requestId),
      token: token,
    );
    if (response is Map<String, dynamic>) {
      final request = AssistanceRequestModel.fromJson(response);
      // Fetch attachments if available
      try {
        final attachments = await getRequestAttachments(requestId);
        return request.copyWith(attachments: attachments);
      } catch (_) {
        return request;
      }
    }
    throw const FormatException('Unexpected response fetching request details');
  }

  Future<List<RequestAttachmentModel>> getRequestAttachments(
    int requestId,
  ) async {
    final response = await _apiClient.get(
      ApiEndpoints.requestAttachments(requestId),
      token: token,
    );
    if (response is List<dynamic>) {
      return response
          .map(
            (item) =>
                RequestAttachmentModel.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    }
    return [];
  }

  Future<AssistanceRequestModel> acceptRequest(
    int requestId, {
    String? officerNotes,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.acceptRequest(requestId),
      body: {
        if (officerNotes != null && officerNotes.isNotEmpty)
          'officer_notes': officerNotes,
      },
      token: token,
    );
    if (response is Map<String, dynamic>) {
      return AssistanceRequestModel.fromJson(response);
    }
    throw const FormatException('Unexpected response accepting request');
  }

  Future<AssistanceRequestModel> rejectRequest(
    int requestId,
    String rejectionReason,
  ) async {
    final response = await _apiClient.post(
      ApiEndpoints.rejectRequest(requestId),
      body: {'rejection_reason': rejectionReason},
      token: token,
    );
    if (response is Map<String, dynamic>) {
      return AssistanceRequestModel.fromJson(response);
    }
    throw const FormatException('Unexpected response rejecting request');
  }

  Future<AssistanceRequestModel> updateRequestStatus(
    int requestId,
    String newStatus, {
    String? officerNotes,
    String? guidanceSummary,
    String? recommendations,
  }) async {
    final response = await _apiClient.patch(
      ApiEndpoints.updateRequestStatus(requestId),
      body: {
        'status': newStatus,
        if (officerNotes != null && officerNotes.isNotEmpty)
          'officer_notes': officerNotes,
        if (guidanceSummary != null && guidanceSummary.isNotEmpty)
          'guidance_summary': guidanceSummary,
        if (recommendations != null && recommendations.isNotEmpty)
          'recommendations': recommendations,
      },
      token: token,
    );
    if (response is Map<String, dynamic>) {
      return AssistanceRequestModel.fromJson(response);
    }
    throw const FormatException('Unexpected response updating request status');
  }

  // ==================== FARMER INSPECTION ====================

  Future<FarmerInspectionModel> getFarmerDetails(int farmerUserId) async {
    final response = await _apiClient.get(
      ApiEndpoints.farmerDetails(farmerUserId),
      token: token,
    );
    if (response is Map<String, dynamic>) {
      return FarmerInspectionModel.fromJson(response);
    }
    throw const FormatException('Unexpected response fetching farmer details');
  }

  // ==================== CHAT & MESSAGING ====================

  @override
  Future<List<ChatMessageModel>> listMessages(int requestId) async {
    final response = await _apiClient.get(
      ApiEndpoints.requestMessages(requestId),
      token: token,
    );
    if (response is List<dynamic>) {
      return response
          .map(
            (item) => ChatMessageModel.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    }
    return [];
  }

  @override
  Future<ChatMessageModel> sendTextMessage(
    int requestId,
    String content,
  ) async {
    final response = await _apiClient.post(
      ApiEndpoints.requestMessages(requestId),
      body: {'content': content.trim()},
      token: token,
    );
    if (response is Map<String, dynamic>) {
      return ChatMessageModel.fromJson(response);
    }
    throw const FormatException('Unexpected response sending message');
  }

  // ==================== NOTIFICATIONS ====================

  Future<NotificationListModel> listNotifications({
    bool unreadOnly = false,
  }) async {
    final endpoint = '${ApiEndpoints.notifications}?unread_only=$unreadOnly';
    final response = await _apiClient.get(endpoint, token: token);
    if (response is Map<String, dynamic>) {
      return NotificationListModel.fromJson(response);
    }
    return const NotificationListModel(unreadCount: 0, items: []);
  }

  Future<void> markNotificationRead(int notificationId) async {
    await _apiClient.patch(
      ApiEndpoints.markNotificationRead(notificationId),
      token: token,
    );
  }

  Future<void> markAllNotificationsRead() async {
    await _apiClient.patch(ApiEndpoints.markAllNotificationsRead, token: token);
  }
}
