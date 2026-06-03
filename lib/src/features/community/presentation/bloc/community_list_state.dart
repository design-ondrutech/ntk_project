import 'package:equatable/equatable.dart';
import 'package:ntk_project/src/features/community/data/models/community_model.dart';

class CommunityListState extends Equatable {
  final bool isLoading;
  final List<CommunityModel> communities;
  final String? error;
  final String? successMessage;

  const CommunityListState({
    this.isLoading = false,
    this.communities = const [],
    this.error,
    this.successMessage,
  });

  CommunityListState copyWith({
    bool? isLoading,
    List<CommunityModel>? communities,
    String? error,
    bool clearError = false,
    String? successMessage,
    bool clearSuccess = false,
  }) {
    return CommunityListState(
      isLoading: isLoading ?? this.isLoading,
      communities: communities ?? this.communities,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [isLoading, communities, error, successMessage];
}
