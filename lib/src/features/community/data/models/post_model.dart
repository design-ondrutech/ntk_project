import 'package:equatable/equatable.dart';
import 'package:ntk_project/src/features/community/data/models/comment_model.dart';

class PostModel extends Equatable {
  final int id;
  final String content;
  final String? image;
  final String authorName;
  final String? authorRole;
  final int likes;
  final int commentCount;
  final String? createdAt;
  final List<CommentModel> comments;

  const PostModel({
    required this.id,
    required this.content,
    this.image,
    required this.authorName,
    this.authorRole,
    this.likes = 0,
    this.commentCount = 0,
    this.createdAt,
    this.comments = const [],
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final commentsJson = json['comments'] as List? ?? [];
    return PostModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.parse(json['id'].toString()),
      content: json['content'] as String? ?? '',
      image: json['image'] as String?,
      authorName: json['authorName'] as String? ?? 'Unknown',
      authorRole: json['authorRole'] as String?,
      likes: json['likes'] as int? ?? 0,
      commentCount: json['commentCount'] as int? ?? commentsJson.length,
      createdAt: json['createdAt'] as String?,
      comments: commentsJson
          .map((c) => CommentModel.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [id, content, authorName, likes, commentCount, createdAt];
}
