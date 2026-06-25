import 'package:equatable/equatable.dart';

class AnnouncementModel extends Equatable {
  final int id;
  final String title;
  final String message;
  final bool isPinned;
  final String createdAt;
  final String? scheduledFor;

  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.message,
    this.isPinned = false,
    required this.createdAt,
    this.scheduledFor,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      title: json['title'] as String? ?? 'Untitled',
      message: json['message'] as String? ?? '',
      isPinned: json['isPinned'] as bool? ?? false,
      createdAt: json['createdAt'] as String? ?? '',
      scheduledFor: json['scheduledFor'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, title, message, isPinned, createdAt, scheduledFor];
}
