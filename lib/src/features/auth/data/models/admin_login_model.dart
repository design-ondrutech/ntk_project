import 'package:equatable/equatable.dart';

class AdminLoginModel extends Equatable {
  final int id;
  final String name;
  final String role;
  final String approvalStatus;
  final int? locationId;
  final String? locationName;
  final String? token;

  const AdminLoginModel({
    required this.id,
    required this.name,
    required this.role,
    required this.approvalStatus,
    this.locationId,
    this.locationName,
    this.token,
  });


  factory AdminLoginModel.fromJson(Map<String, dynamic> json, {String? token}) {
    return AdminLoginModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      name: json['name'] as String,
      role: json['role'] as String,
      approvalStatus: json['approvalStatus'] as String? ?? 'APPROVED',
      locationId: json['location'] != null
          ? json['location']['id'] as int
          : json['locationId'] as int?,
      locationName: json['location'] != null
          ? json['location']['name'] as String?
          : json['locationName'] as String?,
      token: token ?? json['token'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'approvalStatus': approvalStatus,
      'locationId': locationId,
      'locationName': locationName,
      'token': token,
    };
  }

  @override
  List<Object?> get props => [id, name, role, approvalStatus, locationId, locationName, token];
}

