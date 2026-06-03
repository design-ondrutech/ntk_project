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
      id: json['id'] as int? ?? 0,
      pollId: json['pollId'] as int?,
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
  });

  factory PollModel.fromJson(Map<String, dynamic> json) {
    final optionsJson = json['options'] as List? ?? [];

    return PollModel(
      id: json['id'] as int? ?? 0,
      question: json['question'] as String? ?? '',
      locationId: json['locationId'] as int?,
      location: json['location'] as Map<String, dynamic>?,
      communityId: json['communityId'] as int?,
      expiresAt: json['expiresAt'] as String?,
      createdAt: json['createdAt'] as String?,
      options: optionsJson
          .map((o) => PollOptionModel.fromJson(o as Map<String, dynamic>))
          .toList(),
      votesCount: json['votesCount'] as int? ?? 0,
      userVoteOptionId: json['userVoteOptionId'] as int?,
      createdBy: json['createdBy'] as Map<String, dynamic>?,
      member: json['member'] as Map<String, dynamic>?,
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
  ];
}
