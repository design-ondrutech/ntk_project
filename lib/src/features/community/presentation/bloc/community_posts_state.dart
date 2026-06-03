import 'package:equatable/equatable.dart';
import 'package:ntk_project/src/features/community/data/models/post_model.dart';

class CommunityPostsState extends Equatable {
  final bool isLoading;
  final bool isFeedLoading;
  final List<PostModel> posts;
  final List<PostModel> feedPosts;
  final String? error;
  final String? successMessage;

  const CommunityPostsState({
    this.isLoading = false,
    this.isFeedLoading = false,
    this.posts = const [],
    this.feedPosts = const [],
    this.error,
    this.successMessage,
  });

  CommunityPostsState copyWith({
    bool? isLoading,
    bool? isFeedLoading,
    List<PostModel>? posts,
    List<PostModel>? feedPosts,
    String? error,
    bool clearError = false,
    String? successMessage,
    bool clearSuccess = false,
  }) {
    return CommunityPostsState(
      isLoading: isLoading ?? this.isLoading,
      isFeedLoading: isFeedLoading ?? this.isFeedLoading,
      posts: posts ?? this.posts,
      feedPosts: feedPosts ?? this.feedPosts,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isFeedLoading,
    posts,
    feedPosts,
    error,
    successMessage,
  ];
}
