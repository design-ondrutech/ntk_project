import 'package:equatable/equatable.dart';

class BroadcastModel extends Equatable {
  final int id;
  final String title;
  final String message;
  final String? image;
  final int recipientCount;
  final String? createdAt;
  final String? locationName;
  final String? createdByName;
  final String? createdByRole;
  final String? content;
  final String? type;
  final String? updatedAt;
  final bool isActive;
  final int? createdById;

  const BroadcastModel({
    required this.id,
    required this.title,
    required this.message,
    this.image,
    this.recipientCount = 0,
    this.createdAt,
    this.locationName,
    this.createdByName,
    this.createdByRole,
    this.content,
    this.type,
    this.updatedAt,
    this.isActive = true,
    this.createdById,
  });

  factory BroadcastModel.fromJson(Map<String, dynamic> json) {
    final location = json['location'];
    final locationJson = location is Map<String, dynamic> ? location : null;
    final createdBy = json['createdBy'];
    final createdByJson = createdBy is Map<String, dynamic> ? createdBy : null;
    final idValue = json['id'];
    final recipientValue = json['recipientCount'];
    final isActiveValue = json['isActive'];

    final contentText = (json['content'] ?? json['message']) as String? ?? '';
    final typeText = (json['type'] ?? json['scope']) as String? ?? 'AREA';

    int? parsedCreatedById;
    if (createdByJson != null && createdByJson['id'] != null) {
      parsedCreatedById = createdByJson['id'] is int
          ? createdByJson['id'] as int
          : int.tryParse(createdByJson['id'].toString());
    }

    return BroadcastModel(
      id: idValue is int
          ? idValue
          : int.tryParse(idValue?.toString() ?? '') ?? 0,
      title: json['title'] as String? ?? 'Broadcast',
      message: contentText,
      image: json['image'] as String?,
      recipientCount: recipientValue is int
          ? recipientValue
          : int.tryParse(recipientValue?.toString() ?? '') ?? 0,
      createdAt: json['createdAt'] as String?,
      locationName: locationJson?['name'] as String?,
      createdByName: createdByJson?['name'] as String?,
      createdByRole: createdByJson?['role'] as String?,
      content: json['content'] as String?,
      type: typeText,
      updatedAt: json['updatedAt'] as String?,
      isActive: isActiveValue is bool
          ? isActiveValue
          : (isActiveValue?.toString().toLowerCase() != 'false'),
      createdById: parsedCreatedById,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    message,
    image,
    recipientCount,
    createdAt,
    locationName,
    createdByName,
    createdByRole,
    content,
    type,
    updatedAt,
    isActive,
    createdById,
  ];
}
