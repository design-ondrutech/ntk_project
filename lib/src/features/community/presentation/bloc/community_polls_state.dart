import 'package:equatable/equatable.dart';
import 'package:ntk_project/src/features/community/data/models/poll_model.dart';

class CommunityPollsState extends Equatable {
  final bool isLoading;
  final bool isVoting;
  final List<PollModel> polls;
  final String? error;
  final String? successMessage;

  const CommunityPollsState({
    this.isLoading = false,
    this.isVoting = false,
    this.polls = const [],
    this.error,
    this.successMessage,
  });

  CommunityPollsState copyWith({
    bool? isLoading,
    bool? isVoting,
    List<PollModel>? polls,
    String? error,
    bool clearError = false,
    String? successMessage,
    bool clearSuccess = false,
  }) {
    return CommunityPollsState(
      isLoading: isLoading ?? this.isLoading,
      isVoting: isVoting ?? this.isVoting,
      polls: polls ?? this.polls,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isVoting,
    polls,
    error,
    successMessage,
  ];
}
