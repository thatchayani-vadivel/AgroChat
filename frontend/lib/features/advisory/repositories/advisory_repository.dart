import 'package:agrochat_app/core/constants/api_endpoints.dart';
import 'package:agrochat_app/core/network/api_client.dart';
import 'package:agrochat_app/features/advisory/models/advisory_model.dart';
import 'package:agrochat_app/features/advisory/models/loan_model.dart';
import 'package:agrochat_app/features/advisory/models/subsidy_model.dart';

/// Repository for Government Schemes, Loan Enquiries, Subsidy Enquiries, and Agricultural Services.
class AdvisoryRepository {
  AdvisoryRepository({ApiClient? apiClient, required this.token})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;
  final String token;

  // ==================== SCHEMES & ADVISORIES ====================

  Future<List<SchemeModel>> listSchemes({
    String? category,
    String? search,
  }) async {
    final queryParams = <String, String>{};
    if (category != null && category.isNotEmpty && category != 'all') {
      queryParams['category'] = category;
    }
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    final query = queryParams.isNotEmpty
        ? '?${queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}'
        : '';

    final response = await _apiClient.get(
      '${ApiEndpoints.schemes}$query',
      token: token,
    );
    if (response is List<dynamic>) {
      return response
          .map((item) => SchemeModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<SchemeModel> getSchemeDetails(int id) async {
    final response = await _apiClient.get(
      ApiEndpoints.schemeDetails(id),
      token: token,
    );
    if (response is Map<String, dynamic>) {
      return SchemeModel.fromJson(response);
    }
    throw const FormatException('Unexpected response from scheme details');
  }

  Future<List<AgriculturalServiceModel>> listServices({
    String? serviceType,
    String? district,
  }) async {
    final queryParams = <String, String>{};
    if (serviceType != null && serviceType.isNotEmpty) {
      queryParams['service_type'] = serviceType;
    }
    if (district != null && district.isNotEmpty) {
      queryParams['district'] = district;
    }

    final query = queryParams.isNotEmpty
        ? '?${queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}'
        : '';

    final response = await _apiClient.get(
      '${ApiEndpoints.agriculturalServices}$query',
      token: token,
    );
    if (response is List<dynamic>) {
      return response
          .map(
            (item) =>
                AgriculturalServiceModel.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    }
    return [];
  }

  // ==================== LOAN ENQUIRIES ====================

  Future<List<LoanEnquiryModel>> listMyLoanEnquiries() async {
    final response = await _apiClient.get(
      ApiEndpoints.myLoanEnquiries,
      token: token,
    );
    if (response is List<dynamic>) {
      return response
          .map(
            (item) => LoanEnquiryModel.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    }
    return [];
  }

  Future<LoanEnquiryModel> submitLoanEnquiry(
    Map<String, dynamic> payload,
  ) async {
    final response = await _apiClient.post(
      ApiEndpoints.loanEnquiries,
      body: payload,
      token: token,
    );
    if (response is Map<String, dynamic>) {
      return LoanEnquiryModel.fromJson(response);
    }
    throw const FormatException('Unexpected response submitting loan enquiry');
  }

  // ==================== SUBSIDY ENQUIRIES ====================

  Future<List<SubsidyEnquiryModel>> listMySubsidyEnquiries() async {
    final response = await _apiClient.get(
      ApiEndpoints.mySubsidyEnquiries,
      token: token,
    );
    if (response is List<dynamic>) {
      return response
          .map(
            (item) =>
                SubsidyEnquiryModel.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    }
    return [];
  }

  Future<SubsidyEnquiryModel> submitSubsidyEnquiry(
    Map<String, dynamic> payload,
  ) async {
    final response = await _apiClient.post(
      ApiEndpoints.subsidyEnquiries,
      body: payload,
      token: token,
    );
    if (response is Map<String, dynamic>) {
      return SubsidyEnquiryModel.fromJson(response);
    }
    throw const FormatException(
      'Unexpected response submitting subsidy enquiry',
    );
  }
}
