class EmergencyModel {
  final String id;
  final String title;
  final String description;
  final String type;
  final String contactName;
  final String contactPhone;
  final String expiryDate;
  final bool collectResponse;
  final String locationName;
  final int going;
  final int maybe;
  final int notGoing;

  EmergencyModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.contactName,
    required this.contactPhone,
    required this.expiryDate,
    required this.collectResponse,
    required this.locationName,
    required this.going,
    required this.maybe,
    required this.notGoing,
  });

  factory EmergencyModel.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>?;
    final stats = json['stats'] as Map<String, dynamic>?;

    return EmergencyModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? '',
      contactName: json['contactName'] ?? '',
      contactPhone: json['contactPhone'] ?? '',
      expiryDate: json['expiryDate'] ?? '',
      collectResponse: json['collectResponse'] ?? false,
      locationName: location?['name'] ?? 'Unknown Location',
      going: stats?['going'] ?? stats?['coming'] ?? 0,
      maybe: stats?['maybe'] ?? 0,
      notGoing: stats?['notGoing'] ?? stats?['unable'] ?? 0,
    );
  }
}

class EmergencyMemberModel {
  final String id;
  final String name;
  final String phone;

  EmergencyMemberModel({
    required this.id,
    required this.name,
    required this.phone,
  });

  factory EmergencyMemberModel.fromJson(Map<String, dynamic> json) {
    return EmergencyMemberModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Unknown',
      phone: json['phone'] ?? '',
    );
  }
}

class EmergencyResponseModel {
  final String status;
  final String? note;
  final EmergencyMemberModel member;

  EmergencyResponseModel({
    required this.status,
    this.note,
    required this.member,
  });

  factory EmergencyResponseModel.fromJson(Map<String, dynamic> json) {
    return EmergencyResponseModel(
      status: json['status'] ?? 'UNKNOWN',
      note: json['note'] as String?,
      member: EmergencyMemberModel.fromJson(
        json['member'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}
