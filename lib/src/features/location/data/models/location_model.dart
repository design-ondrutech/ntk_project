import 'package:equatable/equatable.dart';

class LocationModel extends Equatable {
  final int id;
  final String name;
  final String? type;
  final int? parentId;

  const LocationModel({
    required this.id,
    required this.name,
    this.type,
    this.parentId,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'] as int,
      name: json['name'] as String,
      type: json['type'] as String?,
      parentId: json['parentId'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'parentId': parentId,
    };
  }

  @override
  List<Object?> get props => [id, name, type, parentId];
}
