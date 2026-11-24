import 'package:agrochat_app/features/farmer/models/farm_model.dart';

/// Full Farmer details including contact, location, registered farms, crops, and livestock.
/// Returned exclusively to authorized Agricultural Officers via GET /api/farmers/{farmer_user_id}.
class FarmerInspectionModel {
  const FarmerInspectionModel({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.preferredLanguage,
    required this.village,
    required this.talukOrBlock,
    required this.district,
    required this.state,
    this.pincode,
    this.farmingExperienceYears,
    this.primaryOccupation = 'Farmer',
    this.bio,
    this.farms = const [],
  });

  final int userId;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String preferredLanguage;
  final String village;
  final String talukOrBlock;
  final String district;
  final String state;
  final String? pincode;
  final int? farmingExperienceYears;
  final String primaryOccupation;
  final String? bio;
  final List<FarmModel> farms;

  double get totalLandAcres {
    return farms.fold<double>(0.0, (sum, f) => sum + f.totalAreaAcres);
  }

  int get totalCropsCount {
    return farms.fold<int>(0, (sum, f) => sum + f.crops.length);
  }

  int get totalLivestockCount {
    return farms.fold<int>(0, (sum, f) => sum + f.livestock.length);
  }

  factory FarmerInspectionModel.fromJson(Map<String, dynamic> json) {
    final profileJson = json['profile'] as Map<String, dynamic>? ?? {};
    final userJson = profileJson['user'] as Map<String, dynamic>? ?? {};

    final farmsList =
        (json['farms'] as List<dynamic>?)
            ?.map((f) => FarmModel.fromJson(f as Map<String, dynamic>))
            .toList() ??
        const [];

    return FarmerInspectionModel(
      userId: userJson['id'] as int? ?? (profileJson['user_id'] as int? ?? 0),
      fullName: userJson['full_name'] as String? ?? 'Farmer',
      email: userJson['email'] as String? ?? '',
      phoneNumber: userJson['phone_number'] as String? ?? '',
      preferredLanguage: userJson['preferred_language'] as String? ?? 'English',
      village: profileJson['village'] as String? ?? '',
      talukOrBlock: profileJson['taluk_or_block'] as String? ?? '',
      district: profileJson['district'] as String? ?? '',
      state: profileJson['state'] as String? ?? '',
      pincode: profileJson['pincode'] as String?,
      farmingExperienceYears: profileJson['farming_experience_years'] as int?,
      primaryOccupation:
          profileJson['primary_occupation'] as String? ?? 'Farmer',
      bio: profileJson['bio'] as String?,
      farms: farmsList,
    );
  }
}
