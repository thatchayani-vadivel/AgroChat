/// Model representing a Farmer's Subsidy Enquiry and Officer Guidance.
class SubsidyEnquiryModel {
  const SubsidyEnquiryModel({
    required this.id,
    required this.farmerId,
    this.schemeId,
    this.farmId,
    required this.subsidyTitle,
    required this.enquiryDetails,
    required this.status,
    this.officerGuidance,
    this.createdAt,
  });

  final int id;
  final int farmerId;
  final int? schemeId;
  final int? farmId;
  final String subsidyTitle;
  final String enquiryDetails;
  final String status;
  final String? officerGuidance;
  final DateTime? createdAt;

  factory SubsidyEnquiryModel.fromJson(Map<String, dynamic> json) {
    return SubsidyEnquiryModel(
      id: json['id'] as int,
      farmerId: json['farmer_id'] as int,
      schemeId: json['scheme_id'] as int?,
      farmId: json['farm_id'] as int?,
      subsidyTitle: json['subsidy_title'] as String? ?? '',
      enquiryDetails: json['enquiry_details'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      officerGuidance: json['officer_guidance'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'subsidy_title': subsidyTitle,
    if (schemeId != null) 'scheme_id': schemeId,
    if (farmId != null) 'farm_id': farmId,
    'enquiry_details': enquiryDetails,
  };
}
