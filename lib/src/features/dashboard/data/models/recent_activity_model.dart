import 'package:equatable/equatable.dart';

class RecentActivityUserModel extends Equatable {
  final int id;
  final String name;
  final String role;

  const RecentActivityUserModel({
    required this.id,
    required this.name,
    required this.role,
  });

  factory RecentActivityUserModel.fromJson(Map<String, dynamic> json) {
    final idValue = json['id'];
    return RecentActivityUserModel(
      id: idValue is int ? idValue : int.tryParse(idValue?.toString() ?? '') ?? 0,
      name: json['name'] as String? ?? 'Unknown',
      role: json['role'] as String? ?? 'MEMBER',
    );
  }

  @override
  List<Object?> get props => [id, name, role];
}

class RecentActivityModel extends Equatable {
  final int id;
  final String action;
  final String details;
  final String createdAt;
  final RecentActivityUserModel? user;

  // Union-specific fields
  final String typename;
  final String? title;
  final String? description;
  final String? locationName;
  final String? date;
  final String? status;
  final String? createdByName;
  final int? goingCount;

  final String? emergencyType;
  final String? audience;
  final String? bloodGroup;
  final String? contactName;
  final String? contactPhone;
  final String? expiryDate;
  final bool? collectResponse;
  final int? maybeCount;

  final String? memberName;
  final String? approvedByName;
  final String? time;

  const RecentActivityModel({
    required this.id,
    required this.action,
    required this.details,
    required this.createdAt,
    this.user,
    this.typename = '',
    this.title,
    this.description,
    this.locationName,
    this.date,
    this.status,
    this.createdByName,
    this.goingCount,
    this.emergencyType,
    this.audience,
    this.bloodGroup,
    this.contactName,
    this.contactPhone,
    this.expiryDate,
    this.collectResponse,
    this.maybeCount,
    this.memberName,
    this.approvedByName,
    this.time,
  });

  factory RecentActivityModel.fromJson(Map<String, dynamic> json) {
    // Support the new Activity schema
    final activityType = json['activityType'] as String?;
    if (activityType != null) {
      final idValue = json['id'];
      final id = idValue is int ? idValue : int.tryParse(idValue?.toString() ?? '') ?? 0;
      final desc = json['description'] as String? ?? '';
      final title = json['title'] as String? ?? '';
      final createdAt = json['createdAt'] as String? ?? '';
      final memberJson = json['member'];
      final locationJson = json['location'];

      return RecentActivityModel(
        id: id,
        action: activityType,
        details: desc,
        createdAt: createdAt,
        typename: activityType == 'EVENT' ? 'Event' : activityType == 'EMERGENCY' ? 'EmergencyRequest' : 'Activity',
        title: title,
        description: desc,
        locationName: locationJson?['name'] as String?,
        user: memberJson is Map<String, dynamic> ? RecentActivityUserModel.fromJson(memberJson) : null,
      );
    }

    final typename = json['__typename'] as String? ?? '';
    final idValue = json['id'];
    final id = idValue is int ? idValue : int.tryParse(idValue?.toString() ?? '') ?? 0;
    final createdAt = json['createdAt'] as String? ?? '';
    final userJson = json['user'];

    String action = json['action'] as String? ?? 'ACTIVITY';
    String details = json['details'] as String? ?? '';

    String? title;
    String? description;
    String? locationName;
    String? date;
    String? status;
    String? createdByName;
    int? goingCount;

    String? emergencyType;
    String? audience;
    String? bloodGroup;
    String? contactName;
    String? contactPhone;
    String? expiryDate;
    bool? collectResponse;
    int? maybeCount;

    String? memberName;
    String? approvedByName;
    String? time;

    if (typename == 'Event') {
      title = json['title'] as String?;
      description = json['description'] as String?;
      locationName = json['location']?['name'] as String?;
      date = json['date'] as String?;
      status = json['status'] as String?;
      createdByName = json['createdBy']?['name'] as String?;
      goingCount = json['stats']?['going'] != null
          ? (json['stats']['going'] is int
              ? json['stats']['going'] as int
              : int.tryParse(json['stats']['going'].toString()) ?? 0)
          : 0;
      action = 'EVENT';
      details = description ?? '';
    } else if (typename == 'EmergencyRequest') {
      title = json['title'] as String?;
      description = json['description'] as String?;
      emergencyType = json['type'] as String?;
      status = json['status'] as String?;
      audience = json['audience'] as String?;
      locationName = json['location']?['name'] as String?;
      bloodGroup = json['member']?['bloodGroup'] as String?;
      createdByName = json['createdBy']?['name'] as String?;
      contactName = json['contactName'] as String?;
      contactPhone = json['contactPhone'] as String?;
      expiryDate = json['expiryDate'] as String?;
      collectResponse = json['collectResponse'] as bool?;
      maybeCount = json['stats']?['maybe'] != null
          ? (json['stats']['maybe'] is int
              ? json['stats']['maybe'] as int
              : int.tryParse(json['stats']['maybe'].toString()) ?? 0)
          : 0;
      action = 'EMERGENCY';
      details = description ?? '';
    } else if (typename == 'MemberApprovalActivity') {
      memberName = json['memberName'] as String?;
      approvedByName = json['approvedByName'] as String?;
      locationName = json['location']?['name'] as String?;
      time = json['time'] as String?;
      action = 'MEMBER';
      details = '$memberName was approved by $approvedByName';
    }

    return RecentActivityModel(
      id: id,
      action: action,
      details: details,
      createdAt: createdAt,
      user: userJson is Map<String, dynamic> ? RecentActivityUserModel.fromJson(userJson) : null,
      typename: typename,
      title: title,
      description: description,
      locationName: locationName,
      date: date,
      status: status,
      createdByName: createdByName,
      goingCount: goingCount,
      emergencyType: emergencyType,
      audience: audience,
      bloodGroup: bloodGroup,
      contactName: contactName,
      contactPhone: contactPhone,
      expiryDate: expiryDate,
      collectResponse: collectResponse,
      maybeCount: maybeCount,
      memberName: memberName,
      approvedByName: approvedByName,
      time: time,
    );
  }

  @override
  List<Object?> get props => [
        id,
        action,
        details,
        createdAt,
        user,
        typename,
        title,
        description,
        locationName,
        date,
        status,
        createdByName,
        goingCount,
        emergencyType,
        audience,
        bloodGroup,
        contactName,
        contactPhone,
        expiryDate,
        collectResponse,
        maybeCount,
        memberName,
        approvedByName,
        time,
      ];
}
