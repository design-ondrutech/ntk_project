import 'package:equatable/equatable.dart';

class CommentModel extends Equatable {
  final int id;
  final String content;
  final String authorName;
  final String? authorRole;
  final String? createdAt;
  final Map<String, dynamic>? createdBy;
  final int? parentId;
  final List<CommentModel> replies;
  final int likesCount;
  final bool isLiked;

  const CommentModel({
    required this.id,
    required this.content,
    required this.authorName,
    this.authorRole,
    this.createdAt,
    this.createdBy,
    this.parentId,
    this.replies = const [],
    this.likesCount = 0,
    this.isLiked = false,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    final repliesJson = json['replies'] as List? ?? [];
    return CommentModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.parse(json['id'].toString()),
      content: json['content'] as String? ?? '',
      authorName: json['authorName'] as String? ?? 'Unknown',
      authorRole: json['authorRole'] as String?,
      createdAt: json['createdAt'] as String?,
      createdBy: json['createdBy'] as Map<String, dynamic>?,
      parentId: json['parentId'] is int
          ? json['parentId'] as int
          : (json['parentId'] == null ? null : int.tryParse(json['parentId'].toString())),
      replies: repliesJson
          .map((r) => CommentModel.fromJson(r as Map<String, dynamic>))
          .toList(),
      likesCount: json['likesCount'] as int? ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
    );
  }

  CommentModel copyWith({
    int? id,
    String? content,
    String? authorName,
    String? authorRole,
    String? createdAt,
    Map<String, dynamic>? createdBy,
    int? parentId,
    List<CommentModel>? replies,
    int? likesCount,
    bool? isLiked,
  }) {
    return CommentModel(
      id: id ?? this.id,
      content: content ?? this.content,
      authorName: authorName ?? this.authorName,
      authorRole: authorRole ?? this.authorRole,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      parentId: parentId ?? this.parentId,
      replies: replies ?? this.replies,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
    );
  }

  @override
  List<Object?> get props => [
        id,
        content,
        authorName,
        authorRole,
        createdAt,
        createdBy,
        parentId,
        replies,
        likesCount,
        isLiked,
      ];
}
