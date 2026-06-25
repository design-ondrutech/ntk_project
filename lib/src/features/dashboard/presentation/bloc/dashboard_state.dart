import 'package:equatable/equatable.dart';
import 'package:ntk_project/src/features/dashboard/data/models/dashboard_stats_model.dart';
import 'package:ntk_project/src/features/dashboard/data/models/recent_activity_model.dart';
import 'package:ntk_project/src/features/dashboard/data/models/moderation_stats_model.dart';
import 'package:ntk_project/src/features/location/data/models/location_model.dart';
import 'package:ntk_project/src/features/users/data/models/user_location_assignment.dart';

class DashboardState extends Equatable {
  final bool isLoading;
  final DashboardStatsModel? stats;
  final List<RecentActivityModel> recentActivity;
  final ModerationStatsModel? moderationStats;
  final String? error;
  final LocationModel? globalLocation;
  final List<UserLocationAssignment> assignedLocations;

  const DashboardState({
    this.isLoading = false,
    this.stats,
    this.recentActivity = const [],
    this.moderationStats,
    this.error,
    this.globalLocation,
    this.assignedLocations = const [],
  });

  DashboardState copyWith({
    bool? isLoading,
    DashboardStatsModel? stats,
    ModerationStatsModel? moderationStats,
    List<RecentActivityModel>? recentActivity,
    String? error,
    bool clearError = false,
    LocationModel? globalLocation,
    bool clearGlobalLocation = false,
    List<UserLocationAssignment>? assignedLocations,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      stats: stats ?? this.stats,
      moderationStats: moderationStats ?? this.moderationStats,
      recentActivity: recentActivity ?? this.recentActivity,
      error: clearError ? null : (error ?? this.error),
      globalLocation: clearGlobalLocation ? null : (globalLocation ?? this.globalLocation),
      assignedLocations: assignedLocations ?? this.assignedLocations,
    );
  }

  @override
  List<Object?> get props => [isLoading, stats, moderationStats, recentActivity, error, globalLocation, assignedLocations];
}
