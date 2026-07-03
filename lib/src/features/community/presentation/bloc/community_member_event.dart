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

class BanCommunityMemberEvent extends CommunityMemberEvent {
  final int communityId;
  final int userId;
  final String? reason;
  final int? durationDays;

  const BanCommunityMemberEvent({
    required this.communityId,
    required this.userId,
    this.reason,
    this.durationDays,
  });

  @override
  List<Object?> get props => [communityId, userId, reason, durationDays];
}
