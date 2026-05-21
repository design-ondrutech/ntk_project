import 'package:equatable/equatable.dart';

abstract class CommunityEvent extends Equatable {
  const CommunityEvent();

  @override
  List<Object?> get props => [];
}

class FetchCommunityFeed extends CommunityEvent {
  final int? locationId;

  const FetchCommunityFeed({this.locationId});

  @override
  List<Object?> get props => [locationId];
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
  final String? authorRole;

  const AddComment({
    required this.postId,
    required this.content,
    required this.authorName,
    this.authorRole,
  });

  @override
  List<Object?> get props => [postId, content, authorName, authorRole];
}

class CreatePost extends CommunityEvent {
  final String content;
  final String? image;
  final String authorName;
  final String? authorRole;
  final int locationId;

  const CreatePost({
    required this.content,
    this.image,
    required this.authorName,
    this.authorRole,
    required this.locationId,
  });

  @override
  List<Object?> get props => [content, image, authorName, authorRole, locationId];
}
