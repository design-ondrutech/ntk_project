import 'package:equatable/equatable.dart';

abstract class CommunityAdminEvent extends Equatable {
  const CommunityAdminEvent();

  @override
  List<Object?> get props => [];
}

class FetchCommunityAnalyticsEvent extends CommunityAdminEvent {
  final int communityId;
  const FetchCommunityAnalyticsEvent(this.communityId);

  @override
  List<Object?> get props => [communityId];
}

class FetchCommunityBansEvent extends CommunityAdminEvent {
  final int communityId;
  const FetchCommunityBansEvent(this.communityId);

  @override
  List<Object?> get props => [communityId];
}

class FetchJoinRequestsEvent extends CommunityAdminEvent {
  final int communityId;
  const FetchJoinRequestsEvent(this.communityId);

  @override
  List<Object?> get props => [communityId];
}

class UnbanUserEvent extends CommunityAdminEvent {
  final int communityId;
  final int userId;

  const UnbanUserEvent({required this.communityId, required this.userId});

  @override
  List<Object?> get props => [communityId, userId];
}

class ReviewJoinRequestEvent extends CommunityAdminEvent {
  final int communityId;
  final int requestId;
  final String action; // 'APPROVE' or 'REJECT'
  final String? rejectionReason;

  const ReviewJoinRequestEvent({
    required this.communityId,
    required this.requestId,
    required this.action,
    this.rejectionReason,
  });

  @override
  List<Object?> get props => [communityId, requestId, action, rejectionReason];
}

class BulkApproveJoinRequestsEvent extends CommunityAdminEvent {
  final int communityId;
  final List<int> requestIds;

  const BulkApproveJoinRequestsEvent(this.communityId, this.requestIds);

  @override
  List<Object?> get props => [communityId, requestIds];
}

class ReportCommunityMemberEvent extends CommunityAdminEvent {
  final int communityId;
  final int reportedUserId;
  final String reason;

  const ReportCommunityMemberEvent({
    required this.communityId,
    required this.reportedUserId,
    required this.reason,
  });

  @override
  List<Object?> get props => [communityId, reportedUserId, reason];
}

class ArchiveCommunityEvent extends CommunityAdminEvent {
  final int communityId;
  final bool isArchived;

  const ArchiveCommunityEvent({
    required this.communityId,
    this.isArchived = true,
  });

  @override
  List<Object?> get props => [communityId, isArchived];
}

class DeleteCommunityGroupEvent extends CommunityAdminEvent {
  final int communityId;

  const DeleteCommunityGroupEvent(this.communityId);

  @override
  List<Object?> get props => [communityId];
}

