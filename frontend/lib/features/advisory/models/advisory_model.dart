/// Models representing Government Schemes, Subsidies, Loans, Insurance, and Agricultural Centers.
class SchemeModel {
  const SchemeModel({
    required this.id,
    required this.title,
    required this.category,
    required this.provider,
    required this.description,
    required this.benefits,
    required this.eligibility,
    this.requiredDocuments,
    this.applicationProcess,
    this.officialLink,
    required this.state,
    required this.isActive,
    this.createdAt,
  });

  final int id;
  final String title;
  final String category; // 'scheme', 'subsidy', 'loan', 'insurance'
  final String provider;
  final String description;
  final String benefits;
  final String eligibility;
  final String? requiredDocuments;
  final String? applicationProcess;
  final String? officialLink;
  final String state;
  final bool isActive;
  final DateTime? createdAt;

  factory SchemeModel.fromJson(Map<String, dynamic> json) {
    return SchemeModel(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ?? 'scheme',
      provider: json['provider'] as String? ?? '',
      description: json['description'] as String? ?? '',
      benefits: json['benefits'] as String? ?? '',
      eligibility: json['eligibility'] as String? ?? '',
      requiredDocuments: json['required_documents'] as String?,
      applicationProcess: json['application_process'] as String?,
      officialLink: json['official_link'] as String?,
      state: json['state'] as String? ?? 'All India',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category,
    'provider': provider,
    'description': description,
    'benefits': benefits,
    'eligibility': eligibility,
    'required_documents': requiredDocuments,
    'application_process': applicationProcess,
    'official_link': officialLink,
    'state': state,
    'is_active': isActive,
  };
}

class AgriculturalServiceModel {
  const AgriculturalServiceModel({
    required this.id,
    required this.name,
    required this.serviceType,
    required this.description,
    required this.address,
    required this.district,
    required this.state,
    this.pincode,
    required this.contactPhone,
    this.email,
    this.workingHours,
    this.latitude,
    this.longitude,
  });

  final int id;
  final String name;
  final String serviceType;
  final String description;
  final String address;
  final String district;
  final String state;
  final String? pincode;
  final String contactPhone;
  final String? email;
  final String? workingHours;
  final double? latitude;
  final double? longitude;

  factory AgriculturalServiceModel.fromJson(Map<String, dynamic> json) {
    return AgriculturalServiceModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      serviceType: json['service_type'] as String? ?? 'Agricultural Center',
      description: json['description'] as String? ?? '',
      address: json['address'] as String? ?? '',
      district: json['district'] as String? ?? '',
      state: json['state'] as String? ?? '',
      pincode: json['pincode'] as String?,
      contactPhone: json['contact_phone'] as String? ?? '',
      email: json['email'] as String?,
      workingHours: json['working_hours'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}
