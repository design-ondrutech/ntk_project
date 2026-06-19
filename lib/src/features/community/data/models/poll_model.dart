import 'package:equatable/equatable.dart';

class PollOptionModel extends Equatable {
  final int id;
  final int? pollId;
  final String text;
  final int votesCount;

  const PollOptionModel({
    required this.id,
    this.pollId,
    required this.text,
    this.votesCount = 0,
  });

  factory PollOptionModel.fromJson(Map<String, dynamic> json) {
    return PollOptionModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      pollId: json['pollId'] is int
          ? json['pollId'] as int
          : int.tryParse(json['pollId']?.toString() ?? ''),
      text: json['text'] as String? ?? '',
      votesCount: json['votesCount'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, pollId, text, votesCount];
}

class PollModel extends Equatable {
  final int id;
  final String question;
  final int? locationId;
  final Map<String, dynamic>? location;
  final int? communityId;
  final String? expiresAt;
  final String? createdAt;
  final List<PollOptionModel> options;
  final int votesCount;
  final int? userVoteOptionId;
  final Map<String, dynamic>? createdBy;
  final Map<String, dynamic>? member;
  final int likes;
  final int commentCount;
  final bool isLiked;

  const PollModel({
    required this.id,
    required this.question,
    this.locationId,
    this.location,
    this.communityId,
    this.expiresAt,
    this.createdAt,
    this.options = const [],
    this.votesCount = 0,
    this.userVoteOptionId,
    this.createdBy,
    this.member,
    this.likes = 0,
    this.commentCount = 0,
    this.isLiked = false,
  });

  factory PollModel.fromJson(Map<String, dynamic> json) {
    final optionsJson = json['options'] as List? ?? [];

    return PollModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      question: json['question'] as String? ?? '',
      locationId: json['locationId'] is int
          ? json['locationId'] as int
          : int.tryParse(json['locationId']?.toString() ?? ''),
      location: json['location'] as Map<String, dynamic>?,
      communityId: json['communityId'] is int
          ? json['communityId'] as int
          : int.tryParse(json['communityId']?.toString() ?? ''),
      expiresAt: json['expiresAt'] as String?,
      createdAt: json['createdAt'] as String?,
      options: optionsJson
          .map((o) => PollOptionModel.fromJson(o as Map<String, dynamic>))
          .toList(),
      votesCount: json['votesCount'] as int? ?? 0,
      userVoteOptionId: json['userVoteOptionId'] is int
          ? json['userVoteOptionId'] as int
          : int.tryParse(json['userVoteOptionId']?.toString() ?? ''),
      createdBy: json['createdBy'] as Map<String, dynamic>?,
      member: json['member'] as Map<String, dynamic>?,
      likes: json['likes'] as int? ?? 0,
      commentCount: json['commentCount'] as int? ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
    );
  }

  PollModel copyWith({
    int? id,
    String? question,
    int? locationId,
    Map<String, dynamic>? location,
    int? communityId,
    String? expiresAt,
    String? createdAt,
    List<PollOptionModel>? options,
    int? votesCount,
    int? userVoteOptionId,
    Map<String, dynamic>? createdBy,
    Map<String, dynamic>? member,
    int? likes,
    int? commentCount,
    bool? isLiked,
  }) {
    return PollModel(
      id: id ?? this.id,
      question: question ?? this.question,
      locationId: locationId ?? this.locationId,
      location: location ?? this.location,
      communityId: communityId ?? this.communityId,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      options: options ?? this.options,
      votesCount: votesCount ?? this.votesCount,
      userVoteOptionId: userVoteOptionId ?? this.userVoteOptionId,
      createdBy: createdBy ?? this.createdBy,
      member: member ?? this.member,
      likes: likes ?? this.likes,
      commentCount: commentCount ?? this.commentCount,
      isLiked: isLiked ?? this.isLiked,
    );
  }

  @override
  List<Object?> get props => [
    id,
    question,
    locationId,
    location,
    communityId,
    expiresAt,
    createdAt,
    options,
    votesCount,
    userVoteOptionId,
    createdBy,
    member,
    likes,
    commentCount,
    isLiked,
  ];
}
