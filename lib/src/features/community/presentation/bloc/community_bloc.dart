import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/features/community/domain/repositories/community_repository.dart';
import 'package:ntk_project/src/features/community/data/models/community_message_model.dart';
import 'package:ntk_project/src/features/community/data/models/post_model.dart';
import 'package:ntk_project/src/features/community/data/models/comment_model.dart';
import 'package:ntk_project/src/features/community/data/community_socket_service.dart';
import 'dart:async';
import 'community_event.dart';
import 'community_state.dart';

class CommunityBloc extends Bloc<CommunityEvent, CommunityState> {
  final CommunityRepository _repository;
  final CommunitySocketService _socketService;
  final Set<int> _processingLikes = {};
  final Set<int> _processingCommentLikes = {};
  
  StreamSubscription? _postDeletedSub;
  StreamSubscription? _pollDeletedSub;

  CommunityBloc(this._repository, this._socketService) : super(const CommunityState()) {
    on<FetchCommunities>(_onFetchCommunities);
    on<FetchCommunityFeed>(_onFetchCommunityFeed);
    on<FetchCommunityPosts>(_onFetchCommunityPosts);
    on<FetchCommunityMessages>(_onFetchCommunityMessages);
    on<SendCommunityMessage>(_onSendCommunityMessage);
    on<LikePost>(_onLikePost);
    on<AddComment>(_onAddComment);
    on<LikeComment>(_onLikeComment);
    on<CreateCommunityPost>(_onCreateCommunityPost);
    on<EditPost>(_onEditPost);
    on<DeletePost>(_onDeletePost);
    on<ReportPost>(_onReportPost);
    on<ModeratePost>(_onModeratePost);
    on<CreateCommunity>(_onCreateCommunity);
    on<JoinCommunity>(_onJoinCommunity);
    on<ReviewJoinRequest>(_onReviewJoinRequest);
    on<CreateComplaint>(_onCreateComplaint);
    on<ReactToMessage>(_onReactToMessage);
    on<MarkMessagesRead>(_onMarkMessagesRead);
    on<EditMessage>(_onEditMessage);
    on<DeleteMessage>(_onDeleteMessage);
    on<OnLiveMessageReceived>(_onLiveMessageReceived);
    on<OnLiveMessageReactionReceived>(_onLiveMessageReactionReceived);
    on<OnLiveMessageEdited>(_onLiveMessageEdited);
    on<OnLiveMessageDeleted>(_onLiveMessageDeleted);
    on<OnLiveMessagesRead>(_onLiveMessagesRead);
    on<ClearCommunityMessage>(
      (event, emit) => emit(state.copyWith(clearMessage: true)),
    );
    on<ClearCommunityError>(
      (event, emit) => emit(state.copyWith(clearError: true)),
    );
    
    // Listen to global socket events for moderation/deletion
    _postDeletedSub = _socketService.onPostDeletedGlobal.listen((data) {
      if (data['postId'] != null) {
        add(DeletePost(data['postId']));
      }
    });
    
    _pollDeletedSub = _socketService.onPollDeletedGlobal.listen((data) {
      if (data['pollId'] != null) {
        // Here we simulate post deletion since feedPosts contains both posts and polls
        add(DeletePost(data['pollId']));
      }
    });
  }

  @override
  Future<void> close() {
    _postDeletedSub?.cancel();
    _pollDeletedSub?.cancel();
    return super.close();
  }

