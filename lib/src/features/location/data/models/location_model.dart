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
    final idValue = json['id'];
    final id = idValue is int
        ? idValue
        : int.tryParse(idValue?.toString() ?? '') ?? 0;
    final parentIdValue = json['parentId'];
    final parentId = parentIdValue is int
        ? parentIdValue
        : int.tryParse(parentIdValue?.toString() ?? '');

    return LocationModel(
      id: id,
      name: json['name'] as String? ?? 'Unknown',
      type: json['type'] as String?,
      parentId: parentId,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'type': type, 'parentId': parentId};
  }

  @override
  List<Object?> get props => [id, name, type, parentId];
}
