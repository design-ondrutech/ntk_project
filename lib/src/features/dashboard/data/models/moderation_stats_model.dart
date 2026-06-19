import 'package:equatable/equatable.dart';

class ModerationStatsModel extends Equatable {
  final int totalReported;
  final int pendingReviews;
  final int warningSent;
  final int deletedPosts;
  final int highPriority;

  const ModerationStatsModel({
    required this.totalReported,
    required this.pendingReviews,
    required this.warningSent,
    required this.deletedPosts,
    required this.highPriority,
  });

  factory ModerationStatsModel.fromJson(Map<String, dynamic> json) {
    return ModerationStatsModel(
      totalReported: json['totalReported'] ?? 0,
      pendingReviews: json['pendingReviews'] ?? 0,
      warningSent: json['warningSent'] ?? 0,
      deletedPosts: json['deletedPosts'] ?? 0,
      highPriority: json['highPriority'] ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        totalReported,
        pendingReviews,
        warningSent,
        deletedPosts,
        highPriority,
      ];
}
