import 'package:equatable/equatable.dart';
import 'package:ntk_project/src/features/community/data/models/comment_model.dart';
import 'package:ntk_project/src/features/community/data/models/community_model.dart';

class PostModel extends Equatable {
  final int id;
  final String title;
  final String content;
  final String? image;
  final String? category;
  final List<String> images;
  final List<String> documents;
  final List<String> attachments;
  final int likes;
  final String authorName;
  final String? authorRole;
  final CommunityModel? community;
  final Map<String, dynamic>? createdBy;
  final Map<String, dynamic>? location;
  final int commentCount;
  final String? createdAt;
  final List<CommentModel> comments;
  final bool isLiked;
  final int? createdById;
  final String? status;
  final int reportCount;
  final List<String> reportReasons;
  final int reportedUsersCount;
  final bool isHighPriority;
  final bool isUnderReview;
  final bool hasWarning;

  const PostModel({
    required this.id,
    required this.title,
    required this.content,
    this.image,
    this.category,
    this.images = const [],
    this.documents = const [],
    this.attachments = const [],
    required this.likes,
    required this.authorName,
    this.authorRole,
    this.community,
    this.createdBy,
    this.location,
    this.commentCount = 0,
    this.createdAt,
    this.comments = const [],
    this.isLiked = false,
    this.createdById,
    this.status,
    this.reportCount = 0,
    this.reportReasons = const [],
    this.reportedUsersCount = 0,
    this.isHighPriority = false,
    this.isUnderReview = false,
    this.hasWarning = false,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final commentsJson = json['comments'] as List? ?? [];

    // Parse nested createdBy for author details if present
    final createdBy = json['createdBy'] as Map<String, dynamic>?;
    final authorName =
        createdBy?['name'] as String? ??
        json['authorName'] as String? ??
        'Unknown';
    final authorRole =
        createdBy?['role'] as String? ?? json['authorRole'] as String?;

    return PostModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.parse(json['id'].toString()),
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      image: json['image'] as String?,
      category: json['category'] as String?,
      images: (json['images'] as List?)?.map((e) => e as String).toList() ?? [],
      documents: (json['documents'] as List?)?.map((e) => e as String).toList() ?? [],
      attachments: (json['attachments'] as List?)?.map((e) => e as String).toList() ?? [],
      likes: json['likes'] as int? ?? 0,
      authorName: authorName,
      authorRole: authorRole,
      community: json['community'] != null
          ? CommunityModel.fromJson(json['community'] as Map<String, dynamic>)
          : null,
      createdBy: createdBy,
      location: json['location'] as Map<String, dynamic>?,
      commentCount: json['commentCount'] as int? ?? commentsJson.length,
      createdAt: json['createdAt'] as String?,
      isLiked: json['isLiked'] as bool? ?? false,
      createdById: json['createdById'] == null
          ? (createdBy?['id'] == null
              ? null
              : (createdBy!['id'] is int
                  ? createdBy['id'] as int
                  : int.tryParse(createdBy['id'].toString())))
          : (json['createdById'] is int
              ? json['createdById'] as int
              : int.tryParse(json['createdById'].toString())),
      comments: commentsJson
          .map((c) => CommentModel.fromJson(c as Map<String, dynamic>))
          .toList(),
      status: json['status'] as String?,
      reportCount: json['reportCount'] as int? ?? 0,
      reportReasons: (json['reportReasons'] as List?)?.map((e) => e as String).toList() ?? [],
      reportedUsersCount: json['reportedUsersCount'] as int? ?? 0,
      isHighPriority: json['isHighPriority'] as bool? ?? false,
      isUnderReview: json['isUnderReview'] as bool? ?? false,
      hasWarning: json['hasWarning'] as bool? ?? false,
    );
  }

  PostModel copyWith({
    int? id,
    String? title,
    String? content,
    String? image,
    String? category,
    List<String>? images,
    List<String>? documents,
    List<String>? attachments,
    int? likes,
    String? authorName,
    String? authorRole,
    CommunityModel? community,
    Map<String, dynamic>? createdBy,
    Map<String, dynamic>? location,
    int? commentCount,
    String? createdAt,
    List<CommentModel>? comments,
    bool? isLiked,
    int? createdById,
    String? status,
    int? reportCount,
    List<String>? reportReasons,
    int? reportedUsersCount,
    bool? isHighPriority,
    bool? isUnderReview,
    bool? hasWarning,
  }) {
    return PostModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      image: image ?? this.image,
      category: category ?? this.category,
      images: images ?? this.images,
      documents: documents ?? this.documents,
      attachments: attachments ?? this.attachments,
      likes: likes ?? this.likes,
      authorName: authorName ?? this.authorName,
      authorRole: authorRole ?? this.authorRole,
      community: community ?? this.community,
      createdBy: createdBy ?? this.createdBy,
      location: location ?? this.location,
      commentCount: commentCount ?? this.commentCount,
      createdAt: createdAt ?? this.createdAt,
      comments: comments ?? this.comments,
      isLiked: isLiked ?? this.isLiked,
      createdById: createdById ?? this.createdById,
      status: status ?? this.status,
      reportCount: reportCount ?? this.reportCount,
      reportReasons: reportReasons ?? this.reportReasons,
      reportedUsersCount: reportedUsersCount ?? this.reportedUsersCount,
      isHighPriority: isHighPriority ?? this.isHighPriority,
      isUnderReview: isUnderReview ?? this.isUnderReview,
      hasWarning: hasWarning ?? this.hasWarning,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    content,
    image,
    category,
    images,
    documents,
    attachments,
    likes,
    authorName,
    authorRole,
    community,
    createdBy,
    location,
    commentCount,
    createdAt,
    comments,
    isLiked,
    createdById,
    status,
    reportCount,
    reportReasons,
    reportedUsersCount,
    isHighPriority,
    isUnderReview,
    hasWarning,
  ];
}
