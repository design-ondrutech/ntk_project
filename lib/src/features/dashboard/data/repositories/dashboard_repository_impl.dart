import 'package:ntk_project/src/core/network/graphql_service.dart';
import 'package:ntk_project/src/features/dashboard/data/models/dashboard_stats_model.dart';
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
  Future<List<dynamic>> getRecentActivity({int? locationId, int? limit}) async {
    const String query = r'''
      query GetRecentActivity($locationId: Int, $limit: Int) {
        recentActivity(locationId: $locationId, limit: $limit) {
          ... on Event {
            id
            title
            date
            eventStatus: status
          }
          ... on EmergencyRequest {
            id
            title
            type
            requestStatus: status
          }
        }
      }
    ''';

    final result = await _graphQLService.performQuery(
      query,
      variables: {'locationId': locationId, 'limit': limit},
    );

    // Backend recentActivity resolver has a known issue with member.findMany().
    // Return empty list gracefully instead of crashing the dashboard.
    if (result.hasException) {
      return [];
    }

    return result.data?['recentActivity'] as List? ?? [];
  }
}
