import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_state.dart';
import 'package:ntk_project/src/core/utils/date_helper.dart';
import 'package:ntk_project/src/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:ntk_project/src/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:ntk_project/src/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:ntk_project/src/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:ntk_project/src/features/notifications/presentation/bloc/notification_state.dart';
import 'package:ntk_project/src/features/dashboard/presentation/screens/main_screen.dart';
import 'package:ntk_project/src/features/events/presentation/screens/events_overview_screen.dart';
import 'package:ntk_project/l10n/app_localizations.dart';

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
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.ntkParty,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.memberDashboard,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            actions: [
              BlocBuilder<NotificationBloc, NotificationState>(
                builder: (context, notifState) {
                  final unreadCount = notifState.notifications.where((n) => !n.isRead).length;
                  return Stack(
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
                      if (unreadCount > 0)
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
                  );
                },
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
                                AppLocalizations.of(context)!.vanakkam(name),
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
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Text(
                            AppLocalizations.of(context)!.todaysHighlights,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Highlights carousel
                        DashboardCarousel(
                          cards: [
                            _buildHighlightCard(
                              title: AppLocalizations.of(context)!.totalMembers,
                              value: stats != null ? '${stats.totalMembers}' : '11',
                              subtext: AppLocalizations.of(context)!.totalMembers,
                              icon: Icons.people_outline_rounded,
                              color: const Color(0xFF10B981),
                            ),
                            _buildHighlightCard(
                              title: AppLocalizations.of(context)!.upcomingEvents,
                              value: stats != null ? '${stats.activeEvents}' : '2',
                              subtext: AppLocalizations.of(context)!.upcomingEvents,
                              icon: Icons.calendar_today_outlined,
                              color: const Color(0xFF2563EB),
                            ),
                            _buildHighlightCard(
                              title: AppLocalizations.of(context)!.activeAlerts,
                              value: stats != null ? '${stats.emergencyRequests}' : '0',
                              subtext: AppLocalizations.of(context)!.activeAlerts,
                              icon: Icons.warning_amber_rounded,
                              color: const Color(0xFFEF4444),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 28),
                        
                        // Quick Actions section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Text(
                            AppLocalizations.of(context)!.quickActions,
                            style: const TextStyle(
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
                                label: AppLocalizations.of(context)!.broadcasts,
                                onTap: () {
                                  MainScreen.of(context)?.setSelectedIndex(1);
                                  EventsOverviewScreen.eventsOverviewKey.currentState?.selectTab(0, subTabIndex: 1);
                                },
                              ),
                              _buildCircleActionButton(
                                context: context,
                                icon: Icons.calendar_today_outlined,
                                color: const Color(0xFF2563EB),
                                label: AppLocalizations.of(context)!.events,
                                onTap: () {
                                  MainScreen.of(context)?.setSelectedIndex(1);
                                  EventsOverviewScreen.eventsOverviewKey.currentState?.selectTab(1);
                                },
                              ),
                              _buildCircleActionButton(
                                context: context,
                                icon: Icons.warning_amber_rounded,
                                color: const Color(0xFFEF4444),
                                label: AppLocalizations.of(context)!.emergency,
                                onTap: () => Navigator.pushNamed(context, '/create_announcement'),
                              ),
                              _buildCircleActionButton(
                                context: context,
                                icon: Icons.forum_outlined,
                                color: const Color(0xFF10B981),
                                label: AppLocalizations.of(context)!.community,
                                onTap: () => MainScreen.of(context)?.setSelectedIndex(2),
                              ),
                              _buildCircleActionButton(
                                context: context,
                                icon: Icons.person_outline_rounded,
                                color: const Color(0xFF64748B),
                                label: AppLocalizations.of(context)!.myProfile,
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
                              Text(
                                AppLocalizations.of(context)!.recentUpdates,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              TextButton(
                                onPressed: () => MainScreen.of(context)?.setSelectedIndex(1),
                                child: Text(
                                  AppLocalizations.of(context)!.viewAll,
                                  style: const TextStyle(
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

  String _formatActivityTime(String? value) {
    if (value == null || value.isEmpty) return 'Just now';
    try {
      final date = DateHelper.parseUtcToLocal(value);
      final diff = DateTime.now().difference(date);
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
      return 'Just now';
    } catch (_) {
      return value;
    }
  }

  Widget _buildRecentUpdatesSection(BuildContext context, DashboardState state) {
    if (state.recentActivity.isEmpty) {
      return _buildRecentUpdateCard(
        title: AppLocalizations.of(context)!.newEventAdded,
        subtitle: AppLocalizations.of(context)!.districtMeetingScheduled,
        time: '2 hrs ago',
      );
    }

    final list = state.recentActivity.take(3).toList();
    return Column(
      children: list.map((act) {
        final title = act.title?.isNotEmpty == true ? act.title! : act.details;
        final subtitle = act.action == 'EVENT'
            ? AppLocalizations.of(context)!.newEventScheduled
            : act.action == 'EMERGENCY'
                ? AppLocalizations.of(context)!.emergencyAlertCreated
                : act.action == 'BROADCAST'
                    ? AppLocalizations.of(context)!.newBroadcastSent
                    : act.details;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildRecentUpdateCard(
            title: title,
            subtitle: subtitle,
            time: _formatActivityTime(act.createdAt),
          ),
        );
      }).toList(),
    );
  }
}

class DashboardCarousel extends StatefulWidget {
  final List<Widget> cards;

  const DashboardCarousel({super.key, required this.cards});

  @override
  State<DashboardCarousel> createState() => _DashboardCarouselState();
}

class _DashboardCarouselState extends State<DashboardCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 145,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.cards.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: widget.cards[index],
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.cards.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentPage == index ? 16 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? const Color(0xFF004D2A)
                    : const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
