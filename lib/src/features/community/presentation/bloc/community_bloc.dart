import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/features/community/domain/repositories/community_repository.dart';
import 'package:ntk_project/src/features/community/data/models/community_message_model.dart';
import 'package:ntk_project/src/features/community/data/models/post_model.dart';
import 'package:ntk_project/src/features/community/data/community_socket_service.dart';
import 'dart:async';
import 'community_event.dart';
import 'community_state.dart';

class CommunityBloc extends Bloc<CommunityEvent, CommunityState> {
  final CommunityRepository _repository;
  final CommunitySocketService _socketService;
  final Set<int> _processingLikes = {};
  
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
    on<CreateCommunityPost>(_onCreateCommunityPost);
    on<EditPost>(_onEditPost);
    on<DeletePost>(_onDeletePost);
    on<ReportPost>(_onReportPost);
    on<CreateCommunity>(_onCreateCommunity);
    on<JoinCommunity>(_onJoinCommunity);
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
        // 2. Call API
        final newLikesFromServer = await _repository.likePost(id: event.postId);

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
      );

      final updatedPosts = state.posts.map((post) {
        if (post.id == event.postId) {
          final newComments = [...post.comments, comment];
          return post.copyWith(
            commentCount: post.commentCount + 1,
            comments: newComments,
          );
        }
        return post;
      }).toList();

      final updatedFeedPosts = state.feedPosts.map((post) {
        if (post.id == event.postId) {
          final newComments = [...post.comments, comment];
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
      await _repository.joinCommunity(
        communityId: event.communityId,
      );
      emit(
        state.copyWith(
          isLoading: false,
          message: 'Successfully joined community',
          clearError: true,
        ),
      );
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
}
