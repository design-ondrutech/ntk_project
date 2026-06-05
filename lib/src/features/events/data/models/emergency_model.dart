import 'package:flutter/material.dart';

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
  final String? audience;

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
    this.audience,
  });

  factory EmergencyModel.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>?;
    final stats = json['stats'] as Map<String, dynamic>?;
    final member = json['member'] as Map<String, dynamic>?;
    final createdByJson = json['createdBy'] as Map<String, dynamic>?;
    
    String creator = '';
    int? parsedCreatorId;

    if (member != null) {
      creator = "${member['name'] ?? ''} ${member['surname'] ?? ''}".trim();
      parsedCreatorId = member['id'] is int ? member['id'] as int : int.tryParse(member['id'].toString());
    } else if (createdByJson != null) {
      creator = createdByJson['name'] ?? '';
      parsedCreatorId = createdByJson['id'] is int ? createdByJson['id'] as int : int.tryParse(createdByJson['id'].toString());
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
      audience: json['audience']?.toString(),
    );
  }

  String get statusBadgeText {
    final s = status?.toUpperCase() ?? 'PENDING';
    if (s == 'APPROVED' || s == 'ACCEPTED') return 'Accepted';
    if (s == 'REJECTED') return 'Rejected';
    if (s == 'FORWARDED' || s == 'FORWARD') return 'Forwarded';
    return 'Pending';
  }

  String get currentLevelText {
    final s = status?.toUpperCase() ?? 'PENDING';
    final aud = audience?.toUpperCase() ?? '';

    if (s == 'APPROVED' || s == 'ACCEPTED') return 'Accepted';
    if (s == 'REJECTED') return 'Rejected';

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
    if (text == 'accepted') return const Color(0xFFE6F4EA);
    if (text == 'rejected') return const Color(0xFFFCE8E6);
    if (text == 'forwarded') return const Color(0xFFE8F0FE);
    return const Color(0xFFFEF7E0); // Pending
  }

  Color get statusBadgeTextColor {
    final text = statusBadgeText.toLowerCase();
    if (text == 'accepted') return const Color(0xFF137333);
    if (text == 'rejected') return const Color(0xFFC5221F);
    if (text == 'forwarded') return const Color(0xFF1967D2);
    return const Color(0xFFB06000); // Pending
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
