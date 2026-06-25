import 'package:equatable/equatable.dart';
import 'package:ntk_project/src/features/community/data/models/community_analytics_model.dart';
import 'package:ntk_project/src/features/community/data/models/community_ban_model.dart';

import 'package:ntk_project/src/features/community/data/models/pending_join_request_model.dart';

class CommunityAdminState extends Equatable {
  final bool isLoadingAnalytics;
  final bool isLoadingBans;
  final bool isLoadingJoinRequests;
  final bool isApproving;
  final bool isReporting;
  final CommunityAnalyticsModel? analytics;
  final List<CommunityBanModel> bans;
  final List<PendingJoinRequestModel> joinRequests;
  final String? error;
  final String? successMessage;

  const CommunityAdminState({
    this.isLoadingAnalytics = false,
    this.isLoadingBans = false,
    this.isLoadingJoinRequests = false,
    this.isApproving = false,
    this.isReporting = false,
    this.analytics,
    this.bans = const [],
    this.joinRequests = const [],
    this.error,
    this.successMessage,
  });

  CommunityAdminState copyWith({
    bool? isLoadingAnalytics,
    bool? isLoadingBans,
    bool? isLoadingJoinRequests,
    bool? isApproving,
    bool? isReporting,
    CommunityAnalyticsModel? analytics,
    List<CommunityBanModel>? bans,
    List<PendingJoinRequestModel>? joinRequests,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return CommunityAdminState(
      isLoadingAnalytics: isLoadingAnalytics ?? this.isLoadingAnalytics,
      isLoadingBans: isLoadingBans ?? this.isLoadingBans,
      isLoadingJoinRequests: isLoadingJoinRequests ?? this.isLoadingJoinRequests,
      isApproving: isApproving ?? this.isApproving,
      isReporting: isReporting ?? this.isReporting,
      analytics: analytics ?? this.analytics,
      bans: bans ?? this.bans,
      joinRequests: joinRequests ?? this.joinRequests,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
        isLoadingAnalytics,
        isLoadingBans,
        isLoadingJoinRequests,
        isApproving,
        isReporting,
        analytics,
        bans,
        joinRequests,
        error,
        successMessage,
      ];
}
