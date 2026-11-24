// Models representing Farmer Farms, cultivated Crops, and Livestock.

class CropModel {
  const CropModel({
    required this.id,
    required this.farmId,
    required this.cropName,
    this.variety,
    required this.season,
    required this.areaAcres,
    this.sowingDate,
    this.expectedHarvestDate,
    this.growthStage,
    this.estimatedYieldKg,
    this.notes,
  });

  final int id;
  final int farmId;
  final String cropName;
  final String? variety;
  final String season;
  final double areaAcres;
  final String? sowingDate;
  final String? expectedHarvestDate;
  final String? growthStage;
  final double? estimatedYieldKg;
  final String? notes;

  factory CropModel.fromJson(Map<String, dynamic> json) {
    return CropModel(
      id: json['id'] as int? ?? 0,
      farmId: json['farm_id'] as int? ?? 0,
      cropName: json['crop_name'] as String? ?? 'Unnamed Crop',
      variety: json['variety'] as String?,
      season: json['season'] as String? ?? 'Kharif',
      areaAcres: (json['area_acres'] as num?)?.toDouble() ?? 1.0,
      sowingDate: json['sowing_date'] as String?,
      expectedHarvestDate: json['expected_harvest_date'] as String?,
      growthStage: json['growth_stage'] as String?,
      estimatedYieldKg: (json['estimated_yield_kg'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'crop_name': cropName,
      if (variety != null && variety!.isNotEmpty) 'variety': variety,
      'season': season,
      'area_acres': areaAcres,
      if (sowingDate != null && sowingDate!.isNotEmpty)
        'sowing_date': sowingDate,
      if (expectedHarvestDate != null && expectedHarvestDate!.isNotEmpty)
        'expected_harvest_date': expectedHarvestDate,
      if (growthStage != null && growthStage!.isNotEmpty)
        'growth_stage': growthStage,
      if (estimatedYieldKg != null) 'estimated_yield_kg': estimatedYieldKg,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }
}

class LivestockModel {
  const LivestockModel({
    required this.id,
    required this.farmId,
    required this.category,
    this.breedOrType,
    required this.count,
    this.purpose,
    this.healthStatus = 'Healthy',
    this.notes,
  });

  final int id;
  final int farmId;
  final String category;
  final String? breedOrType;
  final int count;
  final String? purpose;
  final String healthStatus;
  final String? notes;

  factory LivestockModel.fromJson(Map<String, dynamic> json) {
    return LivestockModel(
      id: json['id'] as int? ?? 0,
      farmId: json['farm_id'] as int? ?? 0,
      category: json['category'] as String? ?? 'Cattle',
      breedOrType: json['breed_or_type'] as String?,
      count: json['count'] as int? ?? 1,
      purpose: json['purpose'] as String?,
      healthStatus: json['health_status'] as String? ?? 'Healthy',
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      if (breedOrType != null && breedOrType!.isNotEmpty)
        'breed_or_type': breedOrType,
      'count': count,
      if (purpose != null && purpose!.isNotEmpty) 'purpose': purpose,
      'health_status': healthStatus,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }
}

class FarmModel {
  const FarmModel({
    required this.id,
    required this.farmerProfileId,
    required this.farmName,
    required this.totalAreaAcres,
    required this.soilType,
    required this.irrigationType,
    this.waterSource,
    required this.location,
    required this.district,
    required this.state,
    this.ownershipType,
    this.notes,
    this.crops = const [],
    this.livestock = const [],
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int farmerProfileId;
  final String farmName;
  final double totalAreaAcres;
  final String soilType;
  final String irrigationType;
  final String? waterSource;
  final String location;
  final String district;
  final String state;
  final String? ownershipType;
  final String? notes;
  final List<CropModel> crops;
  final List<LivestockModel> livestock;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory FarmModel.fromJson(Map<String, dynamic> json) {
    return FarmModel(
      id: json['id'] as int? ?? 0,
      farmerProfileId: json['farmer_profile_id'] as int? ?? 0,
      farmName: json['farm_name'] as String? ?? 'My Farm',
      totalAreaAcres: (json['total_area_acres'] as num?)?.toDouble() ?? 1.0,
      soilType: json['soil_type'] as String? ?? 'Alluvial',
      irrigationType: json['irrigation_type'] as String? ?? 'Rainfed',
      waterSource: json['water_source'] as String?,
      location: json['location'] as String? ?? '',
      district: json['district'] as String? ?? '',
      state: json['state'] as String? ?? '',
      ownershipType: json['ownership_type'] as String?,
      notes: json['notes'] as String?,
      crops:
          (json['crops'] as List<dynamic>?)
              ?.map((c) => CropModel.fromJson(c as Map<String, dynamic>))
              .toList() ??
          const [],
      livestock:
          (json['livestock'] as List<dynamic>?)
              ?.map((l) => LivestockModel.fromJson(l as Map<String, dynamic>))
              .toList() ??
          const [],
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
      'farm_name': farmName,
      'total_area_acres': totalAreaAcres,
      'soil_type': soilType,
      'irrigation_type': irrigationType,
      if (waterSource != null && waterSource!.isNotEmpty)
        'water_source': waterSource,
      'location': location,
      'district': district,
      'state': state,
      if (ownershipType != null && ownershipType!.isNotEmpty)
        'ownership_type': ownershipType,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }
}
