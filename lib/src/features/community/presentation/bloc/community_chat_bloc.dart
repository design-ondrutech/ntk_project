import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/features/community/data/community_socket_service.dart';
import 'package:ntk_project/src/features/community/data/models/community_message_model.dart';
import 'package:ntk_project/src/features/community/domain/repositories/community_repository.dart';
import 'community_chat_event.dart';
import 'community_chat_state.dart';

class CommunityChatBloc extends Bloc<CommunityChatEvent, CommunityChatState> {
  final CommunityRepository _repository;
  final CommunitySocketService _socketService;

  StreamSubscription? _messageSub;
  StreamSubscription? _messageEditedSub;
  StreamSubscription? _messageDeletedSub;
  StreamSubscription? _messageReactionSub;
  StreamSubscription? _messagesReadSub;
  StreamSubscription? _settingsSub;
  StreamSubscription? _typingSub;

  CommunityChatBloc(this._repository, this._socketService)
    : super(const CommunityChatState()) {
    on<FetchCommunityMessagesEvent>(_onFetchCommunityMessages);
    on<SendCommunityMessageEvent>(_onSendCommunityMessage);
    on<ReactToMessageEvent>(_onReactToMessage);
    on<MarkMessagesReadEvent>(_onMarkMessagesRead);
    on<EditMessageEvent>(_onEditMessage);
    on<DeleteMessageEvent>(_onDeleteMessage);
    on<StarMessageEvent>(_onStarMessage);
    on<UnstarMessageEvent>(_onUnstarMessage);
    on<SendTypingEvent>(_onSendTyping);

    on<ConnectChatSocket>(_onConnectChatSocket);
    on<DisconnectChatSocket>(_onDisconnectChatSocket);

    // Socket driven events
    on<LiveMessageReceived>(_onLiveMessageReceived);
    on<LiveMessageReactionReceived>(_onLiveMessageReactionReceived);
    on<LiveMessageEdited>(_onLiveMessageEdited);
    on<LiveMessageDeleted>(_onLiveMessageDeleted);
    on<LiveMessagesRead>(_onLiveMessagesRead);
    on<LiveSettingsUpdated>(_onLiveSettingsUpdated);
    on<LiveTypingEvent>(_onLiveTyping);
  }

  void _onConnectChatSocket(
    ConnectChatSocket event,
    Emitter<CommunityChatState> emit,
  ) {
    _socketService.connect(event.token);
    _socketService.joinCommunity(event.communityId);

    _messageSub?.cancel();
    _messageEditedSub?.cancel();
    _messageDeletedSub?.cancel();
    _messageReactionSub?.cancel();
    _messagesReadSub?.cancel();
    _settingsSub?.cancel();
    _typingSub?.cancel();

    _messageSub = _socketService.onMessageReceived.listen((msg) {
      if (!isClosed) add(LiveMessageReceived(msg));
    });

    _messageEditedSub = _socketService.onMessageEdited.listen((msg) {
      if (!isClosed) add(LiveMessageEdited(msg));
    });

    _messageDeletedSub = _socketService.onMessageDeleted.listen((data) {
      if (!isClosed) add(LiveMessageDeleted(data['id'] as int));
    });

    _messageReactionSub = _socketService.onMessageReaction.listen((msg) {
      if (!isClosed) add(LiveMessageReactionReceived(msg));
    });

    _messagesReadSub = _socketService.onMessagesRead.listen((data) {
      final List<dynamic> ids = data['messageIds'] ?? [];
      final int readerId = data['readerId'] ?? 0;
      if (!isClosed) add(LiveMessagesRead(ids.cast<int>(), readerId));
    });

    _settingsSub = _socketService.onSettingsUpdated.listen((community) {
      if (!isClosed) add(LiveSettingsUpdated(community));
    });

    _typingSub = _socketService.onTyping.listen((data) {
      if (!isClosed) {
        final userId = data['userId'] as int? ?? 0;
        final userName = data['userName'] as String? ?? '';
        final isTyping = data['isTyping'] as bool? ?? true;
        add(LiveTypingEvent(userId, userName, isTyping: isTyping));
      }
    });
  }

