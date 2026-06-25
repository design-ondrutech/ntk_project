import 'package:equatable/equatable.dart';

abstract class CommunityListEvent extends Equatable {
  const CommunityListEvent();

  @override
  List<Object?> get props => [];
}

class FetchCommunitiesList extends CommunityListEvent {}

class SearchCommunitiesEvent extends CommunityListEvent {
  final String? query;
  final int? locationId;

  const SearchCommunitiesEvent({this.query, this.locationId});

  @override
  List<Object?> get props => [query, locationId];
}

class CreateNewCommunity extends CommunityListEvent {
  final String name;
  final String? description;
  final String? image;
  final bool allowMemberMessages;

  const CreateNewCommunity({
    required this.name,
    this.description,
    this.image,
    this.allowMemberMessages = true,
  });

  @override
  List<Object?> get props => [name, description, image, allowMemberMessages];
}

class ResetCommunityList extends CommunityListEvent {
  const ResetCommunityList();
}

class JoinCommunityGroup extends CommunityListEvent {
  final int communityId;
  final String? reason;
  final String? inviteCode;

  const JoinCommunityGroup({
    required this.communityId,
    this.reason,
    this.inviteCode,
  });

  @override
  List<Object?> get props => [communityId, reason, inviteCode];
}

class LeaveCommunityGroup extends CommunityListEvent {
  final int communityId;

  const LeaveCommunityGroup({required this.communityId});

  @override
  List<Object?> get props => [communityId];
}
