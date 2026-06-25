import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/features/dashboard/data/models/recent_activity_model.dart';
import 'package:ntk_project/src/features/dashboard/data/models/dashboard_stats_model.dart';
import 'package:ntk_project/src/features/users/data/models/user_location_assignment.dart';
import 'package:ntk_project/src/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:ntk_project/src/features/users/domain/repositories/user_repository.dart';
import 'package:ntk_project/src/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:ntk_project/src/features/dashboard/presentation/bloc/dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardRepository _dashboardRepository;
  final UserRepository _userRepository;

  DashboardBloc(this._dashboardRepository, this._userRepository) : super(const DashboardState()) {
    on<LoadDashboardStats>(_onLoadDashboardStats);
    on<LoadModerationStats>(_onLoadModerationStats);
    on<UpdateGlobalLocation>(_onUpdateGlobalLocation);
    on<ResetDashboard>((event, emit) => emit(const DashboardState()));
  }

  Future<void> _onLoadDashboardStats(
    LoadDashboardStats event,
    Emitter<DashboardState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final statsFuture = _dashboardRepository.getDashboardStats(
        event.locationId,
        filterLocationId: event.filterLocationId,
      );

      final assignedLocationsFuture = (event.userId != null && state.assignedLocations.isEmpty)
          ? _userRepository.getUserAssignedLocations(userId: event.userId!)
          : Future.value(state.assignedLocations);

      final activityFuture = _dashboardRepository.getRecentActivity(
        locationId: event.locationId,
        limit: 10,
      ).catchError((_) => <RecentActivityModel>[]); // silently ignore — stats still show correctly

      final results = await Future.wait([statsFuture, assignedLocationsFuture, activityFuture]);

      final stats = results[0] as DashboardStatsModel;
      final assignedLocations = results[1] as List<UserLocationAssignment>;
      final activity = results[2] as List<RecentActivityModel>;

      activity.sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));

      emit(
        state.copyWith(
          isLoading: false,
          stats: stats,
          recentActivity: activity,
          assignedLocations: assignedLocations,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  void _onUpdateGlobalLocation(
    UpdateGlobalLocation event,
    Emitter<DashboardState> emit,
  ) {
    if (event.location == null) {
      emit(state.copyWith(clearGlobalLocation: true));
    } else {
      emit(state.copyWith(globalLocation: event.location));
    }
  }

  Future<void> _onLoadModerationStats(
    LoadModerationStats event,
    Emitter<DashboardState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final stats = await _dashboardRepository.getModerationDashboardStats(
        event.locationId,
      );
      emit(
        state.copyWith(
          isLoading: false,
          moderationStats: stats,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }
}