  void _onDisconnectChatSocket(
    DisconnectChatSocket event,
    Emitter<CommunityChatState> emit,
  ) {
    _messageSub?.cancel();
    _messageEditedSub?.cancel();
    _messageDeletedSub?.cancel();
    _messageReactionSub?.cancel();
    _messagesReadSub?.cancel();
    _settingsSub?.cancel();
    _typingSub?.cancel();
    // Assuming leaving community handles the leave on socket level.
    // _socketService.leaveCommunity(...) should be called before disconnecting
  }

  Future<void> _onFetchCommunityMessages(
    FetchCommunityMessagesEvent event,
    Emitter<CommunityChatState> emit,
  ) async {
    // If it's a pagination load (beforeMessageId is not null), don't show full loading overlay
    if (event.beforeMessageId == null) {
      emit(state.copyWith(isLoading: true, clearError: true));
    }

    try {
      final messages = await _repository.getCommunityMessages(
        communityId: event.communityId,
        beforeMessageId: event.beforeMessageId,
      );

      if (event.beforeMessageId != null) {
        // Append older messages to the end
        emit(
          state.copyWith(
            isLoading: false,
            messages: [...state.messages, ...messages.reversed],
          ),
        );
      } else {
        // Initial load, newest should be first
        emit(state.copyWith(isLoading: false, messages: messages.reversed.toList()));
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onSendCommunityMessage(
    SendCommunityMessageEvent event,
    Emitter<CommunityChatState> emit,
  ) async {
    emit(state.copyWith(isSendingMessage: true, clearError: true));
    try {
      final message = await _repository.sendCommunityMessage(
        communityId: event.communityId,
        message: event.message,
        replyToMessageId: event.replyToMessageId,
        messageType: event.messageType,
        mediaUrl: event.mediaUrl,
        mediaType: event.mediaType,
        fileName: event.fileName,
        metadata: event.metadata,
      );
      // Wait for socket or optimistically add
      if (!state.messages.any((m) => m.id == message.id)) {
        emit(
          state.copyWith(
            isSendingMessage: false,
            messages: [message, ...state.messages],
          ),
        );
      } else {
        emit(state.copyWith(isSendingMessage: false));
      }
    } catch (e) {
      emit(state.copyWith(isSendingMessage: false, error: e.toString()));
    }
  }

  Future<void> _onReactToMessage(
    ReactToMessageEvent event,
    Emitter<CommunityChatState> emit,
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
    MarkMessagesReadEvent event,
    Emitter<CommunityChatState> emit,
  ) async {
    try {
      if (event.messageIds.isEmpty) return;
      await _repository.markCommunityMessagesRead(
        communityId: event.communityId,
        messageIds: event.messageIds,
      );
    } catch (e) {
      // Ignored
    }
  }

  Future<void> _onEditMessage(
    EditMessageEvent event,
    Emitter<CommunityChatState> emit,
  ) async {
    try {
      final updatedMsg = await _repository.editCommunityMessage(
        id: event.messageId,
        message: event.message,
      );
      final updatedList = state.messages
          .map((m) => m.id == event.messageId ? updatedMsg : m)
          .toList();
      emit(state.copyWith(messages: updatedList, clearError: true));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to edit message: $e'));
    }
  }

  Future<void> _onDeleteMessage(
    DeleteMessageEvent event,
    Emitter<CommunityChatState> emit,
  ) async {
    try {
      await _repository.deleteCommunityMessage(id: event.messageId);
      final updatedList = state.messages.map((m) {
        if (m.id == event.messageId) {
          return CommunityMessageModel(
            id: m.id,
            communityId: m.communityId,
            senderName: m.senderName,
            message: "This message was deleted",
            messageType: m.messageType,
            isDeleted: true,
            readByCount: m.readByCount,
          );
        }
        return m;
      }).toList();
      emit(state.copyWith(messages: updatedList, clearError: true));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to delete message: $e'));
    }
  }

  Future<void> _onStarMessage(
    StarMessageEvent event,
    Emitter<CommunityChatState> emit,
  ) async {
    try {
      await _repository.starCommunityMessage(messageId: event.messageId);
      final updatedList = state.messages
          .map((m) => m.id == event.messageId ? m.copyWith(isStarred: true) : m)
          .toList();
      emit(state.copyWith(messages: updatedList, clearError: true));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to star message: $e'));
    }
  }

  Future<void> _onUnstarMessage(
    UnstarMessageEvent event,
    Emitter<CommunityChatState> emit,
  ) async {
    try {
      await _repository.unstarCommunityMessage(messageId: event.messageId);
      final updatedList = state.messages
          .map((m) => m.id == event.messageId ? m.copyWith(isStarred: false) : m)
          .toList();
      emit(state.copyWith(messages: updatedList, clearError: true));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to unstar message: $e'));
    }
  }

  void _onLiveMessageReceived(
    LiveMessageReceived event,
    Emitter<CommunityChatState> emit,
  ) {
    if (state.messages.any((m) => m.id == event.message.id)) return;
    // Prepend because messages are usually displayed in a reverse list view (bottom up)
    emit(state.copyWith(messages: [event.message, ...state.messages]));
  }

  void _onLiveMessageReactionReceived(
    LiveMessageReactionReceived event,
    Emitter<CommunityChatState> emit,
  ) {
    final updatedList = state.messages
        .map((m) => m.id == event.message.id ? event.message : m)
        .toList();
    emit(state.copyWith(messages: updatedList));
  }

  void _onLiveMessageEdited(
    LiveMessageEdited event,
    Emitter<CommunityChatState> emit,
  ) {
    final updatedList = state.messages
        .map((m) => m.id == event.message.id ? event.message : m)
        .toList();
    emit(state.copyWith(messages: updatedList));
  }

  void _onLiveMessageDeleted(
    LiveMessageDeleted event,
    Emitter<CommunityChatState> emit,
  ) {
    final updatedList = state.messages.map((m) {
      if (m.id == event.messageId) {
        return CommunityMessageModel(
          id: m.id,
          communityId: m.communityId,
          senderName: m.senderName,
          message: "This message was deleted",
          messageType: m.messageType,
          isDeleted: true,
          readByCount: m.readByCount,
        );
      }
      return m;
    }).toList();
    emit(state.copyWith(messages: updatedList));
  }

  void _onLiveMessagesRead(
    LiveMessagesRead event,
    Emitter<CommunityChatState> emit,
  ) {
    final updatedList = state.messages.map((m) {
      if (event.messageIds.contains(m.id)) {
        return CommunityMessageModel(
          id: m.id,
          communityId: m.communityId,
          senderId: m.senderId,
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

  void _onLiveSettingsUpdated(
    LiveSettingsUpdated event,
    Emitter<CommunityChatState> emit,
  ) {
    emit(state.copyWith(currentCommunitySettings: event.community));
  }

  void _onSendTyping(
    SendTypingEvent event,
    Emitter<CommunityChatState> emit,
  ) {
    _socketService.emitTyping(event.communityId, event.userId, event.userName);
  }

  void _onLiveTyping(
    LiveTypingEvent event,
    Emitter<CommunityChatState> emit,
  ) {
    final currentUsers = List<String>.from(state.typingUsers);
    
    if (event.isTyping && !currentUsers.contains(event.userName)) {
      currentUsers.add(event.userName);
      emit(state.copyWith(typingUsers: currentUsers));
    } else if (!event.isTyping && currentUsers.contains(event.userName)) {
      currentUsers.remove(event.userName);
      emit(state.copyWith(typingUsers: currentUsers));
    }
  }

  @override
  Future<void> close() {
    _messageSub?.cancel();
    _messageEditedSub?.cancel();
    _messageDeletedSub?.cancel();
    _messageReactionSub?.cancel();
    _messagesReadSub?.cancel();
    _settingsSub?.cancel();
    _typingSub?.cancel();
    return super.close();
  }
}
