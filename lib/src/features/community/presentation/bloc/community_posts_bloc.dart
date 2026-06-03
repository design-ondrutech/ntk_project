import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/features/community/data/models/post_model.dart';
import 'package:ntk_project/src/features/community/domain/repositories/community_repository.dart';
import 'community_posts_event.dart';
import 'community_posts_state.dart';

class CommunityPostsBloc
    extends Bloc<CommunityPostsEvent, CommunityPostsState> {
  final CommunityRepository _repository;

  CommunityPostsBloc(this._repository) : super(const CommunityPostsState()) {
    on<FetchCommunityPostsList>(_onFetchCommunityPostsList);
    on<FetchFeedPosts>(_onFetchFeedPosts);
    on<CreateCommunityPostEvent>(_onCreateCommunityPost);
    on<LikePostEvent>(_onLikePost);
    on<AddCommentEvent>(_onAddComment);
    on<EditPostEvent>(_onEditPost);
    on<DeletePostEvent>(_onDeletePost);
  }

  Future<void> _onFetchCommunityPostsList(
    FetchCommunityPostsList event,
    Emitter<CommunityPostsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final posts = await _repository.getCommunityPosts(
        communityId: event.communityId,
      );
      emit(state.copyWith(isLoading: false, posts: posts));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onFetchFeedPosts(
    FetchFeedPosts event,
    Emitter<CommunityPostsState> emit,
  ) async {
    emit(state.copyWith(isFeedLoading: true, clearError: true));
    try {
      final posts = await _repository.getCommunityFeed(
        locationId: event.locationId,
      );
      emit(state.copyWith(isFeedLoading: false, feedPosts: posts));
    } catch (e) {
      emit(state.copyWith(isFeedLoading: false, error: e.toString()));
    }
  }

  Future<void> _onCreateCommunityPost(
    CreateCommunityPostEvent event,
    Emitter<CommunityPostsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final newPost = await _repository.createCommunityPost(
        title: event.title,
        content: event.content,
        category: event.category,
        authorName: event.authorName,
        authorRole: event.authorRole,
        locationId: event.locationId,
        images: event.image != null ? [event.image!] : null,
      );

      emit(
        state.copyWith(
          isLoading: false,
          posts: [newPost, ...state.posts],
          successMessage: 'Post created successfully',
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: 'Failed to create post: $e',
          clearSuccess: true,
        ),
      );
    }
  }

  Future<void> _onLikePost(
    LikePostEvent event,
    Emitter<CommunityPostsState> emit,
  ) async {
    try {
      final newLikes = await _repository.likePost(id: event.postId);

      final updatedPosts = state.posts.map((post) {
        return post.id == event.postId
            ? post.copyWith(likes: newLikes, isLiked: !post.isLiked)
            : post;
      }).toList();

      final updatedFeedPosts = state.feedPosts.map((post) {
        return post.id == event.postId
            ? post.copyWith(likes: newLikes, isLiked: !post.isLiked)
            : post;
      }).toList();

      emit(
        state.copyWith(
          posts: updatedPosts,
          feedPosts: updatedFeedPosts,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(error: 'Failed to like post: $e', clearSuccess: true),
      );
    }
  }

  Future<void> _onAddComment(
    AddCommentEvent event,
    Emitter<CommunityPostsState> emit,
  ) async {
    try {
      final comment = await _repository.addComment(
        postId: event.postId,
        content: event.content,
        authorName: event.authorName,
        authorRole: event.authorRole,
      );

      final updatedPosts = state.posts.map((post) {
        if (post.id == event.postId) {
          return post.copyWith(
            commentCount: post.commentCount + 1,
            comments: [...post.comments, comment],
          );
        }
        return post;
      }).toList();

      final updatedFeedPosts = state.feedPosts.map((post) {
        if (post.id == event.postId) {
          return post.copyWith(
            commentCount: post.commentCount + 1,
            comments: [...post.comments, comment],
          );
        }
        return post;
      }).toList();

      emit(
        state.copyWith(
          posts: updatedPosts,
          feedPosts: updatedFeedPosts,
          successMessage: 'Comment added',
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(error: 'Failed to add comment: $e', clearSuccess: true),
      );
    }
  }

  Future<void> _onEditPost(
    EditPostEvent event,
    Emitter<CommunityPostsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final edited = await _repository.editPost(
        id: event.postId,
        content: event.content,
        images: event.images,
      );

      PostModel merge(PostModel post) => post.id == event.postId
          ? post.copyWith(
              content: edited.content,
              images: edited.images.isNotEmpty ? edited.images : post.images,
            )
          : post;

      emit(
        state.copyWith(
          isLoading: false,
          posts: state.posts.map(merge).toList(),
          feedPosts: state.feedPosts.map(merge).toList(),
          successMessage: 'Post updated',
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: 'Failed to edit post: $e',
          clearSuccess: true,
        ),
      );
    }
  }

  Future<void> _onDeletePost(
    DeletePostEvent event,
    Emitter<CommunityPostsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final deleted = await _repository.deletePost(id: event.postId);
      if (!deleted) throw Exception('Delete failed');

      bool keep(PostModel post) => post.id != event.postId;
      emit(
        state.copyWith(
          isLoading: false,
          posts: state.posts.where(keep).toList(),
          feedPosts: state.feedPosts.where(keep).toList(),
          successMessage: 'Post deleted',
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: 'Failed to delete post: $e',
          clearSuccess: true,
        ),
      );
    }
  }
}
