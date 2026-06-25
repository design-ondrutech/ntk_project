import 'package:equatable/equatable.dart';

abstract class CommunityLinksEvent extends Equatable {
  const CommunityLinksEvent();

  @override
  List<Object?> get props => [];
}

class FetchCommunityLinksEvent extends CommunityLinksEvent {
  final int communityId;
  const FetchCommunityLinksEvent(this.communityId);

  @override
  List<Object?> get props => [communityId];
}

class UploadCommunityLinkEvent extends CommunityLinksEvent {
  final int communityId;
  final String title;
  final String url;
  final String type;

  const UploadCommunityLinkEvent({
    required this.communityId,
    required this.title,
    required this.url,
    required this.type,
  });

  @override
  List<Object?> get props => [communityId, title, url, type];
}

class DeleteCommunityLinkEvent extends CommunityLinksEvent {
  final int linkId;
  const DeleteCommunityLinkEvent(this.linkId);

  @override
  List<Object?> get props => [linkId];
}
