import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/core/theme/app_theme.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_state.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_event.dart';
import 'package:ntk_project/src/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:ntk_project/src/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:ntk_project/src/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:ntk_project/src/features/dashboard/presentation/screens/main_screen.dart';
import 'package:ntk_project/src/features/users/presentation/screens/user_management_screen.dart';
import 'package:ntk_project/src/features/location/presentation/bloc/location_bloc.dart';
import 'package:ntk_project/src/features/location/presentation/bloc/location_state.dart';
import 'package:ntk_project/src/features/requests_broadcasts/presentation/bloc/pending_requests_bloc.dart';
import 'package:ntk_project/src/features/users/presentation/screens/pending_requests_screen.dart';
import 'package:ntk_project/src/features/events/presentation/screens/events_overview_screen.dart';
import 'package:ntk_project/src/features/dashboard/presentation/screens/dashboard_widgets.dart';
import 'package:ntk_project/l10n/app_localizations.dart';
import 'package:ntk_project/src/core/widgets/ntk_app_bar.dart';

class SubAdminDashboard extends StatelessWidget {
  const SubAdminDashboard({super.key, required this.authState});

  final AuthState authState;

  @override
  Widget build(BuildContext context) {
    final name = authState.loginData?.name ?? 'Sub Admin';
    final locationNameFromLogin = authState.loginData?.locationName;
    final authLocationId = authState.loginData?.locationId;

    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        final locationName = state.globalLocation?.name ?? 
            ((locationNameFromLogin != null && locationNameFromLogin.isNotEmpty)
                ? locationNameFromLogin
                : (state.stats?.locationName != null && state.stats!.locationName.isNotEmpty)
                    ? state.stats!.locationName
                    : 'Tamil Nadu');

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
              child: buildDashboardAvatar(context),
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
                  AppLocalizations.of(context)!.subAdminPortal,
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
              IconButton(
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/notifications');
                },
              ),
            ],
          ),
          body: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () async {
                    context.read<DashboardBloc>().add(
                      LoadDashboardStats(state.globalLocation?.id ?? authLocationId),
                    );
                    context.read<DashboardBloc>().add(
                      LoadModerationStats(state.globalLocation?.id ?? authLocationId),
                    );
                    context.read<PendingRequestsBloc>().add(
                      LoadPendingRequests(
                        locationId: state.globalLocation?.id ?? authLocationId,
                        role: 'MEMBER',
                      ),
                    );
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Solid green greeting card
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF004D2A),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppLocalizations.of(context)!.vanakkam(name),
                                        style: const TextStyle(
                                          fontSize: 22,
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
                                              localizeLocationName(context, locationName),
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
                              ],
                            ),
                          ),
                        ),
                        
                        // Today's Activity Section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            AppLocalizations.of(context)!.todaysActivity,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Today's Activity carousel
                        DashboardCarousel(
                          cards: [
                            _buildActivityCard(
                              context: context,
                              title: AppLocalizations.of(context)!.newMembers,
                              value: '${stats?.newMembersToday ?? 0}',
                              subtext: AppLocalizations.of(context)!.registeredToday,
                              icon: Icons.person_add_outlined,
                              color: const Color(0xFF004D2A),
                              onTap: () {
                                MainScreen.of(context)?.setSelectedIndex(1);
                                UserManagementScreen.userManagementKey.currentState?.selectTab('Member');
                              },
                            ),
                            _buildActivityCard(
                              context: context,
                              title: AppLocalizations.of(context)!.approvedToday,
                              value: '${stats?.approvedToday ?? 0}',
                              subtext: AppLocalizations.of(context)!.approvedToday,
                              icon: Icons.how_to_reg_outlined,
                              color: const Color(0xFF10B981),
                              onTap: () {
                                MainScreen.of(context)?.setSelectedIndex(1);
                                UserManagementScreen.userManagementKey.currentState?.selectTab('Member');
                              },
                            ),
                            _buildActivityCard(
                              context: context,
                              title: AppLocalizations.of(context)!.totalTowns,
                              value: '${stats?.totalTowns ?? 0}',
                              subtext: AppLocalizations.of(context)!.totalTownsScope,
                              icon: Icons.location_city_outlined,
                              color: const Color(0xFF2563EB),
                            ),
                            _buildActivityCard(
                              context: context,
                              title: AppLocalizations.of(context)!.totalStreets,
                              value: '${stats?.totalStreets ?? 0}',
                              subtext: AppLocalizations.of(context)!.totalStreetsScope,
                              icon: Icons.streetview_outlined,
                              color: const Color(0xFFD97706),
                            ),
                            _buildActivityCard(
                              context: context,
                              title: AppLocalizations.of(context)!.activeEvents,
                              value: '${stats?.activeEvents ?? 0}',
                              subtext: AppLocalizations.of(context)!.upcomingEvents,
                              icon: Icons.calendar_today_outlined,
                              color: const Color(0xFF2563EB),
                              onTap: () {
                                MainScreen.of(context)?.setSelectedIndex(2);
                                EventsOverviewScreen.eventsOverviewKey.currentState?.selectTab(1);
                              },
                            ),
                            _buildActivityCard(
                              context: context,
                              title: AppLocalizations.of(context)!.emergencyRequests,
                              value: '${stats?.emergencyRequests ?? 0}',
                              subtext: AppLocalizations.of(context)!.activeAlerts,
                              icon: Icons.warning_amber_rounded,
                              color: const Color(0xFFEF4444),
                              onTap: () {
                                MainScreen.of(context)?.setSelectedIndex(2);
                                EventsOverviewScreen.eventsOverviewKey.currentState?.selectTab(0, subTabIndex: 0);
                              },
                            ),
                            _buildActivityCard(
                              context: context,
                              title: AppLocalizations.of(context)!.activeBroadcasts,
                              value: '${stats?.activeBroadcasts ?? 0}',
                              subtext: AppLocalizations.of(context)!.activeBroadcasts,
                              icon: Icons.campaign_outlined,
                              color: const Color(0xFF8B5CF6),
                              onTap: () {
                                MainScreen.of(context)?.setSelectedIndex(2);
                                EventsOverviewScreen.eventsOverviewKey.currentState?.selectTab(0, subTabIndex: 1);
                              },
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 28),

                        // Moderation Section
                        if (state.moderationStats != null) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.reportedPosts,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                 if ((state.moderationStats?.highPriorityReportsCount ?? 0) > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.warning_rounded, size: 14, color: Colors.red),
                                        const SizedBox(width: 4),
                                        Text(
                                          AppLocalizations.of(context)!.highPriority(state.moderationStats!.highPriorityReportsCount),
                                          style: const TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: GestureDetector(
                              onTap: () async {
                                await Navigator.pushNamed(context, '/moderation_queue');
                                if (context.mounted) {
                                  context.read<DashboardBloc>().add(LoadModerationStats(state.globalLocation?.id ?? authLocationId));
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFF1F5F9)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              AppLocalizations.of(context)!.pendingReviews,
                                              style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w600),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${state.moderationStats?.pendingReviews ?? 0}',
                                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                                            ),
                                          ],
                                        ),
                                        const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                        ],


                        // Pending Requests Section
                        BlocBuilder<PendingRequestsBloc, PendingRequestsState>(
                          builder: (context, pendingState) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        AppLocalizations.of(context)!.pendingRequests,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                      if (pendingState.requests.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEF4444).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '${pendingState.requests.length} ${AppLocalizations.of(context)!.pendingRequests}',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Color(0xFFEF4444),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  GestureDetector(
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const PendingRequestsScreen(),
                                        ),
                                      );
                                      if (context.mounted) {
                                        context.read<PendingRequestsBloc>().add(
                                          LoadPendingRequests(
                                            locationId: state.globalLocation?.id ?? authLocationId,
                                            role: 'MEMBER',
                                          ),
                                        );
                                        context.read<DashboardBloc>().add(
                                          LoadDashboardStats(state.globalLocation?.id ?? authLocationId),
                                        );
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: const Color(0xFFF1F5F9)),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.03),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: pendingState.isLoading
                                          ? const Center(
                                              child: Padding(
                                                padding: EdgeInsets.all(8.0),
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              ),
                                            )
                                          : Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.all(10),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFD97706).withOpacity(0.1),
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      child: const Icon(
                                                        Icons.pending_actions_outlined,
                                                        color: Color(0xFFD97706),
                                                        size: 20,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 16),
                                                    Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          pendingState.requests.isEmpty
                                                              ? AppLocalizations.of(context)!.noPendingRequests
                                                              : AppLocalizations.of(context)!.membersWaiting(pendingState.requests.length),
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 15,
                                                            color: Color(0xFF1E293B),
                                                          ),
                                                        ),
                                                        const SizedBox(height: 2),
                                                        Text(
                                                          pendingState.requests.isEmpty
                                                              ? AppLocalizations.of(context)!.allRequestsProcessed
                                                              : AppLocalizations.of(context)!.tapToReviewAndApprove,
                                                          style: const TextStyle(
                                                            fontSize: 12,
                                                            color: Color(0xFF94A3B8),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                const Icon(
                                                  Icons.chevron_right_rounded,
                                                  color: Color(0xFF94A3B8),
                                                  size: 20,
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 28),

                        // Quick Actions Section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            AppLocalizations.of(context)!.quickActions,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Quick Actions stacked cards
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            children: [
                              _buildQuickActionCard(
                                label: AppLocalizations.of(context)!.addMember,
                                icon: Icons.person_add_alt_1_outlined,
                                color: const Color(0xFF2563EB),
                                onTap: () async {
                                  await Navigator.pushNamed(context, '/add_member');
                                  if (context.mounted) {
                                    context.read<DashboardBloc>().add(LoadDashboardStats(state.globalLocation?.id ?? authLocationId));
                                  }
                                },
                              ),
                              _buildQuickActionCard(
                                label: AppLocalizations.of(context)!.broadcast,
                                icon: Icons.campaign_outlined,
                                color: const Color(0xFF10B981),
                                onTap: () {
                                  MainScreen.of(context)?.setSelectedIndex(2);
                                  EventsOverviewScreen.eventsOverviewKey.currentState?.selectTab(0, subTabIndex: 1);
                                },
                              ),
                              _buildQuickActionCard(
                                label: AppLocalizations.of(context)!.event,
                                icon: Icons.event_note_outlined,
                                color: const Color(0xFF2563EB),
                                onTap: () {
                                  MainScreen.of(context)?.setSelectedIndex(2);
                                  EventsOverviewScreen.eventsOverviewKey.currentState?.selectTab(1);
                                },
                              ),
                              _buildQuickActionCard(
                                label: AppLocalizations.of(context)!.emergency,
                                icon: Icons.warning_amber_rounded,
                                color: const Color(0xFFEF4444),
                                onTap: () {
                                  MainScreen.of(context)?.setSelectedIndex(2);
                                  EventsOverviewScreen.eventsOverviewKey.currentState?.selectTab(0, subTabIndex: 0);
                                },
                              ),
                              _buildQuickActionCard(
                                label: AppLocalizations.of(context)!.community,
                                icon: Icons.forum_outlined,
                                color: const Color(0xFF8B5CF6),
                                onTap: () => MainScreen.of(context)?.setSelectedIndex(3),
                              ),
                            ],
                          ),
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

  Widget _buildActivityCard({
    required BuildContext context,
    required String title,
    required String value,
    required String subtext,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
    bool isLink = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isLink ? color : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModerationCard(String title, String value, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, color: color, size: 16),
                ),
                const Spacer(),
                Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.01),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF94A3B8),
                size: 20,
              ),
            ],
          ),
        ),
      ),
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
