import 'package:equatable/equatable.dart';

abstract class CommunityPostsEvent extends Equatable {
  const CommunityPostsEvent();

  @override
  List<Object?> get props => [];
}

class FetchCommunityPostsList extends CommunityPostsEvent {
  final int communityId;
  const FetchCommunityPostsList(this.communityId);
  @override
  List<Object?> get props => [communityId];
}

class FetchFeedPosts extends CommunityPostsEvent {
  final int? locationId;
  const FetchFeedPosts({this.locationId});
  @override
  List<Object?> get props => [locationId];
}

class CreateCommunityPostEvent extends CommunityPostsEvent {
  final int communityId;
  final String title;
  final String content;
  final String? category;
  final List<String>? images;
  final List<String>? documents;

  const CreateCommunityPostEvent({
    required this.communityId,
    required this.title,
    required this.content,
    this.category,
    this.images,
    this.documents,
  });

  @override
  List<Object?> get props => [
    communityId,
    title,
    content,
    category,
    images,
    documents,
  ];
}

class LikePostEvent extends CommunityPostsEvent {
  final int postId;
  const LikePostEvent(this.postId);
  @override
  List<Object?> get props => [postId];
}

class LikeCommunityPostEvent extends CommunityPostsEvent {
  final int postId;
  const LikeCommunityPostEvent(this.postId);
  @override
  List<Object?> get props => [postId];
}

class AddCommentEvent extends CommunityPostsEvent {
  final int postId;
  final String content;
  final String authorName;
  final String authorRole;
  const AddCommentEvent(
    this.postId,
    this.content,
    this.authorName,
    this.authorRole,
  );
  @override
  List<Object?> get props => [postId, content, authorName, authorRole];
}

class AddCommunityCommentEvent extends CommunityPostsEvent {
  final int postId;
  final String content;
  const AddCommunityCommentEvent(
    this.postId,
    this.content,
  );
  @override
  List<Object?> get props => [postId, content];
}

class EditPostEvent extends CommunityPostsEvent {
  final int postId;
  final String content;
  final List<String>? images;

  const EditPostEvent({
    required this.postId,
    required this.content,
    this.images,
  });

  @override
  List<Object?> get props => [postId, content, images];
}

class DeletePostEvent extends CommunityPostsEvent {
  final int postId;

  const DeletePostEvent(this.postId);

  @override
  List<Object?> get props => [postId];
}

class ResetCommunityPosts extends CommunityPostsEvent {
  const ResetCommunityPosts();
}
