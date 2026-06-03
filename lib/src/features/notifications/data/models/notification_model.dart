import 'package:equatable/equatable.dart';

class NotificationModel extends Equatable {
  final int id;
  final String title;
  final String message;
  final String? type;
  final String? time;
  final String? createdAt;
  final bool isRead;
  final int? relatedEntityId;
  final String? locationName;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    this.type,
    this.time,
    this.createdAt,
    this.isRead = false,
    this.relatedEntityId,
    this.locationName,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      type: json['type'] as String?,
      time: json['time'] as String?,
      createdAt: json['createdAt'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      relatedEntityId: json['relatedEntityId'] is int
          ? json['relatedEntityId'] as int
          : int.tryParse(json['relatedEntityId']?.toString() ?? ''),
      locationName:
          json['locationName'] as String? ??
          json['location']?['name'] as String?,
    );
  }

  NotificationModel copyWith({
    int? id,
    String? title,
    String? message,
    String? type,
    String? time,
    String? createdAt,
    bool? isRead,
    int? relatedEntityId,
    String? locationName,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      time: time ?? this.time,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      relatedEntityId: relatedEntityId ?? this.relatedEntityId,
      locationName: locationName ?? this.locationName,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    message,
    type,
    time,
    createdAt,
    isRead,
    relatedEntityId,
    locationName,
  ];
}
