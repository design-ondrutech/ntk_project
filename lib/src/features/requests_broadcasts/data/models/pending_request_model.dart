import 'package:ntk_project/src/features/location/data/models/location_model.dart';

class PendingRequestModel {
  final int id;
  final String name;
  final String phone;
  final String role;
  final LocationModel? location;
  final String createdAt;
  final String type; // 'USER' or 'MEMBER'

  PendingRequestModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.location,
    required this.createdAt,
    required this.type,
  });

  factory PendingRequestModel.fromJson(Map<String, dynamic> json) {
    return PendingRequestModel(
      id: int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'MEMBER',
      location: json['location'] != null 
          ? LocationModel.fromJson(json['location']) 
          : null,
      createdAt: json['createdAt'] ?? '',
      type: json['type'] ?? 'MEMBER',
    );
  }
}
