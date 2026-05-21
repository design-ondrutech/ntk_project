import 'package:equatable/equatable.dart';

class CommentModel extends Equatable {
  final int id;
  final String content;
  final String authorName;
  final String? authorRole;
  final String? createdAt;

  const CommentModel({
    required this.id,
    required this.content,
    required this.authorName,
    this.authorRole,
    this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.parse(json['id'].toString()),
      content: json['content'] as String? ?? '',
      authorName: json['authorName'] as String? ?? 'Unknown',
      authorRole: json['authorRole'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, content, authorName, createdAt];
}
