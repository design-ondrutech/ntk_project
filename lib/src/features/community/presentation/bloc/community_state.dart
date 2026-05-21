import 'package:equatable/equatable.dart';
import 'package:ntk_project/src/features/community/data/models/post_model.dart';

class CommunityState extends Equatable {
  final bool isLoading;
  final List<PostModel> posts;
  final String? error;
  final String? message;

  const CommunityState({
    this.isLoading = false,
    this.posts = const [],
    this.error,
    this.message,
  });

  CommunityState copyWith({
    bool? isLoading,
    List<PostModel>? posts,
    String? error,
    String? message,
    bool clearError = false,
    bool clearMessage = false,
  }) {
    return CommunityState(
      isLoading: isLoading ?? this.isLoading,
      posts: posts ?? this.posts,
      error: clearError ? null : (error ?? this.error),
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [isLoading, posts, error, message];
}
