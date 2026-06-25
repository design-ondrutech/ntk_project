import 'package:equatable/equatable.dart';
import 'package:ntk_project/src/features/location/data/models/location_model.dart';

class LocationAccessRequest extends Equatable {
  final int id;
  final int? userId;
  final String? currentRole;
  final String requestedRole;
  final String requestType;
  final String status;
  final String? reason;
  final String? rejectionReason;
  final String? createdAt;
  final RequestUser? user;
  final List<RequestedLocation> requestedLocations;

  const LocationAccessRequest({
    required this.id,
    this.userId,
    this.currentRole,
    required this.requestedRole,
    required this.requestType,
    required this.status,
    this.reason,
    this.rejectionReason,
    this.createdAt,
    this.user,
    this.requestedLocations = const [],
  });

  factory LocationAccessRequest.fromJson(Map<String, dynamic> json) {
    return LocationAccessRequest(
      id: json['id'] as int,
      userId: json['userId'] as int?,
      currentRole: json['currentRole'] as String?,
      requestedRole: json['requestedRole'] as String? ?? 'MEMBER',
      requestType: json['requestType'] as String? ?? 'ROLE_CHANGE',
      status: json['status'] as String? ?? 'PENDING',
      reason: json['reason'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      createdAt: json['createdAt'] as String?,
      user: json['user'] != null
          ? RequestUser.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      requestedLocations: (json['requestedLocations'] as List<dynamic>?)
              ?.map((e) => RequestedLocation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'currentRole': currentRole,
      'requestedRole': requestedRole,
      'requestType': requestType,
      'status': status,
      'reason': reason,
      'rejectionReason': rejectionReason,
      'createdAt': createdAt,
      'user': user?.toJson(),
      'requestedLocations': requestedLocations.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        currentRole,
        requestedRole,
        requestType,
        status,
        reason,
        rejectionReason,
        createdAt,
        user,
        requestedLocations,
      ];
}

class RequestUser extends Equatable {
  final int id;
  final String name;
  final String? phone;
  final LocationModel? location;

  const RequestUser({
    required this.id,
    required this.name,
    this.phone,
    this.location,
  });

  factory RequestUser.fromJson(Map<String, dynamic> json) {
    return RequestUser(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String?,
      location: json['location'] != null
          ? LocationModel.fromJson(json['location'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'location': location?.toJson(),
    };
  }

  @override
  List<Object?> get props => [id, name, phone, location];
}

class RequestedLocation extends Equatable {
  final int? id;
  final LocationModel? location;

  const RequestedLocation({this.id, this.location});

  factory RequestedLocation.fromJson(Map<String, dynamic> json) {
    return RequestedLocation(
      id: json['id'] as int?,
      location: json['location'] != null
          ? LocationModel.fromJson(json['location'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'location': location?.toJson(),
    };
  }

  @override
  List<Object?> get props => [id, location];
}
