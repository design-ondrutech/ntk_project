import 'package:equatable/equatable.dart';

class NotificationSettingsState extends Equatable {
  final bool isLoading;
  final Map<String, bool> settings;
  final String? error;

  const NotificationSettingsState({
    this.isLoading = false,
    this.settings = const {},
    this.error,
  });

  NotificationSettingsState copyWith({
    bool? isLoading,
    Map<String, bool>? settings,
    String? error,
  }) {
    return NotificationSettingsState(
      isLoading: isLoading ?? this.isLoading,
      settings: settings ?? this.settings,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [isLoading, settings, error];
}
