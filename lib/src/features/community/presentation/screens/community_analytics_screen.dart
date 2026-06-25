import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/core/widgets/ntk_app_bar.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/admin/community_admin_bloc.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/admin/community_admin_event.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/admin/community_admin_state.dart';

class CommunityAnalyticsScreen extends StatefulWidget {
  final int communityId;

  const CommunityAnalyticsScreen({Key? key, required this.communityId}) : super(key: key);

  @override
  State<CommunityAnalyticsScreen> createState() => _CommunityAnalyticsScreenState();
}

class _CommunityAnalyticsScreenState extends State<CommunityAnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CommunityAdminBloc>().add(FetchCommunityAnalyticsEvent(widget.communityId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      appBar: const NTKAppBar(
        title: 'Community Analytics',
        subtitle: 'Growth and engagement metrics',
      ),
      body: BlocBuilder<CommunityAdminBloc, CommunityAdminState>(
        builder: (context, state) {
          if (state.isLoadingAnalytics && state.analytics == null) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF0A3D28)));
          }

          if (state.error != null && state.analytics == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${state.error}', style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<CommunityAdminBloc>().add(FetchCommunityAnalyticsEvent(widget.communityId));
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final analytics = state.analytics;
          if (analytics == null) {
            return const Center(child: Text('No analytics data available.'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatCard(
                  icon: Icons.groups,
                  color: Colors.blue,
                  title: 'Total Members',
                  value: analytics.totalMembers.toString(),
                ),
                const SizedBox(height: 12),
                _buildStatCard(
                  icon: Icons.person_add,
                  color: Colors.green,
                  title: 'Active Members',
                  value: analytics.activeMembersCount.toString(),
                ),
                const SizedBox(height: 12),
                _buildStatCard(
                  icon: Icons.group_add,
                  color: Colors.purple,
                  title: 'Pending Join Requests',
                  value: analytics.pendingJoinRequestsCount.toString(),
                ),
                const SizedBox(height: 12),
                _buildStatCard(
                  icon: Icons.trending_up,
                  color: Colors.orange,
                  title: 'New Members This Week',
                  value: analytics.newMembersThisWeek.toString(),
                ),
                const SizedBox(height: 12),
                _buildStatCard(
                  icon: Icons.event,
                  color: Colors.teal,
                  title: 'Events Created',
                  value: analytics.eventsCreatedCount.toString(),
                ),
                const SizedBox(height: 12),
                _buildStatCard(
                  icon: Icons.check_circle_outline,
                  color: Colors.red,
                  title: 'Complaint Resolution Rate',
                  value: '${(analytics.complaintResolutionRate * 100).toStringAsFixed(1)}%',
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE7ECE9)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF667085),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
