import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/features/community/domain/repositories/community_repository.dart';
import 'package:ntk_project/src/features/community/data/models/community_message_model.dart';
import 'package:ntk_project/src/features/community/data/models/post_model.dart';
import 'community_event.dart';
import 'community_state.dart';

class CommunityBloc extends Bloc<CommunityEvent, CommunityState> {
  final CommunityRepository _repository;

  CommunityBloc(this._repository) : super(const CommunityState()) {
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
    on<CreateCommunity>(_onCreateCommunity);
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
    try {
      final newLikes = await _repository.likePost(id: event.postId);
      final updatedPosts = state.posts.map((post) {
        if (post.id == event.postId) {
          return post.copyWith(likes: newLikes, isLiked: !post.isLiked);
        }
        return post;
      }).toList();
      final updatedFeedPosts = state.feedPosts.map((post) {
        if (post.id == event.postId) {
          return post.copyWith(likes: newLikes, isLiked: !post.isLiked);
        }
        return post;
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
        state.copyWith(error: 'லைக் செய்ய முடியவில்லை: $e', clearMessage: true),
      );
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

      emit(
        state.copyWith(
          posts: updatedPosts,
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
      final newPost = await _repository.createCommunityPost(
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
