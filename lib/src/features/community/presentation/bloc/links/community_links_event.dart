import 'package:equatable/equatable.dart';

abstract class CommunityLinksEvent extends Equatable {
  const CommunityLinksEvent();

  @override
  List<Object?> get props => [];
}

class FetchCommunityMediaGalleryEvent extends CommunityLinksEvent {
  final int communityId;
  final String? mediaType;
  const FetchCommunityMediaGalleryEvent(this.communityId, {this.mediaType});

  @override
  List<Object?> get props => [communityId, mediaType];
}
