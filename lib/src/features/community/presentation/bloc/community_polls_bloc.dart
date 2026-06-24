import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/features/community/domain/repositories/community_repository.dart';
import 'package:ntk_project/src/features/community/data/models/poll_model.dart';
import 'package:ntk_project/src/features/community/data/models/comment_model.dart';
import 'package:ntk_project/src/features/community/data/community_socket_service.dart';
import 'dart:async';
import 'community_polls_event.dart';
import 'community_polls_state.dart';

class CommunityPollsBloc
    extends Bloc<CommunityPollsEvent, CommunityPollsState> {
  final CommunityRepository _repository;
  final CommunitySocketService _socketService;
  StreamSubscription? _pollDeletedSub;
  final Set<int> _processingPollCommentLikes = {};

  CommunityPollsBloc(this._repository, this._socketService) : super(const CommunityPollsState()) {
    on<FetchPollsEvent>(_onFetchPolls);
    on<CreatePollEvent>(_onCreatePoll);
    on<VoteInPollEvent>(_onVoteInPoll);
    on<LikePollEvent>(_onLikePoll);
    on<AddPollCommentEvent>(_onAddPollComment);
    on<LikePollCommentEvent>(_onLikePollComment);
    on<FetchPollDetailsEvent>(_onFetchPollDetails);
    on<ClearPollsMessage>(
      (event, emit) => emit(state.copyWith(clearSuccess: true)),
    );
    on<ClearPollsError>(
      (event, emit) => emit(state.copyWith(clearError: true)),
    );
    on<DeletePollEvent>((event, emit) {
      final updatedPolls = state.polls.where((p) => p.id != event.pollId).toList();
      emit(state.copyWith(polls: updatedPolls));
    });

    _pollDeletedSub = _socketService.onPollDeletedGlobal.listen((data) {
      if (data['pollId'] != null) {
        add(DeletePollEvent(pollId: data['pollId']));
      }
    });
  }

  @override
  Future<void> close() {
    _pollDeletedSub?.cancel();
    return super.close();
  }

  Future<void> _onFetchPolls(
    FetchPollsEvent event,
    Emitter<CommunityPollsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final polls = await _repository.getPollList(
        communityId: event.communityId,
        locationId: event.locationId,
      );
      emit(state.copyWith(isLoading: false, polls: polls));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onCreatePoll(
    CreatePollEvent event,
    Emitter<CommunityPollsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final newPoll = await _repository.createPoll(
        question: event.question,
        options: event.options,
        durationDays: event.durationDays,
        locationId: event.locationId,
        communityId: event.communityId,
      );

      emit(
        state.copyWith(
          isLoading: false,
          polls: [newPoll, ...state.polls],
          successMessage: 'Poll created successfully',
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: 'Failed to create poll: $e',
          clearSuccess: true,
        ),
      );
    }
  }

  Future<void> _onVoteInPoll(
    VoteInPollEvent event,
    Emitter<CommunityPollsState> emit,
  ) async {
    emit(state.copyWith(isVoting: true, clearError: true));
    try {
      await _repository.voteInPoll(
        pollId: event.pollId,
        optionId: event.optionId,
      );

      final updatedPollsList = state.polls.map((p) {
        if (p.id == event.pollId) {
          final updatedOptions = p.options.map((o) {
            if (o.id == event.optionId) {
              return PollOptionModel(
                id: o.id,
                pollId: o.pollId,
                text: o.text,
                votesCount: o.votesCount + 1,
              );
            }
            return o;
          }).toList();
          return PollModel(
            id: p.id,
            question: p.question,
            locationId: p.locationId,
            location: p.location,
            communityId: p.communityId,
            expiresAt: p.expiresAt,
            createdAt: p.createdAt,
            options: updatedOptions,
            votesCount: p.votesCount + 1,
            userVoteOptionId: event.optionId,
            createdBy: p.createdBy,
            member: p.member,
          );
        }
        return p;
      }).toList();

      emit(
        state.copyWith(
          isVoting: false,
          polls: updatedPollsList,
          successMessage: 'Vote cast successfully',
          clearError: true,
        ),
      );
    } catch (e) {
      final cleanMessage = e.toString().replaceAll('Exception: ', '');
      emit(
        state.copyWith(
          isVoting: false,
          error: cleanMessage,
          clearSuccess: true,
        ),
      );
    }
  }

  Future<void> _onLikePoll(
    LikePollEvent event,
    Emitter<CommunityPollsState> emit,
  ) async {
    // Optimistic UI update
    final updatedPolls = state.polls.map((p) {
      if (p.id == event.pollId) {
        final isLiked = p.isLiked;
        return p.copyWith(
          isLiked: !isLiked,
          likes: isLiked ? (p.likes > 0 ? p.likes - 1 : 0) : p.likes + 1,
        );
      }
      return p;
    }).toList();
    emit(state.copyWith(polls: updatedPolls));

    try {
      final result = await _repository.likePoll(pollId: event.pollId);
      final likesCount = result['likesCount'] as int? ?? 0;
      final isLiked = result['isLiked'] as bool? ?? false;

      final syncedPolls = state.polls.map((p) {
        if (p.id == event.pollId) {
          return p.copyWith(
            likes: likesCount,
            isLiked: isLiked,
          );
        }
        return p;
      }).toList();
      emit(state.copyWith(polls: syncedPolls));
    } catch (e) {
      // Revert on error
      final revertedPolls = state.polls.map((p) {
        if (p.id == event.pollId) {
          final isLiked = !p.isLiked; // The optimistic state
          return p.copyWith(
            isLiked: !isLiked,
            likes: isLiked ? (p.likes > 0 ? p.likes - 1 : 0) : p.likes + 1,
          );
        }
        return p;
      }).toList();
      emit(state.copyWith(polls: revertedPolls, error: e.toString(), clearSuccess: true));
    }
  }

  Future<void> _onAddPollComment(
    AddPollCommentEvent event,
    Emitter<CommunityPollsState> emit,
  ) async {
    final updatedPollsOptimistic = state.polls.map((p) {
      if (p.id == event.pollId) {
        return p.copyWith(commentCount: p.commentCount + 1);
      }
      return p;
    }).toList();
    emit(state.copyWith(polls: updatedPollsOptimistic));

    try {
      final comment = await _repository.addPollComment(
        pollId: event.pollId,
        content: event.content,
        authorName: event.authorName,
        authorRole: event.authorRole,
        parentId: event.parentId,
      );

      final updatedPolls = state.polls.map((poll) {
        if (poll.id == event.pollId) {
          final newComments = event.parentId == null
              ? [...poll.comments, comment]
              : _addCommentToTree(poll.comments, comment, event.parentId!);
          return poll.copyWith(
            comments: newComments,
          );
        }
        return poll;
      }).toList();

      emit(state.copyWith(polls: updatedPolls, clearError: true));
    } catch (e) {
      final revertedPolls = state.polls.map((p) {
        if (p.id == event.pollId) {
          return p.copyWith(commentCount: p.commentCount > 0 ? p.commentCount - 1 : 0);
        }
        return p;
      }).toList();
      emit(state.copyWith(polls: revertedPolls, error: e.toString(), clearSuccess: true));
    }
  }

  Future<void> _onFetchPollDetails(
    FetchPollDetailsEvent event,
    Emitter<CommunityPollsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final detailedPoll = await _repository.getPollDetails(id: event.pollId);
      final listContainsPoll = state.polls.any((p) => p.id == event.pollId);
      final updatedList = listContainsPoll
          ? state.polls.map((p) => p.id == event.pollId ? detailedPoll : p).toList()
          : [...state.polls, detailedPoll];
      emit(state.copyWith(isLoading: false, polls: updatedList));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onLikePollComment(
    LikePollCommentEvent event,
    Emitter<CommunityPollsState> emit,
  ) async {
    if (_processingPollCommentLikes.contains(event.pollCommentId)) return;
    _processingPollCommentLikes.add(event.pollCommentId);

    try {
      CommentModel? targetComment;
      for (final poll in state.polls) {
        targetComment = _findCommentInTree(poll.comments, event.pollCommentId);
        if (targetComment != null) break;
      }

      if (targetComment == null) return;

      final wasLiked = targetComment.isLiked;

      // 1. Optimistic Update
      final updatedPolls = state.polls.map((poll) {
        return poll.copyWith(
          comments: _updateCommentLikeInTree(
            comments: poll.comments,
            targetCommentId: event.pollCommentId,
            isLikedUpdater: (c) => !c.isLiked,
            likesCount: (c) => c.isLiked ? (c.likesCount - 1).clamp(0, 999999) : c.likesCount + 1,
          ),
        );
      }).toList();

      emit(state.copyWith(polls: updatedPolls, clearError: true));

      try {
        // 2. Call API
        final result = await _repository.likePollComment(pollCommentId: event.pollCommentId);
        final isLikedFromServer = result['isLiked'] as bool;
        final likesCountFromServer = result['likesCount'] as int;

        // 3. Sync with server values
        final syncedPolls = state.polls.map((poll) {
          return poll.copyWith(
            comments: _updateCommentLikeInTree(
              comments: poll.comments,
              targetCommentId: event.pollCommentId,
              isLikedUpdater: (_) => isLikedFromServer,
              likesCount: (_) => likesCountFromServer,
            ),
          );
        }).toList();

        emit(state.copyWith(polls: syncedPolls, clearError: true));
      } catch (e) {
        // 4. Rollback on failure
        final rollbackPolls = state.polls.map((poll) {
          return poll.copyWith(
            comments: _updateCommentLikeInTree(
              comments: poll.comments,
              targetCommentId: event.pollCommentId,
              isLikedUpdater: (_) => wasLiked,
              likesCount: (_) => targetComment!.likesCount,
            ),
          );
        }).toList();

        emit(state.copyWith(
          polls: rollbackPolls,
          error: 'லைக் செய்ய முடியவில்லை: $e',
          clearSuccess: true,
        ));
      }
    } finally {
      _processingPollCommentLikes.remove(event.pollCommentId);
    }
  }

  List<CommentModel> _addCommentToTree(List<CommentModel> comments, CommentModel newComment, int parentId) {
    return comments.map((comment) {
      if (comment.id == parentId) {
        return comment.copyWith(
          replies: [...comment.replies, newComment],
        );
      } else if (comment.replies.isNotEmpty) {
        return comment.copyWith(
          replies: _addCommentToTree(comment.replies, newComment, parentId),
        );
      }
      return comment;
    }).toList();
  }

  CommentModel? _findCommentInTree(List<CommentModel> comments, int commentId) {
    for (final comment in comments) {
      if (comment.id == commentId) return comment;
      if (comment.replies.isNotEmpty) {
        final nested = _findCommentInTree(comment.replies, commentId);
        if (nested != null) return nested;
      }
    }
    return null;
  }

  List<CommentModel> _updateCommentLikeInTree({
    required List<CommentModel> comments,
    required int targetCommentId,
    required bool Function(CommentModel) isLikedUpdater,
    required int Function(CommentModel) likesCount,
  }) {
    return comments.map((comment) {
      if (comment.id == targetCommentId) {
        return comment.copyWith(
          isLiked: isLikedUpdater(comment),
          likesCount: likesCount(comment),
        );
      } else if (comment.replies.isNotEmpty) {
        return comment.copyWith(
          replies: _updateCommentLikeInTree(
            comments: comment.replies,
            targetCommentId: targetCommentId,
            isLikedUpdater: isLikedUpdater,
            likesCount: likesCount,
          ),
        );
      }
      return comment;
    }).toList();
  }
}
