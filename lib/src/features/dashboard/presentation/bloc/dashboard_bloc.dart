import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/features/dashboard/data/models/recent_activity_model.dart';
import 'package:ntk_project/src/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:ntk_project/src/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:ntk_project/src/features/dashboard/presentation/bloc/dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardRepository _dashboardRepository;

  DashboardBloc(this._dashboardRepository) : super(const DashboardState()) {
    on<LoadDashboardStats>(_onLoadDashboardStats);
    on<UpdateGlobalLocation>(_onUpdateGlobalLocation);
  }

  Future<void> _onLoadDashboardStats(
    LoadDashboardStats event,
    Emitter<DashboardState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final stats = await _dashboardRepository.getDashboardStats(
        event.locationId,
      );
      // recentActivity failure must NOT crash the dashboard
      List<RecentActivityModel> activity = [];
      try {
        activity = await _dashboardRepository.getRecentActivity(
          locationId: event.locationId,
          limit: 10,
        );
      } catch (_) {
        // silently ignore — stats still show correctly
      }
      emit(
        state.copyWith(
          isLoading: false,
          stats: stats,
          recentActivity: activity,
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
}
