import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/features/notifications/domain/repositories/notification_repository.dart';
import 'notification_settings_event.dart';
import 'notification_settings_state.dart';

class NotificationSettingsBloc
    extends Bloc<NotificationSettingsEvent, NotificationSettingsState> {
  final NotificationRepository _repository;

  NotificationSettingsBloc(this._repository)
    : super(const NotificationSettingsState()) {
    on<FetchNotificationSettings>(_onFetchSettings);
    on<ToggleNotificationSetting>(_onToggleSetting);
  }

  Future<void> _onFetchSettings(
    FetchNotificationSettings event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      final settings = await _repository.getNotificationSettings();
      emit(state.copyWith(isLoading: false, settings: settings));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onToggleSetting(
    ToggleNotificationSetting event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    try {
      final updatedSettings = Map<String, bool>.from(state.settings);
      updatedSettings[event.key] = event.value;

      // Optimistic update
      emit(state.copyWith(settings: updatedSettings));

      await _repository.updateNotificationSettings(updatedSettings);
    } catch (e) {
      // Revert on error
      emit(state.copyWith(error: 'Failed to update setting: $e'));
      add(FetchNotificationSettings());
    }
  }
}
