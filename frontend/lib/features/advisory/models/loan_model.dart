/// Model representing a Farmer's Agricultural Loan Enquiry and Officer Guidance.
class LoanEnquiryModel {
  const LoanEnquiryModel({
    required this.id,
    required this.farmerId,
    this.schemeId,
    required this.loanType,
    this.preferredBank,
    required this.requestedAmountInr,
    required this.purpose,
    this.annualIncomeInr,
    this.landHoldingAcres,
    required this.status,
    this.officerGuidance,
    this.createdAt,
  });

  final int id;
  final int farmerId;
  final int? schemeId;
  final String loanType;
  final String? preferredBank;
  final double requestedAmountInr;
  final String purpose;
  final double? annualIncomeInr;
  final double? landHoldingAcres;
  final String status;
  final String? officerGuidance;
  final DateTime? createdAt;

  factory LoanEnquiryModel.fromJson(Map<String, dynamic> json) {
    return LoanEnquiryModel(
      id: json['id'] as int,
      farmerId: json['farmer_id'] as int,
      schemeId: json['scheme_id'] as int?,
      loanType: json['loan_type'] as String? ?? 'Crop Loan',
      preferredBank: json['preferred_bank'] as String?,
      requestedAmountInr:
          (json['requested_amount_inr'] as num?)?.toDouble() ?? 0.0,
      purpose: json['purpose'] as String? ?? '',
      annualIncomeInr: (json['annual_income_inr'] as num?)?.toDouble(),
      landHoldingAcres: (json['land_holding_acres'] as num?)?.toDouble(),
      status: json['status'] as String? ?? 'pending',
      officerGuidance: json['officer_guidance'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'loan_type': loanType,
    if (schemeId != null) 'scheme_id': schemeId,
    if (preferredBank != null && preferredBank!.isNotEmpty)
      'preferred_bank': preferredBank,
    'requested_amount_inr': requestedAmountInr,
    'purpose': purpose,
    if (annualIncomeInr != null) 'annual_income_inr': annualIncomeInr,
    if (landHoldingAcres != null) 'land_holding_acres': landHoldingAcres,
  };
}