  Future<void> _onFetchCommunities(
    FetchCommunities event,
    Emitter<CommunityState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final communities = await _repository.getCommunities();
      emit(state.copyWith(isLoading: false, communities: communities));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onFetchCommunityFeed(
    FetchCommunityFeed event,
    Emitter<CommunityState> emit,
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

  Future<void> _onFetchCommunityPosts(
    FetchCommunityPosts event,
    Emitter<CommunityState> emit,
  ) async {
    emit(
      state.copyWith(
        isLoading: true,
        selectedCommunityId: event.communityId,
        clearError: true,
      ),
    );
    try {
      final posts = await _repository.getCommunityPosts(
        communityId: event.communityId,
      );
      emit(state.copyWith(isLoading: false, posts: posts));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onFetchCommunityMessages(
    FetchCommunityMessages event,
    Emitter<CommunityState> emit,
  ) async {
    emit(
      state.copyWith(
        isLoading: true,
        selectedCommunityId: event.communityId,
        clearError: true,
      ),
    );
    try {
      final messages = await _repository.getCommunityMessages(
        communityId: event.communityId,
        beforeMessageId: event.beforeMessageId,
      );
      emit(state.copyWith(isLoading: false, messages: messages));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onSendCommunityMessage(
    SendCommunityMessage event,
    Emitter<CommunityState> emit,
  ) async {
    emit(state.copyWith(isSendingMessage: true, clearError: true));
    try {
      final message = await _repository.sendCommunityMessage(
        communityId: event.communityId,
        message: event.message,
        replyToMessageId: event.replyToMessageId,
        messageType: 'TEXT',
      );
      emit(
        state.copyWith(
          isSendingMessage: false,
          messages: [...state.messages, message],
          clearError: true,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isSendingMessage: false, error: e.toString()));
    }
  }

  Future<void> _onLikePost(LikePost event, Emitter<CommunityState> emit) async {
    if (_processingLikes.contains(event.postId)) return;
    _processingLikes.add(event.postId);

    try {
      PostModel? postToToggle;
      try {
        postToToggle = state.posts.firstWhere((p) => p.id == event.postId);
      } catch (_) {
        try {
          postToToggle = state.feedPosts.firstWhere((p) => p.id == event.postId);
        } catch (_) {}
      }

      if (postToToggle == null) return;
      final isCurrentlyLiked = postToToggle.isLiked;

      // 1. Optimistic update
      final optimisticPosts = state.posts.map((post) {
        if (post.id == event.postId) {
          final newLikes = post.isLiked ? post.likes - 1 : post.likes + 1;
          return post.copyWith(
            likes: newLikes < 0 ? 0 : newLikes,
            isLiked: !post.isLiked,
          );
        }
        return post;
      }).toList();

      final optimisticFeedPosts = state.feedPosts.map((post) {
        if (post.id == event.postId) {
          final newLikes = post.isLiked ? post.likes - 1 : post.likes + 1;
          return post.copyWith(
            likes: newLikes < 0 ? 0 : newLikes,
            isLiked: !post.isLiked,
          );
        }
        return post;
      }).toList();

      emit(
        state.copyWith(
          posts: optimisticPosts,
          feedPosts: optimisticFeedPosts,
          clearError: true,
        ),
      );

      try {
        // 2. Call API (likeCommunityPost handles toggling for both like and unlike)
        final newLikesFromServer = await _repository.likeCommunityPost(postId: event.postId);

      // 3. Sync with server (only update likes count)
      final syncedPosts = state.posts.map((post) {
        if (post.id == event.postId) {
          return post.copyWith(likes: newLikesFromServer);
        }
        return post;
      }).toList();

      final syncedFeedPosts = state.feedPosts.map((post) {
        if (post.id == event.postId) {
          return post.copyWith(likes: newLikesFromServer);
        }
        return post;
      }).toList();

      emit(
        state.copyWith(
          posts: syncedPosts,
          feedPosts: syncedFeedPosts,
          clearError: true,
        ),
      );
    } catch (e) {
      // 4. Rollback on failure
      final rollbackPosts = state.posts.map((post) {
        if (post.id == event.postId) {
          final newLikes = post.isLiked ? post.likes - 1 : post.likes + 1;
          return post.copyWith(
            likes: newLikes < 0 ? 0 : newLikes,
            isLiked: !post.isLiked,
          );
        }
        return post;
      }).toList();

      final rollbackFeedPosts = state.feedPosts.map((post) {
        if (post.id == event.postId) {
          final newLikes = post.isLiked ? post.likes - 1 : post.likes + 1;
          return post.copyWith(
            likes: newLikes < 0 ? 0 : newLikes,
            isLiked: !post.isLiked,
          );
        }
        return post;
      }).toList();

      emit(
        state.copyWith(
          posts: rollbackPosts,
          feedPosts: rollbackFeedPosts,
          error: 'செயல்பாட்டை நிறைவு செய்ய முடியவில்லை. தயவுசெய்து மீண்டும் முயற்சிக்கவும்.',
          clearMessage: true,
        ),
      );
    }
    } finally {
      _processingLikes.remove(event.postId);
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
        parentId: event.parentId,
      );

      final updatedPosts = state.posts.map((post) {
        if (post.id == event.postId) {
          final newComments = event.parentId == null
              ? [...post.comments, comment]
              : _addCommentToTree(post.comments, comment, event.parentId!);
          return post.copyWith(
            commentCount: post.commentCount + 1,
            comments: newComments,
          );
        }
        return post;
      }).toList();

      final updatedFeedPosts = state.feedPosts.map((post) {
        if (post.id == event.postId) {
          final newComments = event.parentId == null
              ? [...post.comments, comment]
              : _addCommentToTree(post.comments, comment, event.parentId!);
          return post.copyWith(
            commentCount: post.commentCount + 1,
            comments: newComments,
          );
        }
        return post;
      }).toList();

      emit(
        state.copyWith(
          posts: updatedPosts,
          feedPosts: updatedFeedPosts,
          message: 'கமெண்ட் சேர்க்கப்பட்டது',
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          error: 'கமெண்ட் சேர்க்க முடியவில்லை: $e',
          clearMessage: true,
        ),
      );
    }
  }

  Future<void> _onCreateCommunityPost(
    CreateCommunityPost event,
    Emitter<CommunityState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final newPost = await _repository.createFeedPost(
        title: event.title,
        content: event.content,
        category: event.category,
        authorName: event.authorName,
        authorRole: event.authorRole,
        locationId: event.locationId,
        images: event.images,
      );

      emit(
        state.copyWith(
          isLoading: false,
          posts: [newPost, ...state.posts],
          feedPosts: [newPost, ...state.feedPosts],
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

  Future<void> _onEditPost(EditPost event, Emitter<CommunityState> emit) async {
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
          message: 'Post updated',
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: 'Failed to edit post: $e',
          clearMessage: true,
        ),
      );
    }
  }

  Future<void> _onDeletePost(
    DeletePost event,
    Emitter<CommunityState> emit,
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
          message: 'Post deleted',
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: 'Failed to delete post: $e',
          clearMessage: true,
        ),
      );
    }
  }

  Future<void> _onReportPost(
    ReportPost event,
    Emitter<CommunityState> emit,
  ) async {
    emit(state.copyWith(isReportingPost: true, clearError: true));
    try {
      await _repository.reportPost(postId: event.postId, reason: event.reason);
      emit(
        state.copyWith(
          isReportingPost: false,
          message: 'Post reported successfully.',
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isReportingPost: false,
          error: e.toString().replaceFirst('Exception: ', ''),
          clearMessage: true,
        ),
      );
    }
  }

  Future<void> _onModeratePost(
    ModeratePost event,
    Emitter<CommunityState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      await _repository.moderatePost(
        postId: event.postId,
        action: event.action,
        warningMessage: event.warningMessage,
      );

      if (event.action == 'DELETE') {
        bool keep(PostModel post) => post.id != event.postId;
        emit(
          state.copyWith(
            isLoading: false,
            posts: state.posts.where(keep).toList(),
            feedPosts: state.feedPosts.where(keep).toList(),
            message: 'Post deleted successfully.',
            clearError: true,
          ),
        );
      } else {
        PostModel update(PostModel post) {
          if (post.id == event.postId) {
            return post.copyWith(
              status: event.action == 'KEEP' ? 'ACTIVE' : post.status,
              hasWarning: event.action == 'WARN' ? true : post.hasWarning,
            );
          }
          return post;
        }
        emit(
          state.copyWith(
            isLoading: false,
            posts: state.posts.map(update).toList(),
            feedPosts: state.feedPosts.map(update).toList(),
            message: event.action == 'KEEP'
                ? 'Post marked as keep.'
                : 'Warning sent to post author.',
            clearError: true,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: 'Failed to moderate post: $e',
          clearMessage: true,
        ),
      );
    }
  }

  Future<void> _onCreateCommunity(
    CreateCommunity event,
    Emitter<CommunityState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final newCommunity = await _repository.createCommunity(
        name: event.name,
        description: event.description,
        image: event.image,
        allowMemberMessages: event.allowMemberMessages,
        locationId: event.locationId,
        privacyType: event.privacyType,
      );

      emit(
        state.copyWith(
          isLoading: false,
          communities: [newCommunity, ...state.communities],
          message: 'Community created successfully',
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: 'Community creation failed: $e',
          clearMessage: true,
        ),
      );
    }
  }

  Future<void> _onJoinCommunity(
    JoinCommunity event,
    Emitter<CommunityState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final status = await _repository.joinCommunityOrRequest(
        communityId: event.communityId,
        reason: event.reason,
        inviteCode: event.inviteCode,
      );
      if (status == 'PENDING_APPROVAL') {
        emit(
          state.copyWith(
            isLoading: false,
            isJoinPending: true,
            message: 'Request sent. Waiting for approval.',
            clearError: true,
          ),
        );
      } else if (status == 'JOINED') {
        add(const FetchCommunities());
        emit(
          state.copyWith(
            isLoading: false,
            isJoinPending: false,
            message: 'Successfully joined community',
            clearError: true,
          ),
        );
      } else {
        emit(
          state.copyWith(
            isLoading: false,
            error: 'Failed to join community. Status: $status',
            clearMessage: true,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: 'Failed to join community: $e',
          clearMessage: true,
        ),
      );
    }
  }

  Future<void> _onReviewJoinRequest(
    ReviewJoinRequest event,
    Emitter<CommunityState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      await _repository.reviewCommunityJoinRequest(
        requestId: event.requestId,
        action: event.action,
        rejectionReason: event.rejectionReason,
      );
      emit(state.copyWith(isLoading: false, message: 'Request ${event.action.toLowerCase()}d successfully', clearError: true));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: 'Failed to review request: $e', clearMessage: true));
    }
  }

  Future<void> _onCreateComplaint(
    CreateComplaint event,
    Emitter<CommunityState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      await _repository.createCommunityComplaint(
        communityId: event.communityId,
        title: event.title,
        description: event.description,
      );
      emit(state.copyWith(isLoading: false, message: 'Complaint submitted successfully', clearError: true));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: 'Failed to submit complaint: $e', clearMessage: true));
    }
  }

  Future<void> _onReactToMessage(
    ReactToMessage event,
    Emitter<CommunityState> emit,
  ) async {
    try {
      await _repository.reactToCommunityMessage(
        messageId: event.messageId,
        emoji: event.emoji,
      );
    } catch (e) {
      emit(state.copyWith(error: 'Failed to react: $e'));
    }
  }

  Future<void> _onMarkMessagesRead(
    MarkMessagesRead event,
    Emitter<CommunityState> emit,
  ) async {
    try {
      await _repository.markCommunityMessagesRead(
        communityId: event.communityId,
        messageIds: event.messageIds,
      );
    } catch (e) {
      debugPrint('Failed to mark messages read: $e');
    }
  }

  Future<void> _onEditMessage(
    EditMessage event,
    Emitter<CommunityState> emit,
  ) async {
    try {
      final updatedMsg = await _repository.editCommunityMessage(
        id: event.messageId,
        message: event.message,
      );
      final updatedList = state.messages.map((m) {
        if (m.id == event.messageId) {
          return CommunityMessageModel(
            id: m.id,
            communityId: m.communityId,
            senderId: m.senderId,
            senderType: m.senderType,
            senderName: m.senderName,
            message: updatedMsg.message,
            messageType: m.messageType,
            mediaUrl: m.mediaUrl,
            mediaType: m.mediaType,
            fileName: m.fileName,
            status: m.status,
            replyToMessageId: m.replyToMessageId,
            editedAt: updatedMsg.editedAt,
            isDeleted: m.isDeleted,
            deletedAt: m.deletedAt,
            readByCount: m.readByCount,
            createdAt: m.createdAt,
            replyTo: m.replyTo,
            reactions: m.reactions,
          );
        }
        return m;
      }).toList();
      emit(state.copyWith(messages: updatedList, clearError: true));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to edit message: $e'));
    }
  }

  Future<void> _onDeleteMessage(
    DeleteMessage event,
    Emitter<CommunityState> emit,
  ) async {
    try {
      await _repository.deleteCommunityMessage(id: event.messageId);
    } catch (e) {
      emit(state.copyWith(error: 'Failed to delete message: $e'));
    }
  }

  void _onLiveMessageReceived(
    OnLiveMessageReceived event,
    Emitter<CommunityState> emit,
  ) {
    if (state.messages.any((m) => m.id == event.message.id)) return;
    emit(state.copyWith(messages: [...state.messages, event.message]));
  }

  void _onLiveMessageReactionReceived(
    OnLiveMessageReactionReceived event,
    Emitter<CommunityState> emit,
  ) {
    final updatedList = state.messages.map((m) {
      if (m.id == event.messageId) {
        return CommunityMessageModel(
          id: m.id,
          communityId: m.communityId,
          senderId: m.senderId,
          senderType: m.senderType,
          senderName: m.senderName,
          message: m.message,
          messageType: m.messageType,
          mediaUrl: m.mediaUrl,
          mediaType: m.mediaType,
          fileName: m.fileName,
          status: m.status,
          replyToMessageId: m.replyToMessageId,
          editedAt: m.editedAt,
          isDeleted: m.isDeleted,
          deletedAt: m.deletedAt,
          readByCount: m.readByCount,
          createdAt: m.createdAt,
          replyTo: m.replyTo,
          reactions: event.reactions,
        );
      }
      return m;
    }).toList();
    emit(state.copyWith(messages: updatedList));
  }

  void _onLiveMessageEdited(
    OnLiveMessageEdited event,
    Emitter<CommunityState> emit,
  ) {
    final updatedList = state.messages.map((m) {
      if (m.id == event.messageId) {
        return CommunityMessageModel(
          id: m.id,
          communityId: m.communityId,
          senderId: m.senderId,
          senderType: m.senderType,
          senderName: m.senderName,
          message: event.message,
          messageType: m.messageType,
          mediaUrl: m.mediaUrl,
          mediaType: m.mediaType,
          fileName: m.fileName,
          status: m.status,
          replyToMessageId: m.replyToMessageId,
          editedAt: event.editedAt,
          isDeleted: m.isDeleted,
          deletedAt: m.deletedAt,
          readByCount: m.readByCount,
          createdAt: m.createdAt,
          replyTo: m.replyTo,
          reactions: m.reactions,
        );
      }
      return m;
    }).toList();
    emit(state.copyWith(messages: updatedList));
  }

  void _onLiveMessageDeleted(
    OnLiveMessageDeleted event,
    Emitter<CommunityState> emit,
  ) {
    final updatedList = state.messages.map((m) {
      if (m.id == event.messageId) {
        return CommunityMessageModel(
          id: m.id,
          communityId: m.communityId,
          senderId: m.senderId,
          senderType: m.senderType,
          senderName: m.senderName,
          message: m.message,
          messageType: m.messageType,
          mediaUrl: m.mediaUrl,
          mediaType: m.mediaType,
          fileName: m.fileName,
          status: m.status,
          replyToMessageId: m.replyToMessageId,
          editedAt: m.editedAt,
          isDeleted: true,
          deletedAt: DateTime.now().toIso8601String(),
          readByCount: m.readByCount,
          createdAt: m.createdAt,
          replyTo: m.replyTo,
          reactions: const [],
        );
      }
      return m;
    }).toList();
    emit(state.copyWith(messages: updatedList));
  }

  void _onLiveMessagesRead(
    OnLiveMessagesRead event,
    Emitter<CommunityState> emit,
  ) {
    final updatedList = state.messages.map((m) {
      if (event.messageIds.contains(m.id)) {
        return CommunityMessageModel(
          id: m.id,
          communityId: m.communityId,
          senderId: m.senderId,
          senderType: m.senderType,
          senderName: m.senderName,
          message: m.message,
          messageType: m.messageType,
          mediaUrl: m.mediaUrl,
          mediaType: m.mediaType,
          fileName: m.fileName,
          status: 'READ',
          replyToMessageId: m.replyToMessageId,
          editedAt: m.editedAt,
          isDeleted: m.isDeleted,
          deletedAt: m.deletedAt,
          readByCount: m.readByCount + 1,
          createdAt: m.createdAt,
          replyTo: m.replyTo,
          reactions: m.reactions,
        );
      }
      return m;
    }).toList();
    emit(state.copyWith(messages: updatedList));
  }

  Future<void> _onLikeComment(
    LikeComment event,
    Emitter<CommunityState> emit,
  ) async {
    if (_processingCommentLikes.contains(event.commentId)) return;
    _processingCommentLikes.add(event.commentId);

    try {
      CommentModel? targetComment;
      for (final post in [...state.posts, ...state.feedPosts]) {
        targetComment = _findCommentInTree(post.comments, event.commentId);
        if (targetComment != null) break;
      }

      if (targetComment == null) return;

      final wasLiked = targetComment.isLiked;

      // 1. Optimistic Update
      final updatedPosts = state.posts.map((post) {
        return post.copyWith(
          comments: _updateCommentLikeInTree(
            comments: post.comments,
            targetCommentId: event.commentId,
            isLikedUpdater: (c) => !c.isLiked,
            likesCount: (c) => c.isLiked ? (c.likesCount - 1).clamp(0, 999999) : c.likesCount + 1,
          ),
        );
      }).toList();

      final updatedFeedPosts = state.feedPosts.map((post) {
        return post.copyWith(
          comments: _updateCommentLikeInTree(
            comments: post.comments,
            targetCommentId: event.commentId,
            isLikedUpdater: (c) => !c.isLiked,
            likesCount: (c) => c.isLiked ? (c.likesCount - 1).clamp(0, 999999) : c.likesCount + 1,
          ),
        );
      }).toList();

      emit(state.copyWith(
        posts: updatedPosts,
        feedPosts: updatedFeedPosts,
        clearError: true,
      ));

      try {
        // 2. Call API
        final result = await _repository.likeComment(commentId: event.commentId);
        final isLikedFromServer = result['isLiked'] as bool;
        final likesCountFromServer = result['likesCount'] as int;

        // 3. Sync with server values
        final syncedPosts = state.posts.map((post) {
          return post.copyWith(
            comments: _updateCommentLikeInTree(
              comments: post.comments,
              targetCommentId: event.commentId,
              isLikedUpdater: (_) => isLikedFromServer,
              likesCount: (_) => likesCountFromServer,
            ),
          );
        }).toList();

        final syncedFeedPosts = state.feedPosts.map((post) {
          return post.copyWith(
            comments: _updateCommentLikeInTree(
              comments: post.comments,
              targetCommentId: event.commentId,
              isLikedUpdater: (_) => isLikedFromServer,
              likesCount: (_) => likesCountFromServer,
            ),
          );
        }).toList();

        emit(state.copyWith(
          posts: syncedPosts,
          feedPosts: syncedFeedPosts,
          clearError: true,
        ));
      } catch (e) {
        // 4. Rollback on failure
        final rollbackPosts = state.posts.map((post) {
          return post.copyWith(
            comments: _updateCommentLikeInTree(
              comments: post.comments,
              targetCommentId: event.commentId,
              isLikedUpdater: (_) => wasLiked,
              likesCount: (_) => targetComment!.likesCount,
            ),
          );
        }).toList();

        final rollbackFeedPosts = state.feedPosts.map((post) {
          return post.copyWith(
            comments: _updateCommentLikeInTree(
              comments: post.comments,
              targetCommentId: event.commentId,
              isLikedUpdater: (_) => wasLiked,
              likesCount: (_) => targetComment!.likesCount,
            ),
          );
        }).toList();

        emit(state.copyWith(
          posts: rollbackPosts,
          feedPosts: rollbackFeedPosts,
          error: 'லைக் செய்ய முடியவில்லை: $e',
          clearMessage: true,
        ));
      }
    } finally {
      _processingCommentLikes.remove(event.commentId);
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
