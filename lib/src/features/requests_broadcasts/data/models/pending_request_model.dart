import 'package:ntk_project/src/features/location/data/models/location_model.dart';

class PendingRequestModel {
  final int id;
  final String name;
  final String phone;
  final String role;
  final LocationModel? location;
  final String? createdAt;
  final String type; // 'USER' or 'MEMBER'
  final String? image;

  PendingRequestModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.location,
    this.createdAt,
    required this.type,
    this.image,
  });

  factory PendingRequestModel.fromJson(Map<String, dynamic> json) {
    // createdAt may come as epoch milliseconds (int) or ISO string
    String? createdAt;
    final raw = json['createdAt'];
    if (raw != null) {
      final asInt = int.tryParse(raw.toString());
      if (asInt != null) {
        createdAt = DateTime.fromMillisecondsSinceEpoch(
          asInt,
        ).toIso8601String();
      } else {
        createdAt = raw.toString();
      }
    }

    return PendingRequestModel(
      id: int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'MEMBER',
      location: json['location'] != null
          ? LocationModel.fromJson(json['location'])
          : null,
      createdAt: createdAt,
      type: json['type'] ?? 'MEMBER',
      image: json['image'] as String?,
    );
  }
}
