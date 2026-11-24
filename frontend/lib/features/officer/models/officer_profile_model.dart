import 'package:agrochat_app/features/auth/models/auth_user.dart';

/// Model representing an Agricultural Officer's professional profile.
class OfficerProfileModel {
  const OfficerProfileModel({
    required this.id,
    required this.userId,
    required this.designation,
    this.department,
    required this.specialization,
    this.qualifications,
    this.experienceYears = 0,
    this.languagesSpoken = 'English',
    this.officeLocation,
    required this.district,
    required this.state,
    this.isAvailable = true,
    this.availabilityHours,
    this.bio,
    this.user,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int userId;
  final String designation;
  final String? department;
  final String specialization;
  final String? qualifications;
  final int experienceYears;
  final String languagesSpoken;
  final String? officeLocation;
  final String district;
  final String state;
  final bool isAvailable;
  final String? availabilityHours;
  final String? bio;
  final AuthUser? user;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get fullName => user?.fullName ?? designation;

  factory OfficerProfileModel.fromJson(Map<String, dynamic> json) {
    return OfficerProfileModel(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      designation: json['designation'] as String? ?? 'Agricultural Officer',
      department: json['department'] as String?,
      specialization:
          json['specialization'] as String? ?? 'General Agriculture',
      qualifications: json['qualifications'] as String?,
      experienceYears: json['experience_years'] as int? ?? 0,
      languagesSpoken: json['languages_spoken'] as String? ?? 'English',
      officeLocation: json['office_location'] as String?,
      district: json['district'] as String? ?? '',
      state: json['state'] as String? ?? '',
      isAvailable: json['is_available'] as bool? ?? true,
      availabilityHours: json['availability_hours'] as String?,
      bio: json['bio'] as String?,
      user: json['user'] != null && json['user'] is Map<String, dynamic>
          ? AuthUser.fromJson(json['user'] as Map<String, dynamic>)
          : null,
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
      'designation': designation,
      if (department != null && department!.isNotEmpty)
        'department': department,
      'specialization': specialization,
      if (qualifications != null && qualifications!.isNotEmpty)
        'qualifications': qualifications,
      'experience_years': experienceYears,
      'languages_spoken': languagesSpoken,
      if (officeLocation != null && officeLocation!.isNotEmpty)
        'office_location': officeLocation,
      'district': district,
      'state': state,
      'is_available': isAvailable,
      if (availabilityHours != null && availabilityHours!.isNotEmpty)
        'availability_hours': availabilityHours,
      if (bio != null && bio!.isNotEmpty) 'bio': bio,
    };
  }

  OfficerProfileModel copyWith({
    String? designation,
    String? department,
    String? specialization,
    String? qualifications,
    int? experienceYears,
    String? languagesSpoken,
    String? officeLocation,
    String? district,
    String? state,
    bool? isAvailable,
    String? availabilityHours,
    String? bio,
    AuthUser? user,
  }) {
    return OfficerProfileModel(
      id: id,
      userId: userId,
      designation: designation ?? this.designation,
      department: department ?? this.department,
      specialization: specialization ?? this.specialization,
      qualifications: qualifications ?? this.qualifications,
      experienceYears: experienceYears ?? this.experienceYears,
      languagesSpoken: languagesSpoken ?? this.languagesSpoken,
      officeLocation: officeLocation ?? this.officeLocation,
      district: district ?? this.district,
      state: state ?? this.state,
      isAvailable: isAvailable ?? this.isAvailable,
      availabilityHours: availabilityHours ?? this.availabilityHours,
      bio: bio ?? this.bio,
      user: user ?? this.user,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
