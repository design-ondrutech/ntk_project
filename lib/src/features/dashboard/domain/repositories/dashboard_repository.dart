import 'package:ntk_project/src/features/dashboard/data/models/dashboard_stats_model.dart';
import 'package:ntk_project/src/features/dashboard/data/models/recent_activity_model.dart';

abstract class DashboardRepository {
  Future<DashboardStatsModel> getDashboardStats(int? locationId);
  Future<List<RecentActivityModel>> getRecentActivity({
    int? locationId,
    int? limit,
    int? offset,
    String? search,
    String? type,
    String? fromDate,
    String? toDate,
  });
}
