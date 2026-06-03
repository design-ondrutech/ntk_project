import 'package:equatable/equatable.dart';
import 'package:ntk_project/src/features/dashboard/data/models/dashboard_stats_model.dart';
import 'package:ntk_project/src/features/dashboard/data/models/recent_activity_model.dart';
import 'package:ntk_project/src/features/location/data/models/location_model.dart';

class DashboardState extends Equatable {
  final bool isLoading;
  final DashboardStatsModel? stats;
  final List<RecentActivityModel> recentActivity;
  final String? error;
  final LocationModel? globalLocation;

  const DashboardState({
    this.isLoading = false,
    this.stats,
    this.recentActivity = const [],
    this.error,
    this.globalLocation,
  });

  DashboardState copyWith({
    bool? isLoading,
    DashboardStatsModel? stats,
    List<RecentActivityModel>? recentActivity,
    String? error,
    bool clearError = false,
    LocationModel? globalLocation,
    bool clearGlobalLocation = false,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      stats: stats ?? this.stats,
      recentActivity: recentActivity ?? this.recentActivity,
      error: clearError ? null : (error ?? this.error),
      globalLocation: clearGlobalLocation ? null : (globalLocation ?? this.globalLocation),
    );
  }

  @override
  List<Object?> get props => [isLoading, stats, recentActivity, error, globalLocation];
}
