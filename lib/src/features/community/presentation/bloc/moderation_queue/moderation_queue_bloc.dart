import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/features/community/domain/repositories/community_repository.dart';
import 'package:ntk_project/src/features/community/data/community_socket_service.dart';
import 'dart:async';
import 'package:ntk_project/src/features/community/presentation/bloc/moderation_queue/moderation_queue_event.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/moderation_queue/moderation_queue_state.dart';

class ModerationQueueBloc extends Bloc<ModerationQueueEvent, ModerationQueueState> {
  final CommunityRepository _communityRepository;
  final CommunitySocketService _socketService;
  StreamSubscription? _reportResolvedSub;

  ModerationQueueBloc(this._communityRepository, this._socketService) : super(const ModerationQueueState()) {
    on<LoadReportedPosts>(_onLoadReportedPosts);
    on<ModeratePost>(_onModeratePost);
    on<ClearModerationMessage>((event, emit) => emit(state.copyWith(clearMessage: true)));
    on<ClearModerationError>((event, emit) => emit(state.copyWith(clearError: true)));
    on<RemovePostFromQueue>((event, emit) {
      final updatedPosts = state.reportedPosts.where((post) => post.id != event.postId).toList();
      emit(state.copyWith(reportedPosts: updatedPosts));
    });

    _reportResolvedSub = _socketService.onReportResolved.listen((data) {
      if (data['postId'] != null) {
        add(RemovePostFromQueue(postId: data['postId']));
      } else if (data['pollId'] != null) {
        add(RemovePostFromQueue(postId: data['pollId']));
      }
    });
  }

  @override
  Future<void> close() {
    _reportResolvedSub?.cancel();
    return super.close();
  }

  Future<void> _onLoadReportedPosts(
    LoadReportedPosts event,
    Emitter<ModerationQueueState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final posts = await _communityRepository.getReportedPostsList(
        locationId: event.locationId,
      );
      emit(state.copyWith(
        isLoading: false,
        reportedPosts: posts,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onModeratePost(
    ModeratePost event,
    Emitter<ModerationQueueState> emit,
  ) async {
    emit(state.copyWith(isModerating: true, clearError: true));
    try {
      await _communityRepository.moderatePost(
        postId: event.postId,
        action: event.action,
        warningMessage: event.warningMessage,
      );

      // Remove the post from the queue immediately upon success
      final updatedPosts = state.reportedPosts.where((post) => post.id != event.postId).toList();

      emit(state.copyWith(
        isModerating: false,
        reportedPosts: updatedPosts,
        message: 'Post moderated successfully.',
      ));
    } catch (e) {
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      var updatedPosts = state.reportedPosts;
      
      // If someone else already moderated this post, just remove it from the queue
      if (errorMsg.toLowerCase().contains('already resolved')) {
        updatedPosts = state.reportedPosts.where((post) => post.id != event.postId).toList();
      }
      
      emit(state.copyWith(
        isModerating: false, 
        error: errorMsg,
        reportedPosts: updatedPosts,
      ));
    }
  }
}
