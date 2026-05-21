import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/features/community/data/models/post_model.dart';
import 'package:ntk_project/src/features/community/domain/repositories/community_repository.dart';
import 'community_event.dart';
import 'community_state.dart';

class CommunityBloc extends Bloc<CommunityEvent, CommunityState> {
  final CommunityRepository _repository;

  CommunityBloc(this._repository) : super(const CommunityState()) {
    on<FetchCommunityFeed>(_onFetchFeed);
    on<LikePost>(_onLikePost);
    on<AddComment>(_onAddComment);
    on<CreatePost>(_onCreatePost);
  }

  Future<void> _onFetchFeed(
    FetchCommunityFeed event,
    Emitter<CommunityState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final posts = await _repository.getCommunityFeed(
        locationId: event.locationId,
      );
      emit(state.copyWith(isLoading: false, posts: posts));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onLikePost(
    LikePost event,
    Emitter<CommunityState> emit,
  ) async {
    try {
      final result = await _repository.likePost(id: event.postId);
      final updatedPosts = state.posts.map((post) {
        if (post.id == event.postId) {
          return PostModel(
            id: post.id,
            content: post.content,
            image: post.image,
            authorName: post.authorName,
            authorRole: post.authorRole,
            likes: result,
            commentCount: post.commentCount,
            createdAt: post.createdAt,
            comments: post.comments,
          );
        }
        return post;
      }).toList();

      emit(state.copyWith(posts: updatedPosts, clearError: true));
    } catch (e) {
      emit(state.copyWith(error: 'லைக் செய்ய முடியவில்லை: $e', clearMessage: true));
    }
  }

  Future<void> _onAddComment(
    AddComment event,
    Emitter<CommunityState> emit,
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
          final newComments = [...post.comments, comment];
          return PostModel(
            id: post.id,
            content: post.content,
            image: post.image,
            authorName: post.authorName,
            authorRole: post.authorRole,
            likes: post.likes,
            commentCount: post.commentCount + 1,
            createdAt: post.createdAt,
            comments: newComments,
          );
        }
        return post;
      }).toList();

      emit(
        state.copyWith(
          posts: updatedPosts,
          message: 'கமெண்ட் சேர்க்கப்பட்டது',
          clearError: true,
        ),
      );
    } catch (e) {
      emit(state.copyWith(error: 'கமெண்ட் சேர்க்க முடியவில்லை: $e', clearMessage: true));
    }
  }

  Future<void> _onCreatePost(
    CreatePost event,
    Emitter<CommunityState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      await _repository.createPost(
        content: event.content,
        image: event.image,
        authorName: event.authorName,
        authorRole: event.authorRole,
        locationId: event.locationId,
      );

      final refreshed = await _repository.getCommunityFeed(
        locationId: event.locationId,
      );
      emit(
        state.copyWith(
          isLoading: false,
          posts: refreshed,
          message: 'போஸ்ட் வெற்றிகரமாக சேர்க்கப்பட்டது',
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: 'போஸ்ட் சேர்க்க முடியவில்லை: $e',
          clearMessage: true,
        ),
      );
    }
  }
}
