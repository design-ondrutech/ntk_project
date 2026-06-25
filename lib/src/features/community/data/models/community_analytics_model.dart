import 'package:equatable/equatable.dart';

class CommunityAnalyticsModel extends Equatable {
  final int totalMembers;
  final int activeMembersCount;
  final int pendingJoinRequestsCount;
  final int newMembersThisWeek;
  final int eventsCreatedCount;
  final double complaintResolutionRate;

  const CommunityAnalyticsModel({
    required this.totalMembers,
    required this.activeMembersCount,
    required this.pendingJoinRequestsCount,
    required this.newMembersThisWeek,
    required this.eventsCreatedCount,
    required this.complaintResolutionRate,
  });

  factory CommunityAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return CommunityAnalyticsModel(
      totalMembers: json['totalMembers'] as int? ?? 0,
      activeMembersCount: json['activeMembersCount'] as int? ?? 0,
      pendingJoinRequestsCount: json['pendingJoinRequestsCount'] as int? ?? 0,
      newMembersThisWeek: json['newMembersThisWeek'] as int? ?? 0,
      eventsCreatedCount: json['eventsCreatedCount'] as int? ?? 0,
      complaintResolutionRate: (json['complaintResolutionRate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalMembers': totalMembers,
      'activeMembersCount': activeMembersCount,
      'pendingJoinRequestsCount': pendingJoinRequestsCount,
      'newMembersThisWeek': newMembersThisWeek,
      'eventsCreatedCount': eventsCreatedCount,
      'complaintResolutionRate': complaintResolutionRate,
    };
  }

  @override
  List<Object?> get props => [
        totalMembers,
        activeMembersCount,
        pendingJoinRequestsCount,
        newMembersThisWeek,
        eventsCreatedCount,
        complaintResolutionRate,
      ];
}
