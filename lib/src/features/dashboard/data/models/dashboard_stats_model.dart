import 'package:equatable/equatable.dart';

class DashboardStatsModel extends Equatable {
  final int totalMembers;
  final int totalStreets;
  final int activeEvents;
  final int emergencyRequests;
  final int totalAdmins;
  final int totalSubAdmins;
  final int pendingApprovals;
  final String locationName;
  final int newMembersToday;
  final int approvedToday;
  final int activeBroadcasts;
  final int totalTowns;

  const DashboardStatsModel({
    required this.totalMembers,
    required this.totalStreets,
    required this.activeEvents,
    required this.emergencyRequests,
    required this.totalAdmins,
    required this.totalSubAdmins,
    required this.pendingApprovals,
    required this.locationName,
    required this.newMembersToday,
    required this.approvedToday,
    required this.activeBroadcasts,
    required this.totalTowns,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardStatsModel(
      totalMembers: json['totalMembers'] ?? 0,
      totalStreets: json['totalStreets'] ?? 0,
      activeEvents: json['activeEvents'] ?? 0,
      emergencyRequests: json['emergencyRequests'] ?? 0,
      totalAdmins: json['totalAdmins'] ?? 0,
      totalSubAdmins: json['totalSubAdmins'] ?? 0,
      pendingApprovals: json['pendingApprovals'] ?? 0,
      locationName: json['locationName'] ?? '',
      newMembersToday: json['newMembersToday'] ?? 0,
      approvedToday: json['approvedToday'] ?? 0,
      activeBroadcasts: json['activeBroadcasts'] ?? 0,
      totalTowns: json['totalTowns'] ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        totalMembers,
        totalStreets,
        activeEvents,
        emergencyRequests,
        totalAdmins,
        totalSubAdmins,
        pendingApprovals,
        locationName,
        newMembersToday,
        approvedToday,
        activeBroadcasts,
        totalTowns,
      ];
}
