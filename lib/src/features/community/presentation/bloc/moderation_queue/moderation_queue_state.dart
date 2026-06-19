import 'package:equatable/equatable.dart';
import 'package:ntk_project/src/features/community/data/models/post_model.dart';

class ModerationQueueState extends Equatable {
  final bool isLoading;
  final bool isModerating;
  final List<PostModel> reportedPosts;
  final String? error;
  final String? message;

  const ModerationQueueState({
    this.isLoading = false,
    this.isModerating = false,
    this.reportedPosts = const [],
    this.error,
    this.message,
  });

  ModerationQueueState copyWith({
    bool? isLoading,
    bool? isModerating,
    List<PostModel>? reportedPosts,
    String? error,
    bool clearError = false,
    String? message,
    bool clearMessage = false,
  }) {
    return ModerationQueueState(
      isLoading: isLoading ?? this.isLoading,
      isModerating: isModerating ?? this.isModerating,
      reportedPosts: reportedPosts ?? this.reportedPosts,
      error: clearError ? null : (error ?? this.error),
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isModerating,
        reportedPosts,
        error,
        message,
      ];
}
