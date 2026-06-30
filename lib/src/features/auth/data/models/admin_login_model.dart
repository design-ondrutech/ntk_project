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
  /// The type of the assigned location: DISTRICT | TALUK | AREA | STREET
  final String? locationType;
  final bool? isActive;
  final String? addedBy;
  final String? image;
  final String? token;
  final String? bloodGroup;
  final String? professionName;
  final String? dateOfBirth;

  const AdminLoginModel({
    required this.id,
    required this.name,
    this.surname,
    this.phone,
    required this.role,
    required this.approvalStatus,
    this.locationId,
    this.locationName,
    this.locationType,
    this.isActive,
    this.addedBy,
    this.image,
    this.token,
    this.bloodGroup,
    this.professionName,
    this.dateOfBirth,
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
      locationType: locationJson != null
          ? locationJson['type'] as String?
          : json['locationType'] as String?,
      isActive: json['isActive'] as bool?,
      addedBy: json['addedBy'] as String?,
      image: json['image'] as String?,
      token: token ?? json['token'] as String?,
      bloodGroup: json['bloodGroup'] as String?,
      professionName: json['profession'] is Map
          ? (json['profession']['name'] as String?)
          : (json['profession'] as String? ?? json['professionName'] as String?),
      dateOfBirth: json['dateOfBirth'] as String?,
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
      'locationType': locationType,
      'isActive': isActive,
      'addedBy': addedBy,
      'image': image,
      'token': token,
      'bloodGroup': bloodGroup,
      'professionName': professionName,
      'dateOfBirth': dateOfBirth,
    };
  }

  AdminLoginModel copyWith({
    int? id,
    String? name,
    String? surname,
    String? phone,
    String? role,
    String? approvalStatus,
    int? locationId,
    String? locationName,
    String? locationType,
    bool? isActive,
    String? addedBy,
    String? image,
    String? token,
    String? bloodGroup,
    String? professionName,
    String? dateOfBirth,
  }) {
    return AdminLoginModel(
      id: id ?? this.id,
      name: name ?? this.name,
      surname: surname ?? this.surname,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      locationId: locationId ?? this.locationId,
      locationName: locationName ?? this.locationName,
      locationType: locationType ?? this.locationType,
      isActive: isActive ?? this.isActive,
      addedBy: addedBy ?? this.addedBy,
      image: image ?? this.image,
      token: token ?? this.token,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      professionName: professionName ?? this.professionName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
    );
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
    locationType,
    isActive,
    addedBy,
    image,
    token,
    bloodGroup,
    professionName,
    dateOfBirth,
  ];
}
