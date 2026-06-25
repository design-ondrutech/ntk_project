import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/features/community/domain/repositories/community_repository.dart';
import 'community_admin_event.dart';
import 'community_admin_state.dart';

class CommunityAdminBloc extends Bloc<CommunityAdminEvent, CommunityAdminState> {
  final CommunityRepository _repository;

  CommunityAdminBloc(this._repository) : super(const CommunityAdminState()) {
    on<FetchCommunityAnalyticsEvent>(_onFetchCommunityAnalytics);
    on<FetchCommunityBansEvent>(_onFetchCommunityBans);
    on<UnbanUserEvent>(_onUnbanUser);
    on<FetchJoinRequestsEvent>(_onFetchJoinRequests);
    on<ReviewJoinRequestEvent>(_onReviewJoinRequest);
    on<BulkApproveJoinRequestsEvent>(_onBulkApproveJoinRequests);
    on<ReportCommunityMemberEvent>(_onReportCommunityMember);
  }

  Future<void> _onFetchCommunityAnalytics(
    FetchCommunityAnalyticsEvent event,
    Emitter<CommunityAdminState> emit,
  ) async {
    emit(state.copyWith(isLoadingAnalytics: true, clearError: true));
    try {
      final analytics = await _repository.getCommunityAnalytics(communityId: event.communityId);
      emit(state.copyWith(isLoadingAnalytics: false, analytics: analytics));
    } catch (e) {
      emit(state.copyWith(isLoadingAnalytics: false, error: 'Failed to fetch analytics: $e'));
    }
  }

  Future<void> _onFetchCommunityBans(
    FetchCommunityBansEvent event,
    Emitter<CommunityAdminState> emit,
  ) async {
    emit(state.copyWith(isLoadingBans: true, clearError: true));
    try {
      final bans = await _repository.getCommunityBans(communityId: event.communityId);
      emit(state.copyWith(isLoadingBans: false, bans: bans));
    } catch (e) {
      emit(state.copyWith(isLoadingBans: false, error: 'Failed to fetch bans: $e'));
    }
  }

  Future<void> _onUnbanUser(
    UnbanUserEvent event,
    Emitter<CommunityAdminState> emit,
  ) async {
    emit(state.copyWith(isLoadingBans: true, clearError: true));
    try {
      await _repository.unbanCommunityUser(communityId: event.communityId, userId: event.userId);
      final bans = await _repository.getCommunityBans(communityId: event.communityId);
      emit(state.copyWith(isLoadingBans: false, bans: bans, successMessage: 'User unbanned successfully', clearSuccess: false));
    } catch (e) {
      emit(state.copyWith(isLoadingBans: false, error: 'Failed to unban user: $e'));
    }
  }

  Future<void> _onFetchJoinRequests(
    FetchJoinRequestsEvent event,
    Emitter<CommunityAdminState> emit,
  ) async {
    emit(state.copyWith(isLoadingJoinRequests: true, clearError: true));
    try {
      final requests = await _repository.getPendingCommunityJoinRequests(communityId: event.communityId);
      emit(state.copyWith(isLoadingJoinRequests: false, joinRequests: requests));
    } catch (e) {
      emit(state.copyWith(isLoadingJoinRequests: false, error: 'Failed to fetch join requests: $e'));
    }
  }

  Future<void> _onReviewJoinRequest(
    ReviewJoinRequestEvent event,
    Emitter<CommunityAdminState> emit,
  ) async {
    emit(state.copyWith(isApproving: true, clearError: true));
    try {
      await _repository.reviewCommunityJoinRequest(
        requestId: event.requestId,
        action: event.action,
        rejectionReason: event.rejectionReason,
      );
      final requests = await _repository.getPendingCommunityJoinRequests(communityId: event.communityId);
      emit(state.copyWith(isApproving: false, joinRequests: requests, successMessage: 'Request reviewed', clearSuccess: false));
    } catch (e) {
      emit(state.copyWith(isApproving: false, error: 'Failed to review request: $e'));
    }
  }

  Future<void> _onBulkApproveJoinRequests(
    BulkApproveJoinRequestsEvent event,
    Emitter<CommunityAdminState> emit,
  ) async {
    emit(state.copyWith(isApproving: true, clearError: true));
    try {
      await _repository.bulkApproveJoinRequests(
        communityId: event.communityId,
        requestIds: event.requestIds,
      );
      final requests = await _repository.getPendingCommunityJoinRequests(communityId: event.communityId);
      emit(state.copyWith(isApproving: false, joinRequests: requests, successMessage: 'Bulk approve successful', clearSuccess: false));
    } catch (e) {
      emit(state.copyWith(isApproving: false, error: 'Failed to bulk approve: $e'));
    }
  }

  Future<void> _onReportCommunityMember(
    ReportCommunityMemberEvent event,
    Emitter<CommunityAdminState> emit,
  ) async {
    emit(state.copyWith(isReporting: true, clearError: true));
    try {
      await _repository.reportCommunityMember(
        communityId: event.communityId,
        reportedUserId: event.reportedUserId,
        reason: event.reason,
      );
      emit(state.copyWith(isReporting: false));
    } catch (e) {
      emit(state.copyWith(isReporting: false, error: 'Failed to report member: $e'));
    }
  }
}
