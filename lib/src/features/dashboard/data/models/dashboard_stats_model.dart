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

  const DashboardStatsModel({
    required this.totalMembers,
    required this.totalStreets,
    required this.activeEvents,
    required this.emergencyRequests,
    required this.totalAdmins,
    required this.totalSubAdmins,
    required this.pendingApprovals,
    required this.locationName,
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
      ];
}
