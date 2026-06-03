import 'package:equatable/equatable.dart';

class AdminLoginModel extends Equatable {
  final int id;
  final String name;
  final String? surname;
  final String? phone;
  final String role;
  final String approvalStatus;
  final int? locationId;
  final String? locationName;
  final bool? isActive;
  final String? addedBy;
  final String? image;
  final String? token;

  const AdminLoginModel({
    required this.id,
    required this.name,
    this.surname,
    this.phone,
    required this.role,
    required this.approvalStatus,
    this.locationId,
    this.locationName,
    this.isActive,
    this.addedBy,
    this.image,
    this.token,
  });

  factory AdminLoginModel.fromJson(Map<String, dynamic> json, {String? token}) {
    final location = json['location'];
    final locationJson = location is Map<String, dynamic> ? location : null;

    return AdminLoginModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.parse(json['id'].toString()),
      name: json['name'] as String? ?? 'User',
      surname: json['surname'] as String?,
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'MEMBER',
      approvalStatus: json['approvalStatus'] as String? ?? 'APPROVED',
      locationId: locationJson != null
          ? locationJson['id'] as int?
          : json['locationId'] as int?,
      locationName: locationJson != null
          ? locationJson['name'] as String?
          : json['locationName'] as String?,
      isActive: json['isActive'] as bool?,
      addedBy: json['addedBy'] as String?,
      image: json['image'] as String?,
      token: token ?? json['token'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'surname': surname,
      'phone': phone,
      'role': role,
      'approvalStatus': approvalStatus,
      'locationId': locationId,
      'locationName': locationName,
      'isActive': isActive,
      'addedBy': addedBy,
      'image': image,
      'token': token,
    };
  }

  @override
  List<Object?> get props => [
    id,
    name,
    surname,
    phone,
    role,
    approvalStatus,
    locationId,
    locationName,
    isActive,
    addedBy,
    image,
    token,
  ];
}
