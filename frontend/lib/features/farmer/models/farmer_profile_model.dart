/// Model representing the Farmer's personal and agricultural profile details.
class FarmerProfileModel {
  const FarmerProfileModel({
    required this.id,
    required this.userId,
    this.village,
    this.talukOrBlock,
    this.district,
    this.state,
    this.pincode,
    this.totalLandholdingAcres,
    this.identityProofType,
    this.identityProofNumber,
    this.preferredCommunicationMode = 'In-App Message',
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int userId;
  final String? village;
  final String? talukOrBlock;
  final String? district;
  final String? state;
  final String? pincode;
  final double? totalLandholdingAcres;
  final String? identityProofType;
  final String? identityProofNumber;
  final String preferredCommunicationMode;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory FarmerProfileModel.fromJson(Map<String, dynamic> json) {
    return FarmerProfileModel(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      village: json['village'] as String?,
      talukOrBlock: json['taluk_or_block'] as String?,
      district: json['district'] as String?,
      state: json['state'] as String?,
      pincode: json['pincode'] as String?,
      totalLandholdingAcres: (json['total_landholding_acres'] as num?)
          ?.toDouble(),
      identityProofType: json['identity_proof_type'] as String?,
      identityProofNumber: json['identity_proof_number'] as String?,
      preferredCommunicationMode:
          json['preferred_communication_mode'] as String? ?? 'In-App Message',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (village != null) 'village': village,
      if (talukOrBlock != null) 'taluk_or_block': talukOrBlock,
      if (district != null) 'district': district,
      if (state != null) 'state': state,
      if (pincode != null) 'pincode': pincode,
      if (totalLandholdingAcres != null)
        'total_landholding_acres': totalLandholdingAcres,
      if (identityProofType != null) 'identity_proof_type': identityProofType,
      if (identityProofNumber != null)
        'identity_proof_number': identityProofNumber,
      'preferred_communication_mode': preferredCommunicationMode,
    };
  }

  FarmerProfileModel copyWith({
    String? village,
    String? talukOrBlock,
    String? district,
    String? state,
    String? pincode,
    double? totalLandholdingAcres,
    String? identityProofType,
    String? identityProofNumber,
    String? preferredCommunicationMode,
  }) {
    return FarmerProfileModel(
      id: id,
      userId: userId,
      village: village ?? this.village,
      talukOrBlock: talukOrBlock ?? this.talukOrBlock,
      district: district ?? this.district,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      totalLandholdingAcres:
          totalLandholdingAcres ?? this.totalLandholdingAcres,
      identityProofType: identityProofType ?? this.identityProofType,
      identityProofNumber: identityProofNumber ?? this.identityProofNumber,
      preferredCommunicationMode:
          preferredCommunicationMode ?? this.preferredCommunicationMode,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
