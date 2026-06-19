import 'package:equatable/equatable.dart';
import 'package:ntk_project/src/features/community/data/models/community_message_model.dart';
import 'package:ntk_project/src/features/community/data/models/community_model.dart';
import 'package:ntk_project/src/features/community/data/models/post_model.dart';

class CommunityState extends Equatable {
  final bool isLoading;
  final bool isFeedLoading;
  final List<CommunityModel> communities;
  final List<PostModel> feedPosts;
  final List<PostModel> posts;
  final List<CommunityMessageModel> messages;
  final bool isSendingMessage;
  final int? selectedCommunityId;
  final String? error;
  final String? message;
  final bool isReportingPost;

  const CommunityState({
    this.isLoading = false,
    this.isFeedLoading = false,
    this.communities = const [],
    this.feedPosts = const [],
    this.posts = const [],
    this.messages = const [],
    this.isSendingMessage = false,
    this.selectedCommunityId,
    this.error,
    this.message,
    this.isReportingPost = false,
  });

  CommunityState copyWith({
    bool? isLoading,
    bool? isFeedLoading,
    List<CommunityModel>? communities,
    List<PostModel>? feedPosts,
    List<PostModel>? posts,
    List<CommunityMessageModel>? messages,
    bool? isSendingMessage,
    int? selectedCommunityId,
    String? error,
    String? message,
    bool? isReportingPost,
    bool clearError = false,
    bool clearMessage = false,
    bool clearSelectedCommunity = false,
  }) {
    return CommunityState(
      isLoading: isLoading ?? this.isLoading,
      isFeedLoading: isFeedLoading ?? this.isFeedLoading,
      communities: communities ?? this.communities,
      feedPosts: feedPosts ?? this.feedPosts,
      posts: posts ?? this.posts,
      messages: messages ?? this.messages,
      isSendingMessage: isSendingMessage ?? this.isSendingMessage,
      selectedCommunityId: clearSelectedCommunity
          ? null
          : (selectedCommunityId ?? this.selectedCommunityId),
      error: clearError ? null : (error ?? this.error),
      message: clearMessage ? null : (message ?? this.message),
      isReportingPost: isReportingPost ?? this.isReportingPost,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isFeedLoading,
    communities,
    feedPosts,
    posts,
    messages,
    isSendingMessage,
    selectedCommunityId,
    error,
    message,
    isReportingPost,
  ];
}
