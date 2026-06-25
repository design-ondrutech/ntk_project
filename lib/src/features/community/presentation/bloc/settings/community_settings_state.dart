import 'package:equatable/equatable.dart';
import 'package:ntk_project/src/features/community/data/models/community_settings_model.dart';

class CommunitySettingsState extends Equatable {
  final bool isLoading;
  final bool isUpdating;
  final CommunitySettingsModel? settings;
  final String? error;
  final String? successMessage;

  const CommunitySettingsState({
    this.isLoading = false,
    this.isUpdating = false,
    this.settings,
    this.error,
    this.successMessage,
  });

  CommunitySettingsState copyWith({
    bool? isLoading,
    bool? isUpdating,
    CommunitySettingsModel? settings,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return CommunitySettingsState(
      isLoading: isLoading ?? this.isLoading,
      isUpdating: isUpdating ?? this.isUpdating,
      settings: settings ?? this.settings,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [isLoading, isUpdating, settings, error, successMessage];
}
