import 'package:ntk_project/src/core/network/graphql_service.dart';
import 'package:ntk_project/src/features/dashboard/data/models/dashboard_stats_model.dart';
import 'package:ntk_project/src/features/dashboard/data/models/moderation_stats_model.dart';
import 'package:ntk_project/src/features/dashboard/data/models/recent_activity_model.dart';
import 'package:ntk_project/src/features/dashboard/domain/repositories/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final GraphQLService _graphQLService;

  DashboardRepositoryImpl(this._graphQLService);

  @override
  Future<DashboardStatsModel> getDashboardStats(int? locationId) async {
    const String query = r'''
      query DashboardStats($locationId: Int) {
        dashboardStats(locationId: $locationId) {
          totalMembers
          totalStreets
          activeEvents
          emergencyRequests
          totalAdmins
          totalSubAdmins
          pendingApprovals
          locationName
          newMembersToday
          approvedToday
          activeBroadcasts
          totalTowns
        }
      }
    ''';

    final result = await _graphQLService.performQuery(
      query,
      variables: locationId != null ? {'locationId': locationId} : {},
    );

    if (result.hasException) {
      throw Exception(
        'Failed to fetch dashboard stats: ${result.exception.toString()}',
      );
    }

    final data = result.data?['dashboardStats'];
    if (data == null) {
      throw Exception('No dashboard data received');
    }

    return DashboardStatsModel.fromJson(data);
  }

  @override
  Future<List<RecentActivityModel>> getRecentActivity({
    int? locationId,
    int? limit,
    int? offset,
    String? search,
    String? type,
    String? fromDate,
    String? toDate,
  }) async {
    const String query = r'''
      query RecentActivity(
        $locationId: Int
        $limit: Int
        $offset: Int
        $search: String
        $type: ActivityType
        $fromDate: String
        $toDate: String
      ) {
        recentActivity(
          locationId: $locationId
          limit: $limit
          offset: $offset
          search: $search
          type: $type
          fromDate: $fromDate
          toDate: $toDate
        ) {
          id
          activityType
          title
          description
          createdAt
          member {
            id
            name
            phone
            role
          }
          location {
            id
            name
          }
        }
      }
    ''';

    final result = await _graphQLService.performQuery(
      query,
      variables: {
        'locationId': locationId,
        'limit': limit,
        'offset': offset,
        'search': search,
        'type': type,
        'fromDate': fromDate,
        'toDate': toDate,
      },
    );

    // Backend recentActivity resolver has a known issue with member.findMany().
    // Return empty list gracefully instead of crashing the dashboard.
    if (result.hasException) {
      return [];
    }

    final List data = result.data?['recentActivity'] as List? ?? [];
    return data
        .map<RecentActivityModel>(
          (json) => RecentActivityModel.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  Future<ModerationStatsModel> getModerationDashboardStats(int? locationId) async {
    const String query = r'''
      query GetModerationDashboardStats($locationId: Int) {
        getModerationDashboardStats(locationId: $locationId) {
          totalReportedPosts
          pendingReviews
          warningSentCount
          deletedPostsCount
          highPriorityReportsCount
        }
      }
    ''';

    final result = await _graphQLService.performQuery(
      query,
      variables: locationId != null ? {'locationId': locationId} : {},
    );

    if (result.hasException) {
      throw Exception(
        'Failed to fetch moderation stats: ${result.exception.toString()}',
      );
    }

    final data = result.data?['getModerationDashboardStats'];
    if (data == null) {
      throw Exception('No moderation data received');
    }

    return ModerationStatsModel.fromJson(data);
  }
}
