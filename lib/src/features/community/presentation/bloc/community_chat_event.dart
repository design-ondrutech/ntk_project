import 'package:equatable/equatable.dart';
import 'package:ntk_project/src/features/community/data/models/community_message_model.dart';
import 'package:ntk_project/src/features/community/data/models/community_model.dart';

abstract class CommunityChatEvent extends Equatable {
  const CommunityChatEvent();

  @override
  List<Object?> get props => [];
}

class ConnectChatSocket extends CommunityChatEvent {
  final int communityId;
  final String token;
  const ConnectChatSocket(this.communityId, this.token);
  @override
  List<Object?> get props => [communityId, token];
}

class DisconnectChatSocket extends CommunityChatEvent {}

class FetchCommunityMessagesEvent extends CommunityChatEvent {
  final int communityId;
  final int? beforeMessageId;

  const FetchCommunityMessagesEvent(this.communityId, {this.beforeMessageId});

  @override
  List<Object?> get props => [communityId, beforeMessageId];
}

class SendCommunityMessageEvent extends CommunityChatEvent {
  final int communityId;
  final String message;
  final int? replyToMessageId;
  final String? messageType;
  final String? mediaUrl;
  final String? mediaType;
  final String? fileName;
  final String? metadata;

  const SendCommunityMessageEvent({
    required this.communityId,
    required this.message,
    this.replyToMessageId,
    this.messageType,
    this.mediaUrl,
    this.mediaType,
    this.fileName,
    this.metadata,
  });

  @override
  List<Object?> get props => [
    communityId,
    message,
    replyToMessageId,
    messageType,
    mediaUrl,
    mediaType,
    fileName,
    metadata,
  ];
}

class ReactToMessageEvent extends CommunityChatEvent {
  final int messageId;
  final String emoji;
  const ReactToMessageEvent(this.messageId, this.emoji);
  @override
  List<Object?> get props => [messageId, emoji];
}

class MarkMessagesReadEvent extends CommunityChatEvent {
  final int communityId;
  final List<int> messageIds;
  const MarkMessagesReadEvent(this.communityId, this.messageIds);
  @override
  List<Object?> get props => [communityId, messageIds];
}

class EditMessageEvent extends CommunityChatEvent {
  final int messageId;
  final String message;
  const EditMessageEvent(this.messageId, this.message);
  @override
  List<Object?> get props => [messageId, message];
}

class DeleteMessageEvent extends CommunityChatEvent {
  final int messageId;
  const DeleteMessageEvent(this.messageId);
  @override
  List<Object?> get props => [messageId];
}

// Socket specific events triggered internally
class LiveMessageReceived extends CommunityChatEvent {
  final CommunityMessageModel message;
  const LiveMessageReceived(this.message);
  @override
  List<Object?> get props => [message];
}

class LiveMessageReactionReceived extends CommunityChatEvent {
  final CommunityMessageModel message;
  const LiveMessageReactionReceived(this.message);
  @override
  List<Object?> get props => [message];
}

class LiveMessageEdited extends CommunityChatEvent {
  final CommunityMessageModel message;
  const LiveMessageEdited(this.message);
  @override
  List<Object?> get props => [message];
}

class LiveMessageDeleted extends CommunityChatEvent {
  final int messageId;
  const LiveMessageDeleted(this.messageId);
  @override
  List<Object?> get props => [messageId];
}

class LiveMessagesRead extends CommunityChatEvent {
  final List<int> messageIds;
  final int readerId;
  const LiveMessagesRead(this.messageIds, this.readerId);
  @override
  List<Object?> get props => [messageIds, readerId];
}

class LiveSettingsUpdated extends CommunityChatEvent {
  final CommunityModel community;
  const LiveSettingsUpdated(this.community);
  @override
  List<Object?> get props => [community];
}
