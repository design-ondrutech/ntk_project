import 'package:equatable/equatable.dart';
import 'package:ntk_project/src/features/location/data/models/location_model.dart';

class UserLocationAssignment extends Equatable {
  final int id;
  final int userId;
  final int locationId;
  final bool isPrimary;
  final LocationModel? location;

  const UserLocationAssignment({
    required this.id,
    required this.userId,
    required this.locationId,
    this.isPrimary = false,
    this.location,
  });

  factory UserLocationAssignment.fromJson(Map<String, dynamic> json) {
    return UserLocationAssignment(
      id: json['id'] as int,
      userId: json['userId'] as int,
      locationId: json['locationId'] as int,
      isPrimary: (json['isPrimary'] == 1 || json['isPrimary'] == true),
      location: json['location'] != null
          ? LocationModel.fromJson(json['location'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'locationId': locationId,
      'isPrimary': isPrimary ? 1 : 0,
      'location': location?.toJson(),
    };
  }

  @override
  List<Object?> get props => [id, userId, locationId, isPrimary, location];
}
