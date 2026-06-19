import 'package:equatable/equatable.dart';

abstract class CommunityMemberEvent extends Equatable {
  const CommunityMemberEvent();

  @override
  List<Object?> get props => [];
}

class FetchCommunityMembers extends CommunityMemberEvent {
  final int communityId;

  const FetchCommunityMembers({required this.communityId});

  @override
  List<Object?> get props => [communityId];
}
