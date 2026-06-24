import 'package:equatable/equatable.dart';

class ModerationStatsModel extends Equatable {
  final int totalReportedPosts;
  final int pendingReviews;
  final int warningSentCount;
  final int deletedPostsCount;
  final int highPriorityReportsCount;

  const ModerationStatsModel({
    required this.totalReportedPosts,
    required this.pendingReviews,
    required this.warningSentCount,
    required this.deletedPostsCount,
    required this.highPriorityReportsCount,
  });

  factory ModerationStatsModel.fromJson(Map<String, dynamic> json) {
    return ModerationStatsModel(
      totalReportedPosts: json['totalReportedPosts'] ?? 0,
      pendingReviews: json['pendingReviews'] ?? 0,
      warningSentCount: json['warningSentCount'] ?? 0,
      deletedPostsCount: json['deletedPostsCount'] ?? 0,
      highPriorityReportsCount: json['highPriorityReportsCount'] ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        totalReportedPosts,
        pendingReviews,
        warningSentCount,
        deletedPostsCount,
        highPriorityReportsCount,
      ];
}
