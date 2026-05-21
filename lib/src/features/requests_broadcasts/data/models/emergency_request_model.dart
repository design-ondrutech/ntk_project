import 'package:equatable/equatable.dart';

class EmergencyRequestModel extends Equatable {
  final int id;
  final String title;
  final String? description;
  final String type;
  final String status;
  final String? locationName;
  final int? locationId;
  final String? memberName;
  final String? audience;
  final String? createdAt;

  const EmergencyRequestModel({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    required this.status,
    this.locationName,
    this.locationId,
    this.memberName,
    this.audience,
    this.createdAt,
  });

  factory EmergencyRequestModel.fromJson(Map<String, dynamic> json) {
    return EmergencyRequestModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.parse(json['id'].toString()),
      title: json['title'] as String? ?? 'Request',
      description: json['description'] as String?,
      type: json['type'] as String? ?? 'NORMAL',
      status: json['status'] as String? ?? 'PENDING',
      locationName: json['location'] != null
          ? json['location']['name'] as String?
          : null,
      locationId: json['location'] != null
          ? json['location']['id'] as int?
          : null,
      memberName: json['member'] != null
          ? json['member']['name'] as String?
          : null,
      audience: json['audience'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    type,
    status,
    locationName,
    memberName,
    createdAt,
  ];
}
