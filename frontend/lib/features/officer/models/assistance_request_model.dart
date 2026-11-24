// Models representing Assistance Requests submitted by Farmers and handled by Officers.

class RequestAttachmentModel {
  const RequestAttachmentModel({
    required this.id,
    required this.requestId,
    required this.fileName,
    required this.fileType,
    required this.fileSizeBytes,
    required this.fileUrl,
    this.description,
    this.createdAt,
  });

  final int id;
  final int requestId;
  final String fileName;
  final String fileType;
  final int fileSizeBytes;
  final String fileUrl;
  final String? description;
  final DateTime? createdAt;

  factory RequestAttachmentModel.fromJson(Map<String, dynamic> json) {
    return RequestAttachmentModel(
      id: json['id'] as int? ?? 0,
      requestId: json['request_id'] as int? ?? 0,
      fileName: json['file_name'] as String? ?? 'attachment',
      fileType: json['file_type'] as String? ?? 'image',
      fileSizeBytes: json['file_size_bytes'] as int? ?? 0,
      fileUrl: json['file_url'] as String? ?? '',
      description: json['description'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'request_id': requestId,
      'file_name': fileName,
      'file_type': fileType,
      'file_size_bytes': fileSizeBytes,
      'file_url': fileUrl,
      if (description != null) 'description': description,
    };
  }
}

class AssistanceRequestModel {
  const AssistanceRequestModel({
    required this.id,
    required this.farmerId,
    this.officerId,
    this.farmId,
    this.cropId,
    required this.title,
    required this.category,
    required this.description,
    required this.priority,
    required this.status,
    this.officerNotes,
    this.rejectionReason,
    this.acceptedAt,
    this.resolvedAt,
    this.createdAt,
    this.updatedAt,
    this.farmerName,
    this.farmerPhone,
    this.officerName,
    this.farmName,
    this.cropName,
    this.consultationId,
    this.attachments = const [],
  });

  final int id;
  final int farmerId;
  final int? officerId;
  final int? farmId;
  final int? cropId;
  final String title;
  final String category;
  final String description;
  final String priority;
  final String status;
  final String? officerNotes;
  final String? rejectionReason;
  final DateTime? acceptedAt;
  final DateTime? resolvedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Joined metadata fields
  final String? farmerName;
  final String? farmerPhone;
  final String? officerName;
  final String? farmName;
  final String? cropName;
  final int? consultationId;
  final List<RequestAttachmentModel> attachments;

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isAccepted => status.toLowerCase() == 'accepted';
  bool get isInProgress => status.toLowerCase() == 'in_progress';
  bool get isResolved => status.toLowerCase() == 'resolved';
  bool get isRejected => status.toLowerCase() == 'rejected';

  factory AssistanceRequestModel.fromJson(Map<String, dynamic> json) {
    return AssistanceRequestModel(
      id: json['id'] as int? ?? 0,
      farmerId: json['farmer_id'] as int? ?? 0,
      officerId: json['officer_id'] as int?,
      farmId: json['farm_id'] as int?,
      cropId: json['crop_id'] as int?,
      title: json['title'] as String? ?? 'Untitled Request',
      category: json['category'] as String? ?? 'General Advisory',
      description: json['description'] as String? ?? '',
      priority: json['priority'] as String? ?? 'medium',
      status: json['status'] as String? ?? 'pending',
      officerNotes: json['officer_notes'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
      acceptedAt: json['accepted_at'] != null
          ? DateTime.tryParse(json['accepted_at'].toString())
          : null,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.tryParse(json['resolved_at'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      farmerName: json['farmer_name'] as String?,
      farmerPhone: json['farmer_phone'] as String?,
      officerName: json['officer_name'] as String?,
      farmName: json['farm_name'] as String?,
      cropName: json['crop_name'] as String?,
      consultationId: json['consultation_id'] as int?,
      attachments:
          (json['attachments'] as List<dynamic>?)
              ?.map(
                (a) =>
                    RequestAttachmentModel.fromJson(a as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farmer_id': farmerId,
      if (officerId != null) 'officer_id': officerId,
      if (farmId != null) 'farm_id': farmId,
      if (cropId != null) 'crop_id': cropId,
      'title': title,
      'category': category,
      'description': description,
      'priority': priority,
      'status': status,
      if (officerNotes != null) 'officer_notes': officerNotes,
      if (rejectionReason != null) 'rejection_reason': rejectionReason,
      if (farmerName != null) 'farmer_name': farmerName,
      if (farmerPhone != null) 'farmer_phone': farmerPhone,
      if (officerName != null) 'officer_name': officerName,
      if (farmName != null) 'farm_name': farmName,
      if (cropName != null) 'crop_name': cropName,
      if (consultationId != null) 'consultation_id': consultationId,
    };
  }

  AssistanceRequestModel copyWith({
    String? status,
    String? officerNotes,
    String? rejectionReason,
    int? officerId,
    String? officerName,
    DateTime? acceptedAt,
    DateTime? resolvedAt,
    List<RequestAttachmentModel>? attachments,
  }) {
    return AssistanceRequestModel(
      id: id,
      farmerId: farmerId,
      officerId: officerId ?? this.officerId,
      farmId: farmId,
      cropId: cropId,
      title: title,
      category: category,
      description: description,
      priority: priority,
      status: status ?? this.status,
      officerNotes: officerNotes ?? this.officerNotes,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      farmerName: farmerName,
      farmerPhone: farmerPhone,
      officerName: officerName ?? this.officerName,
      farmName: farmName,
      cropName: cropName,
      consultationId: consultationId,
      attachments: attachments ?? this.attachments,
    );
  }
}
