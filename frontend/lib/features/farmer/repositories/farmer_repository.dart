import 'package:agrochat_app/core/constants/api_endpoints.dart';
import 'package:agrochat_app/core/network/api_client.dart';
import 'package:agrochat_app/features/auth/models/auth_user.dart';
import 'package:agrochat_app/features/farmer/models/farm_model.dart';
import 'package:agrochat_app/features/farmer/models/farmer_profile_model.dart';
import 'package:agrochat_app/features/officer/models/assistance_request_model.dart';
import 'package:agrochat_app/features/officer/models/chat_message_model.dart';
import 'package:agrochat_app/features/officer/models/officer_profile_model.dart';

/// Repository handling all Farmer module network requests to FastAPI backend.
class FarmerRepository implements ChatMessageProvider {
  FarmerRepository({ApiClient? apiClient, required this.token})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;
  final String token;

  // ==================== PROFILE & PREFERENCES ====================

  Future<FarmerProfileModel> getFarmerProfile() async {
    final response = await _apiClient.get(
      ApiEndpoints.farmerProfile,
      token: token,
    );
    if (response is Map<String, dynamic>) {
      return FarmerProfileModel.fromJson(response);
    }
    throw const FormatException('Unexpected response from farmer profile API');
  }

  Future<FarmerProfileModel> updateFarmerProfile(
    FarmerProfileModel profile,
  ) async {
    final response = await _apiClient.put(
      ApiEndpoints.farmerProfile,
      body: profile.toJson(),
      token: token,
    );
    if (response is Map<String, dynamic>) {
      return FarmerProfileModel.fromJson(response);
    }
    throw const FormatException('Unexpected response updating farmer profile');
  }

  Future<AuthUser> updatePreferredLanguage(String preferredLanguage) async {
    final response = await _apiClient.patch(
      ApiEndpoints.farmerPreferredLanguage,
      body: {'preferred_language': preferredLanguage},
      token: token,
    );
    if (response is Map<String, dynamic>) {
      return AuthUser.fromJson(response);
    }
    throw const FormatException('Unexpected response updating language');
  }

  // ==================== FARMS ====================

  Future<List<FarmModel>> listFarms() async {
    final response = await _apiClient.get(ApiEndpoints.farms, token: token);
    if (response is List<dynamic>) {
      return response
          .map((item) => FarmModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<FarmModel> createFarm(FarmModel farm) async {
    final response = await _apiClient.post(
      ApiEndpoints.farms,
      body: farm.toJson(),
      token: token,
    );
    if (response is Map<String, dynamic>) {
      return FarmModel.fromJson(response);
    }
    throw const FormatException('Unexpected response creating farm');
  }

  Future<FarmModel> updateFarm(int farmId, FarmModel farm) async {
    final response = await _apiClient.put(
      ApiEndpoints.farmDetails(farmId),
      body: farm.toJson(),
      token: token,
    );
    if (response is Map<String, dynamic>) {
      return FarmModel.fromJson(response);
    }
    throw const FormatException('Unexpected response updating farm');
  }

  Future<void> deleteFarm(int farmId) async {
    await _apiClient.delete(ApiEndpoints.farmDetails(farmId), token: token);
  }

  // ==================== CROPS ====================

  Future<CropModel> addCrop(int farmId, CropModel crop) async {
    final response = await _apiClient.post(
      ApiEndpoints.farmCrops(farmId),
      body: crop.toJson(),
      token: token,
    );
    if (response is Map<String, dynamic>) {
      return CropModel.fromJson(response);
    }
    throw const FormatException('Unexpected response adding crop');
  }

  Future<CropModel> updateCrop(int farmId, int cropId, CropModel crop) async {
    final response = await _apiClient.put(
      ApiEndpoints.farmCropDetail(farmId, cropId),
      body: crop.toJson(),
      token: token,
    );
    if (response is Map<String, dynamic>) {
      return CropModel.fromJson(response);
    }
    throw const FormatException('Unexpected response updating crop');
  }

  Future<void> deleteCrop(int farmId, int cropId) async {
    await _apiClient.delete(
      ApiEndpoints.farmCropDetail(farmId, cropId),
      token: token,
    );
  }

  // ==================== LIVESTOCK ====================

  Future<LivestockModel> addLivestock(
    int farmId,
    LivestockModel livestock,
  ) async {
    final response = await _apiClient.post(
      ApiEndpoints.farmLivestock(farmId),
      body: livestock.toJson(),
      token: token,
    );
    if (response is Map<String, dynamic>) {
      return LivestockModel.fromJson(response);
    }
    throw const FormatException('Unexpected response adding livestock');
  }

  Future<void> deleteLivestock(int farmId, int livestockId) async {
    await _apiClient.delete(
      ApiEndpoints.farmLivestockDetail(farmId, livestockId),
      token: token,
    );
  }

  // ==================== SUMMARY COUNTS FOR DASHBOARD ====================

  Future<int> getActiveRequestsCount() async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.myRequests,
        token: token,
      );
      if (response is List<dynamic>) {
        return response.length;
      }
    } catch (_) {
      // Non-blocking for dashboard stats
    }
    return 0;
  }

  Future<int> getUnreadNotificationsCount() async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.notifications,
        token: token,
      );
      if (response is List<dynamic>) {
        return response
            .where((n) => (n as Map<String, dynamic>)['is_read'] == false)
            .length;
      }
    } catch (_) {
      // Non-blocking
    }
    return 0;
  }

  // ==================== ASSISTANCE REQUESTS ====================

  Future<List<AssistanceRequestModel>> listMyRequests() async {
    final response = await _apiClient.get(
      ApiEndpoints.myRequests,
      token: token,
    );
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

  Future<AssistanceRequestModel> createRequest(
    Map<String, dynamic> payload,
  ) async {
    final response = await _apiClient.post(
      ApiEndpoints.requests,
      body: payload,
      token: token,
    );
    if (response is Map<String, dynamic>) {
      return AssistanceRequestModel.fromJson(response);
    }
    throw const FormatException(
      'Unexpected response creating assistance request',
    );
  }

  Future<AssistanceRequestModel> cancelRequest(int requestId) async {
    final response = await _apiClient.post(
      ApiEndpoints.cancelRequest(requestId),
      token: token,
    );
    if (response is Map<String, dynamic>) {
      return AssistanceRequestModel.fromJson(response);
    }
    throw const FormatException('Unexpected response cancelling request');
  }

  Future<AssistanceRequestModel> getRequestDetails(int requestId) async {
    final response = await _apiClient.get(
      ApiEndpoints.requestDetails(requestId),
      token: token,
    );
    if (response is Map<String, dynamic>) {
      return AssistanceRequestModel.fromJson(response);
    }
    throw const FormatException('Unexpected response fetching request details');
  }

  Future<List<OfficerProfileModel>> listAvailableOfficers() async {
    final response = await _apiClient.get(
      '${ApiEndpoints.officersDiscovery}?available_only=true',
      token: token,
    );
    if (response is List<dynamic>) {
      return response
          .map(
            (item) =>
                OfficerProfileModel.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    }
    return [];
  }

  // ==================== CONSULTATION CHAT ====================

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
  Future<ChatMessageModel> sendTextMessage(int requestId, String text) async {
    final response = await _apiClient.post(
      ApiEndpoints.requestMessages(requestId),
      body: {'message_text': text, 'message_type': 'text'},
      token: token,
    );
    if (response is Map<String, dynamic>) {
      return ChatMessageModel.fromJson(response);
    }
    throw const FormatException('Unexpected response sending message');
  }
}
