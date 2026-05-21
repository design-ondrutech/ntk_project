import 'package:ntk_project/src/features/dashboard/data/models/dashboard_stats_model.dart';

abstract class DashboardRepository {
  Future<DashboardStatsModel> getDashboardStats(int? locationId);
  Future<List<dynamic>> getRecentActivity({int? locationId, int? limit});
}
