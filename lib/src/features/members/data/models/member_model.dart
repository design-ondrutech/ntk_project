import 'package:equatable/equatable.dart';
import 'package:ntk_project/src/features/location/data/models/location_model.dart';

class MemberModel extends Equatable {
  final int id;
  final String name;
  final String? surname;
  final String? phone;
  final String? role;
  final String? approvalStatus;
  final LocationModel? location;
  final String? professionName;
  final String? bloodGroup;
  final String? addedBy;
  final bool isActive;
  final DateTime? createdAt;
  final String? dateOfBirth;
  final String? gender;

  const MemberModel({
    required this.id,
    required this.name,
    this.surname,
    this.phone,
    this.role,
    this.approvalStatus,
    this.location,
    this.professionName,
    this.bloodGroup,
    this.addedBy,
    this.isActive = true,
    this.createdAt,
    this.dateOfBirth,
    this.gender,
  });

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    return MemberModel(
      id: json['id'] != null
          ? (json['id'] is int
                ? json['id'] as int
                : int.parse(json['id'].toString()))
          : 0,
      name: json['name'] as String? ?? 'Unknown',
      surname: json['surname'] as String?,
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'Member',
      approvalStatus: json['approvalStatus'] as String?,
      location: json['location'] != null
          ? LocationModel.fromJson(json['location'])
          : null,
      professionName:
          json['profession'] as String? ?? (json['professionName'] as String?),
      bloodGroup: json['bloodGroup'] as String?,
      addedBy:
          json['addedBy'] as String? ?? (json['createdBy']?['name'] as String?),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: _parseDate(json['createdAt']),
      dateOfBirth: json['dateOfBirth'] as String?,
      gender: json['gender'] as String?,
    );
  }

  static DateTime? _parseDate(dynamic dateStr) {
    if (dateStr == null) return null;
    final str = dateStr.toString();
    final asInt = int.tryParse(str);
    if (asInt != null) {
      return DateTime.fromMillisecondsSinceEpoch(asInt);
    }
    return DateTime.tryParse(str);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'surname': surname,
      'phone': phone,
      'role': role,
      'approvalStatus': approvalStatus,
      'location': location?.toJson(),
      'professionName': professionName,
      'bloodGroup': bloodGroup,
      'addedBy': addedBy,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'dateOfBirth': dateOfBirth,
      'gender': gender,
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
    location,
    professionName,
    bloodGroup,
    addedBy,
    isActive,
    createdAt,
    dateOfBirth,
    gender,
  ];
}
