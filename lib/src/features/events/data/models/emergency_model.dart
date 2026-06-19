import 'package:flutter/material.dart';
import 'package:ntk_project/src/core/utils/date_helper.dart';

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
  final String? createdAt;
  final String? createdBy;
  final String? status;
  final int? creatorId;
  final int? createdById;
  final String? audience;
  final String? bloodGroup;
  final String? unitsRequired;
  final String? hospitalName;
  final String? patientCondition;
  final String? disasterType;
  final String? affectedArea;
  final String? requiredSupport;
  final String? volunteerType;

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
    this.createdAt,
    this.createdBy,
    this.status,
    this.creatorId,
    this.createdById,
    this.audience,
    this.bloodGroup,
    this.unitsRequired,
    this.hospitalName,
    this.patientCondition,
    this.disasterType,
    this.affectedArea,
    this.requiredSupport,
    this.volunteerType,
  });

  factory EmergencyModel.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>?;
    final stats = json['stats'] as Map<String, dynamic>?;
    final member = json['member'] as Map<String, dynamic>?;
    final createdByJson = json['createdBy'] as Map<String, dynamic>?;
    
    String creator = '';
    int? parsedCreatorId;
    int? parsedCreatedById;

    if (member != null) {
      creator = "${member['name'] ?? ''} ${member['surname'] ?? ''}".trim();
      parsedCreatorId = member['id'] is int ? member['id'] as int : int.tryParse(member['id'].toString());
    } else if (createdByJson != null) {
      creator = createdByJson['name'] ?? '';
      parsedCreatorId = createdByJson['id'] is int ? createdByJson['id'] as int : int.tryParse(createdByJson['id'].toString());
    }

    if (createdByJson != null) {
      parsedCreatedById = createdByJson['id'] is int ? createdByJson['id'] as int : int.tryParse(createdByJson['id'].toString());
    }

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
      createdAt: json['createdAt']?.toString(),
      createdBy: creator.isNotEmpty ? creator : null,
      status: json['status']?.toString(),
      creatorId: parsedCreatorId,
      createdById: parsedCreatedById,
      audience: json['audience']?.toString(),
      bloodGroup: json['bloodGroup']?.toString(),
      unitsRequired: json['unitsRequired']?.toString(),
      hospitalName: json['hospitalName']?.toString(),
      patientCondition: json['patientCondition']?.toString(),
      disasterType: json['disasterType']?.toString(),
      affectedArea: json['affectedArea']?.toString(),
      requiredSupport: json['requiredSupport']?.toString(),
      volunteerType: json['volunteerType']?.toString(),
    );
  }

  bool isCreatedBy(int? userId) {
    if (userId == null) return false;
    if (creatorId == userId || creatorId?.toString() == userId.toString()) return true;
    if (createdById == userId || createdById?.toString() == userId.toString()) return true;
    return false;
  }

  EmergencyModel copyWith({
    String? id,
    String? title,
    String? description,
    String? type,
    String? contactName,
    String? contactPhone,
    String? expiryDate,
    bool? collectResponse,
    String? locationName,
    int? going,
    int? maybe,
    int? notGoing,
    String? createdAt,
    String? createdBy,
    String? status,
    int? creatorId,
    int? createdById,
    String? audience,
    String? bloodGroup,
    String? unitsRequired,
    String? hospitalName,
    String? patientCondition,
    String? disasterType,
    String? affectedArea,
    String? requiredSupport,
    String? volunteerType,
  }) {
    return EmergencyModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      contactName: contactName ?? this.contactName,
      contactPhone: contactPhone ?? this.contactPhone,
      expiryDate: expiryDate ?? this.expiryDate,
      collectResponse: collectResponse ?? this.collectResponse,
      locationName: locationName ?? this.locationName,
      going: going ?? this.going,
      maybe: maybe ?? this.maybe,
      notGoing: notGoing ?? this.notGoing,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      status: status ?? this.status,
      creatorId: creatorId ?? this.creatorId,
      createdById: createdById ?? this.createdById,
      audience: audience ?? this.audience,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      unitsRequired: unitsRequired ?? this.unitsRequired,
      hospitalName: hospitalName ?? this.hospitalName,
      patientCondition: patientCondition ?? this.patientCondition,
      disasterType: disasterType ?? this.disasterType,
      affectedArea: affectedArea ?? this.affectedArea,
      requiredSupport: requiredSupport ?? this.requiredSupport,
      volunteerType: volunteerType ?? this.volunteerType,
    );
  }

  bool get isExpired {
    if (expiryDate.isEmpty) return false;
    try {
      final expiry = DateHelper.parseUtcToLocal(expiryDate);
      return DateTime.now().isAfter(expiry);
    } catch (_) {
      return false;
    }
  }

  bool get isCompleted {
    final s = status?.toUpperCase() ?? '';
    return s == 'COMPLETED' || s == 'CLOSED';
  }

  String get statusBadgeText {
    final s = status?.toUpperCase() ?? 'PENDING';
    if (s == 'COMPLETED' || s == 'CLOSED') return 'Completed';
    if (s == 'APPROVED' ||
        s == 'ACCEPTED' ||
        s == 'APPROVED_SUB_ADMIN' ||
        s == 'APPROVED_ADMIN' ||
        s == 'APPROVED_STATE') return 'Accepted';
    if (s == 'REJECTED') return 'Rejected';
    if (s == 'FORWARDED' || s == 'FORWARD') return 'Forwarded';
    if (isExpired) return 'Expired';
    return 'Pending';
  }

  String get currentLevelText {
    final s = status?.toUpperCase() ?? 'PENDING';
    final aud = audience?.toUpperCase() ?? '';

    if (s == 'COMPLETED' || s == 'CLOSED') return 'Completed';
    if (s == 'REJECTED') return 'Rejected';

    if (s == 'APPROVED_SUB_ADMIN') {
      return 'Approved by Sub Admin (Live)';
    }
    if (s == 'APPROVED_ADMIN') {
      return 'Approved by Admin (Live)';
    }
    if (s == 'APPROVED_STATE') {
      return 'Approved (State Live)';
    }
    if (s == 'APPROVED' || s == 'ACCEPTED') {
      return 'Accepted';
    }

    if (s == 'PENDING_SUB_ADMIN') {
      return 'Sub Admin Review';
    }
    if (s == 'PENDING_ADMIN') {
      return 'Admin Review';
    }
    if (s == 'PENDING_SUPER_ADMIN') {
      return 'Super Admin Review';
    }

    if (s == 'FORWARDED' || s == 'FORWARD') {
      if (aud == 'STATE' || aud == 'SUPER_ADMIN') {
        return 'Super Admin Review';
      }
      return 'Admin Review';
    }

    if (aud == 'STATE' || aud == 'SUPER_ADMIN') {
      return 'Super Admin Review';
    } else if (aud == 'DISTRICT' || aud == 'ADMIN') {
      return 'Admin Review';
    }
    return 'Sub Admin Review';
  }

  Color get statusBadgeBgColor {
    final text = statusBadgeText.toLowerCase();
    if (text == 'completed') return const Color(0xFFE0F2FE);
    if (text == 'expired') return const Color(0xFFF3F4F6);
    if (text == 'accepted') return const Color(0xFFE6F4EA);
    if (text == 'rejected') return const Color(0xFFFCE8E6);
    if (text == 'forwarded') return const Color(0xFFE8F0FE);
    return const Color(0xFFFEF7E0); // Pending
  }

  Color get statusBadgeTextColor {
    final text = statusBadgeText.toLowerCase();
    if (text == 'completed') return const Color(0xFF0369A1);
    if (text == 'expired') return const Color(0xFF6B7280);
    if (text == 'accepted') return const Color(0xFF137333);
    if (text == 'rejected') return const Color(0xFFC5221F);
    if (text == 'forwarded') return const Color(0xFF1967D2);
    return const Color(0xFFB06000); // Pending
  }

  String get typeLabel {
    final t = type.toUpperCase();
    if (t == 'BLOOD_REQUIRED') return 'Blood Request';
    if (t == 'MEDICAL_HELP') return 'Medical Emergency';
    if (t == 'DISASTER_SUPPORT') return 'Disaster Alert';
    if (t == 'VOLUNTEER_NEEDED') return 'Volunteer Request';
    return 'Emergency Request';
  }

  String get typeEmoji {
    final t = type.toUpperCase();
    if (t == 'BLOOD_REQUIRED') return '🩸';
    if (t == 'MEDICAL_HELP') return '🏥';
    if (t == 'DISASTER_SUPPORT') return '🌊';
    if (t == 'VOLUNTEER_NEEDED') return '🤝';
    return '⚠️';
  }

  IconData get typeIcon {
    final t = type.toUpperCase();
    if (t == 'BLOOD_REQUIRED') return Icons.bloodtype_rounded;
    if (t == 'MEDICAL_HELP') return Icons.medical_services_rounded;
    if (t == 'DISASTER_SUPPORT') return Icons.thunderstorm_rounded;
    if (t == 'VOLUNTEER_NEEDED') return Icons.people_alt_rounded;
    return Icons.warning_amber_rounded;
  }

  Color get typeColor {
    final t = type.toUpperCase();
    if (t == 'BLOOD_REQUIRED') return const Color(0xFFC5221F);
    if (t == 'MEDICAL_HELP') return const Color(0xFF0F5A29);
    if (t == 'DISASTER_SUPPORT') return const Color(0xFF1967D2);
    if (t == 'VOLUNTEER_NEEDED') return const Color(0xFFB06000);
    return const Color(0xFF374151);
  }

  Color get typeBgColor {
    final t = type.toUpperCase();
    if (t == 'BLOOD_REQUIRED') return const Color(0xFFFCE8E6);
    if (t == 'MEDICAL_HELP') return const Color(0xFFE6F4EA);
    if (t == 'DISASTER_SUPPORT') return const Color(0xFFE8F0FE);
    if (t == 'VOLUNTEER_NEEDED') return const Color(0xFFFEF7E0);
    return const Color(0xFFF1F5F9);
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
