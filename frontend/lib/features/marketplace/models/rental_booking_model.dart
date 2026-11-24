/// Models representing Equipment Rentals and Farmer Booking Requests.
class EquipmentRentalModel {
  const EquipmentRentalModel({
    required this.id,
    required this.equipmentName,
    required this.category,
    required this.description,
    required this.providerName,
    required this.contactPhone,
    required this.location,
    required this.district,
    required this.state,
    required this.dailyRateInr,
    this.hourlyRateInr,
    required this.availabilityStatus,
  });

  final int id;
  final String equipmentName;
  final String category;
  final String description;
  final String providerName;
  final String contactPhone;
  final String location;
  final String district;
  final String state;
  final double dailyRateInr;
  final double? hourlyRateInr;
  final String availabilityStatus; // 'available', 'rented', 'maintenance'

  factory EquipmentRentalModel.fromJson(Map<String, dynamic> json) {
    return EquipmentRentalModel(
      id: json['id'] as int,
      equipmentName: json['equipment_name'] as String? ?? '',
      category: json['category'] as String? ?? 'Equipment',
      description: json['description'] as String? ?? '',
      providerName: json['provider_name'] as String? ?? '',
      contactPhone: json['contact_phone'] as String? ?? '',
      location: json['location'] as String? ?? '',
      district: json['district'] as String? ?? '',
      state: json['state'] as String? ?? '',
      dailyRateInr: (json['daily_rate_inr'] as num?)?.toDouble() ?? 0.0,
      hourlyRateInr: (json['hourly_rate_inr'] as num?)?.toDouble(),
      availabilityStatus: json['availability_status'] as String? ?? 'available',
    );
  }
}

class RentalBookingModel {
  const RentalBookingModel({
    required this.id,
    required this.equipmentId,
    this.equipmentName,
    required this.farmerId,
    required this.startDate,
    required this.endDate,
    required this.rentalType,
    required this.durationUnits,
    required this.totalCostInr,
    required this.deliveryLocation,
    required this.contactPhone,
    required this.bookingStatus,
    this.farmerNotes,
    this.providerResponse,
    this.createdAt,
  });

  final int id;
  final int equipmentId;
  final String? equipmentName;
  final int farmerId;
  final String startDate;
  final String endDate;
  final String rentalType;
  final int durationUnits;
  final double totalCostInr;
  final String deliveryLocation;
  final String contactPhone;
  final String bookingStatus;
  final String? farmerNotes;
  final String? providerResponse;
  final DateTime? createdAt;

  factory RentalBookingModel.fromJson(Map<String, dynamic> json) {
    return RentalBookingModel(
      id: json['id'] as int,
      equipmentId: json['equipment_id'] as int,
      equipmentName: json['equipment_name'] as String?,
      farmerId: json['farmer_id'] as int,
      startDate: json['start_date'] as String? ?? '',
      endDate: json['end_date'] as String? ?? '',
      rentalType: json['rental_type'] as String? ?? 'daily',
      durationUnits: json['duration_units'] as int? ?? 1,
      totalCostInr: (json['total_cost_inr'] as num?)?.toDouble() ?? 0.0,
      deliveryLocation: json['delivery_location'] as String? ?? '',
      contactPhone: json['contact_phone'] as String? ?? '',
      bookingStatus: json['booking_status'] as String? ?? 'pending',
      farmerNotes: json['farmer_notes'] as String?,
      providerResponse: json['provider_response'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'equipment_id': equipmentId,
    'start_date': startDate,
    'end_date': endDate,
    'rental_type': rentalType,
    'duration_units': durationUnits,
    'delivery_location': deliveryLocation,
    'contact_phone': contactPhone,
    if (farmerNotes != null && farmerNotes!.isNotEmpty)
      'farmer_notes': farmerNotes,
  };
}
