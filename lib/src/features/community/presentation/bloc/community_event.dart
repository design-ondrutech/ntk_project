import 'package:equatable/equatable.dart';
import 'package:ntk_project/src/features/community/data/models/community_message_model.dart';

abstract class CommunityEvent extends Equatable {
  const CommunityEvent();

  @override
  List<Object?> get props => [];
}

class FetchCommunities extends CommunityEvent {
  const FetchCommunities();
}

class FetchCommunityFeed extends CommunityEvent {
  final int? locationId;

  const FetchCommunityFeed({this.locationId});

  @override
  List<Object?> get props => [locationId];
}

class FetchCommunityPosts extends CommunityEvent {
  final int communityId;

  const FetchCommunityPosts(this.communityId);

  @override
  List<Object?> get props => [communityId];
}

class FetchCommunityMessages extends CommunityEvent {
  final int communityId;
  final int? beforeMessageId;

  const FetchCommunityMessages({
    required this.communityId,
    this.beforeMessageId,
  });

  @override
  List<Object?> get props => [communityId, beforeMessageId];
}

class SendCommunityMessage extends CommunityEvent {
  final int communityId;
  final String message;
  final int? replyToMessageId;

  const SendCommunityMessage({
    required this.communityId,
    required this.message,
    this.replyToMessageId,
  });

  @override
  List<Object?> get props => [communityId, message, replyToMessageId];
}

class LikePost extends CommunityEvent {
  final int postId;

  const LikePost(this.postId);

  @override
  List<Object?> get props => [postId];
}

class AddComment extends CommunityEvent {
  final int postId;
  final String content;
  final String authorName;
  final String authorRole;

  const AddComment({
    required this.postId,
    required this.content,
    required this.authorName,
    required this.authorRole,
  });

  @override
  List<Object?> get props => [postId, content, authorName, authorRole];
}

class CreateCommunityPost extends CommunityEvent {
  final String title;
  final String content;
  final String category;
  final String authorName;
  final String authorRole;
  final int locationId;
  final List<String>? images;

  const CreateCommunityPost({
    required this.title,
    required this.content,
    required this.category,
    required this.authorName,
    required this.authorRole,
    required this.locationId,
    this.images,
  });

  @override
  List<Object?> get props => [
    title,
    content,
    category,
    authorName,
    authorRole,
    locationId,
    images,
  ];
}

class EditPost extends CommunityEvent {
  final int postId;
  final String content;
  final List<String>? images;

  const EditPost({required this.postId, required this.content, this.images});

  @override
  List<Object?> get props => [postId, content, images];
}

class DeletePost extends CommunityEvent {
  final int postId;

  const DeletePost(this.postId);

  @override
  List<Object?> get props => [postId];
}

class CreateCommunity extends CommunityEvent {
  final String name;
  final String? description;
  final String? image;
  final bool allowMemberMessages;

  const CreateCommunity({
    required this.name,
    this.description,
    this.image,
    required this.allowMemberMessages,
  });

  @override
  List<Object?> get props => [name, description, image, allowMemberMessages];
}

// ─── Chat Interactions ────────────────────────────────────────────────────────

class ReactToMessage extends CommunityEvent {
  final int messageId;
  final String emoji;

  const ReactToMessage({required this.messageId, required this.emoji});

  @override
  List<Object?> get props => [messageId, emoji];
}

class MarkMessagesRead extends CommunityEvent {
  final int communityId;
  final List<int> messageIds;

  const MarkMessagesRead({required this.communityId, required this.messageIds});

  @override
  List<Object?> get props => [communityId, messageIds];
}

class EditMessage extends CommunityEvent {
  final int messageId;
  final String message;

  const EditMessage({required this.messageId, required this.message});

  @override
  List<Object?> get props => [messageId, message];
}

class DeleteMessage extends CommunityEvent {
  final int messageId;

  const DeleteMessage(this.messageId);

  @override
  List<Object?> get props => [messageId];
}

// ─── Live Socket Updates ──────────────────────────────────────────────────────

class OnLiveMessageReceived extends CommunityEvent {
  final CommunityMessageModel message;

  const OnLiveMessageReceived(this.message);

  @override
  List<Object?> get props => [message];
}

class OnLiveMessageReactionReceived extends CommunityEvent {
  final int messageId;
  final List<CommunityMessageReactionModel> reactions;

  const OnLiveMessageReactionReceived({
    required this.messageId,
    required this.reactions,
  });

  @override
  List<Object?> get props => [messageId, reactions];
}

class OnLiveMessageEdited extends CommunityEvent {
  final int messageId;
  final String message;
  final String? editedAt;

  const OnLiveMessageEdited({
    required this.messageId,
    required this.message,
    this.editedAt,
  });

  @override
  List<Object?> get props => [messageId, message, editedAt];
}

class OnLiveMessageDeleted extends CommunityEvent {
  final int messageId;

  const OnLiveMessageDeleted(this.messageId);

  @override
  List<Object?> get props => [messageId];
}

class OnLiveMessagesRead extends CommunityEvent {
  final int readerId;
  final List<int> messageIds;

  const OnLiveMessagesRead({required this.readerId, required this.messageIds});

  @override
  List<Object?> get props => [readerId, messageIds];
}

class ClearCommunityMessage extends CommunityEvent {
  const ClearCommunityMessage();
}

class ClearCommunityError extends CommunityEvent {
  const ClearCommunityError();
}
