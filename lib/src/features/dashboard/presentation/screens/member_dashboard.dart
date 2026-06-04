import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_state.dart';
import 'package:ntk_project/src/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:ntk_project/src/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:ntk_project/src/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:ntk_project/src/features/dashboard/presentation/screens/main_screen.dart';

class MemberDashboard extends StatelessWidget {
  const MemberDashboard({super.key, required this.authState});

  final AuthState authState;

  @override
  Widget build(BuildContext context) {
    final name = authState.loginData?.name ?? 'Karthik';
    final locationName = authState.loginData?.locationName ?? 'கஞ்சமலைக்காடு';

    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        final stats = state.stats;

        return Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),
          appBar: AppBar(
            backgroundColor: const Color(0xFF004D2A),
            elevation: 0,
            centerTitle: false,
            automaticallyImplyLeading: false,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.grid_view_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NTK Party',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'Member Dashboard',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            actions: [
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/notifications');
                    },
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () async {
                    context.read<DashboardBloc>().add(
                      LoadDashboardStats(authState.loginData?.locationId),
                    );
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Solid green card greeting block
                        Container(
                          width: double.infinity,
                          color: const Color(0xFF004D2A),
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Vanakkam, $name! 👋',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    color: Colors.white70,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      locationName,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Today's Highlights section
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.0),
                          child: Text(
                            "Today's Highlights",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Highlights horizontal scroll row
                        SizedBox(
                          height: 135,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            children: [
                              _buildHighlightCard(
                                title: 'Total Members',
                                value: stats != null ? '${stats.totalMembers}' : '11',
                                subtext: 'Total Members',
                                icon: Icons.people_outline_rounded,
                                color: const Color(0xFF10B981),
                              ),
                              const SizedBox(width: 12),
                              _buildHighlightCard(
                                title: 'Upcoming Events',
                                value: stats != null ? '${stats.activeEvents}' : '2',
                                subtext: 'Upcoming Events',
                                icon: Icons.calendar_today_outlined,
                                color: const Color(0xFF2563EB),
                              ),
                              const SizedBox(width: 12),
                              _buildHighlightCard(
                                title: 'Active Alerts',
                                value: stats != null ? '${stats.emergencyRequests}' : '0',
                                subtext: 'Active Alerts',
                                icon: Icons.warning_amber_rounded,
                                color: const Color(0xFFEF4444),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 28),
                        
                        // Quick Actions section
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.0),
                          child: Text(
                            'Quick Actions',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Quick Actions buttons row
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCircleActionButton(
                                context: context,
                                icon: Icons.campaign_outlined,
                                color: const Color(0xFF8B5CF6),
                                label: 'Broadcasts',
                                onTap: () => MainScreen.of(context)?.setSelectedIndex(1),
                              ),
                              _buildCircleActionButton(
                                context: context,
                                icon: Icons.calendar_today_outlined,
                                color: const Color(0xFF2563EB),
                                label: 'Events',
                                onTap: () => MainScreen.of(context)?.setSelectedIndex(1),
                              ),
                              _buildCircleActionButton(
                                context: context,
                                icon: Icons.warning_amber_rounded,
                                color: const Color(0xFFEF4444),
                                label: 'Emergency',
                                onTap: () => MainScreen.of(context)?.setSelectedIndex(1),
                              ),
                              _buildCircleActionButton(
                                context: context,
                                icon: Icons.forum_outlined,
                                color: const Color(0xFF10B981),
                                label: 'Community',
                                onTap: () => MainScreen.of(context)?.setSelectedIndex(2),
                              ),
                              _buildCircleActionButton(
                                context: context,
                                icon: Icons.person_outline_rounded,
                                color: const Color(0xFF64748B),
                                label: 'My Profile',
                                onTap: () => MainScreen.of(context)?.setSelectedIndex(3),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 28),
                        
                        // Recent Updates header
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Recent Updates',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              TextButton(
                                onPressed: () => MainScreen.of(context)?.setSelectedIndex(1),
                                child: const Text(
                                  'View All',
                                  style: TextStyle(
                                    color: Color(0xFF004D2A),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Recent Updates cards
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: _buildRecentUpdatesSection(context, state),
                        ),
                        
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildHighlightCard({
    required String title,
    required String value,
    required String subtext,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 145,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subtext,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleActionButton({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentUpdateCard({
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.event_note_outlined,
              color: Color(0xFF64748B),
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            time,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentUpdatesSection(BuildContext context, DashboardState state) {
    if (state.recentActivity.isEmpty) {
      return _buildRecentUpdateCard(
        title: 'New Event Added',
        subtitle: 'District meeting scheduled for this weekend',
        time: '2 hrs ago',
      );
    }

    final list = state.recentActivity.take(3).toList();
    return Column(
      children: list.map((act) {
        final title = act.title?.isNotEmpty == true ? act.title! : act.details;
        final subtitle = act.action == 'EVENT'
            ? 'New Event Scheduled'
            : act.action == 'EMERGENCY'
                ? 'Emergency Alert Created'
                : act.action == 'BROADCAST'
                    ? 'New Broadcast Sent'
                    : act.details;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildRecentUpdateCard(
            title: title,
            subtitle: subtitle,
            time: 'Just now',
          ),
        );
      }).toList(),
    );
  }
}
