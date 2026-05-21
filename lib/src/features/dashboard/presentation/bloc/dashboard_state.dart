import 'package:equatable/equatable.dart';
import 'package:ntk_project/src/features/dashboard/data/models/dashboard_stats_model.dart';

class DashboardState extends Equatable {
  final bool isLoading;
  final DashboardStatsModel? stats;
  final List<dynamic> recentActivity;
  final String? error;

  const DashboardState({
    this.isLoading = false,
    this.stats,
    this.recentActivity = const [],
    this.error,
  });

  DashboardState copyWith({
    bool? isLoading,
    DashboardStatsModel? stats,
    List<dynamic>? recentActivity,
    String? error,
    bool clearError = false,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      stats: stats ?? this.stats,
      recentActivity: recentActivity ?? this.recentActivity,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [isLoading, stats, recentActivity, error];
}
