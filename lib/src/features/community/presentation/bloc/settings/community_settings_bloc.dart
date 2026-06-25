import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/features/community/domain/repositories/community_repository.dart';
import 'community_settings_event.dart';
import 'community_settings_state.dart';

class CommunitySettingsBloc extends Bloc<CommunitySettingsEvent, CommunitySettingsState> {
  final CommunityRepository _repository;

  CommunitySettingsBloc(this._repository) : super(const CommunitySettingsState()) {
    on<FetchCommunitySettingsEvent>(_onFetchCommunitySettings);
    on<UpdateCommunitySettingsEvent>(_onUpdateCommunitySettings);
  }

  Future<void> _onFetchCommunitySettings(
    FetchCommunitySettingsEvent event,
    Emitter<CommunitySettingsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final settings = await _repository.getCommunitySettings(communityId: event.communityId);
      emit(state.copyWith(isLoading: false, settings: settings));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: 'Failed to fetch settings: $e'));
    }
  }

  Future<void> _onUpdateCommunitySettings(
    UpdateCommunitySettingsEvent event,
    Emitter<CommunitySettingsState> emit,
  ) async {
    emit(state.copyWith(isUpdating: true, clearError: true, clearSuccess: true));
    try {
      final updatedSettings = await _repository.updateCommunitySettings(
        communityId: event.communityId,
        settings: event.settings,
      );
      emit(state.copyWith(
        isUpdating: false,
        settings: updatedSettings,
        successMessage: 'Settings updated successfully',
      ));
    } catch (e) {
      emit(state.copyWith(
        isUpdating: false,
        error: 'Failed to update settings: $e',
      ));
    }
  }
}
