import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_state.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_event.dart';
import 'package:ntk_project/src/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:ntk_project/src/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:ntk_project/src/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:ntk_project/src/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:ntk_project/src/features/notifications/presentation/bloc/notification_state.dart';
import 'package:ntk_project/src/features/location/presentation/bloc/location_bloc.dart';
import 'package:ntk_project/src/features/location/presentation/bloc/location_state.dart';
import 'package:ntk_project/src/features/requests_broadcasts/presentation/bloc/pending_requests_bloc.dart';
import 'package:ntk_project/src/features/dashboard/presentation/screens/main_screen.dart';
import 'package:ntk_project/src/features/dashboard/presentation/screens/dashboard_widgets.dart';
import 'package:ntk_project/src/features/users/presentation/screens/user_management_screen.dart';
import 'package:ntk_project/src/features/events/presentation/screens/events_overview_screen.dart';

class SuperAdminDashboard extends StatelessWidget {
  const SuperAdminDashboard({super.key, required this.authState});

  final AuthState authState;

  @override
  Widget build(BuildContext context) {
    final name = authState.loginData?.name ?? 'Thalaivar Seeman';
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        final locationName = state.globalLocation?.name ?? state.stats?.locationName ?? authState.loginData?.locationName ?? 'Tamil Nadu';

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5), // Light Gray
          appBar: AppBar(
            backgroundColor: const Color(0xFF004D2A), // Dark Green
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
                const Text('NTK Party', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                Text(locationName, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500, fontSize: 11, letterSpacing: 1.2)),
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
                        icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                        onPressed: () {
                          Navigator.pushNamed(context, '/notifications');
                        },
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 12,
                          top: 12,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            child: Text(
                              unreadCount > 99 ? '99+' : '$unreadCount',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
          drawer: const Drawer(), // Placeholder drawer
          body: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () async {
                    context.read<DashboardBloc>().add(LoadDashboardStats(state.globalLocation?.id ?? authState.loginData?.locationId));
                    context.read<DashboardBloc>().add(LoadModerationStats(state.globalLocation?.id ?? authState.loginData?.locationId));
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildGreetingText('Vanakkam, $name!', 'Here is an overview of the party administration.'),
                        const SizedBox(height: 20),
                        
                        // Location Filter (District)
                        BlocBuilder<LocationBloc, LocationState>(
                          builder: (context, locationState) {
                            final currentSelectedId = state.globalLocation?.id ?? authState.loginData?.locationId;
                            final hasDistrict = locationState.districts.any((d) => d.id == currentSelectedId);

                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[200]!),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  isExpanded: true,
                                  hint: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Text('District', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600)),
                                      SizedBox(height: 2),
                                      Text('All Districts', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                    ],
                                  ),
                                  value: hasDistrict ? currentSelectedId : null,
                                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                                  items: [
                                    const DropdownMenuItem(
                                      value: null,
                                      child: Text('All Districts', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                    ),
                                    ...locationState.districts.map((d) => DropdownMenuItem(
                                      value: d.id,
                                      child: Text(d.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                    )).toList(),
                                  ],
                                  onChanged: (val) {
                                    final name = val == null ? 'Tamil Nadu' : locationState.districts.firstWhere((d) => d.id == val).name;
                                    context.read<AuthBloc>().add(ChangeLocationRequested(locationId: val ?? 1, locationName: name));
                                    
                                    // Reload Dashboard data and update global location
                                    final location = val == null ? null : locationState.districts.firstWhere((d) => d.id == val);
                                    context.read<DashboardBloc>().add(UpdateGlobalLocation(location));
                                    context.read<DashboardBloc>().add(LoadDashboardStats(val ?? 1));
                                    context.read<DashboardBloc>().add(LoadModerationStats(val ?? 1));
                                    context.read<PendingRequestsBloc>().add(LoadPendingRequests(locationId: val ?? 1));
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        
                        // Today's Activity Section
                        const Text('Today\'s Activity', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        const SizedBox(height: 12),
                        DashboardCarousel(
                          cards: [
                            buildHorizontalActivityCard('New\nMembers', '${state.stats?.newMembersToday ?? 0}', const Color(0xFF004D2A), width: null),
                            buildHorizontalActivityCard('Approved', '${state.stats?.approvedToday ?? 0}', const Color(0xFF004D2A), width: null),
                            buildHorizontalActivityCard('Events', '${state.stats?.activeEvents ?? 0}', Colors.blue, width: null),
                            buildHorizontalActivityCard('Broadcasts', '${state.stats?.activeBroadcasts ?? 0}', Colors.purple, width: null),
                            buildHorizontalActivityCard('Emergency\nAlerts', '${state.stats?.emergencyRequests ?? 0}', Colors.red, width: null),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Statistics Overview Cards
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.45,
                          children: [
                            buildModernStatCard(
                              'Total Admins',
                              '${state.stats?.totalAdmins ?? 19}',
                              Icons.security_outlined,
                              const Color(0xFF004D2A),
                              onTap: () {
                                MainScreen.of(context)?.setSelectedIndex(1);
                                UserManagementScreen.userManagementKey.currentState?.selectTab('Admin');
                              },
                            ),
                            buildModernStatCard(
                              'Total Sub Admins',
                              '${state.stats?.totalSubAdmins ?? 14}',
                              Icons.badge_outlined,
                              const Color(0xFF004D2A),
                              onTap: () {
                                MainScreen.of(context)?.setSelectedIndex(1);
                                UserManagementScreen.userManagementKey.currentState?.selectTab('Sub Admin');
                              },
                            ),
                            buildModernStatCard(
                              'Total Members',
                              '${state.stats?.totalMembers ?? 45}',
                              Icons.people_alt_outlined,
                              const Color(0xFF004D2A),
                              onTap: () {
                                MainScreen.of(context)?.setSelectedIndex(1);
                                UserManagementScreen.userManagementKey.currentState?.selectTab('Member');
                              },
                            ),
                            buildModernStatCard(
                              'Pending Requests',
                              '${state.stats?.pendingApprovals ?? 0}',
                              Icons.assignment_late_outlined,
                              Colors.red,
                              onTap: () async {
                                await Navigator.pushNamed(context, '/pending_requests');
                                if (context.mounted) {
                                  context.read<DashboardBloc>().add(LoadDashboardStats(state.globalLocation?.id ?? authState.loginData?.locationId));
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const SizedBox(height: 24),
                        
                        // Moderation Section
                        if (state.moderationStats != null) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Reported Posts',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              if ((state.moderationStats?.highPriority ?? 0) > 0)
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
                                        '${state.moderationStats?.highPriority} High Priority',
                                        style: const TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () async {
                              await Navigator.pushNamed(context, '/moderation_queue');
                              if (context.mounted) {
                                context.read<DashboardBloc>().add(LoadModerationStats(state.globalLocation?.id ?? authState.loginData?.locationId));
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
                                            'Pending Reviews',
                                            style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w600),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${state.moderationStats?.pendingReviews ?? 0}',
                                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        height: 40,
                                        width: 1,
                                        color: Colors.grey[200],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Total Reports',
                                            style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w600),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${state.moderationStats?.totalReported ?? 0}',
                                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
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
                          const SizedBox(height: 24),
                        ],

                        
                        // Quick Actions Section
                        const Text('Quick Actions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        const SizedBox(height: 12),
                        GridView.count(
                          crossAxisCount: 4,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.95,
                          children: [
                            buildModernActionBtn('Add Admin', Icons.person_add_alt_1_outlined, const Color(0xFF004D2A), () async {
                              await Navigator.pushNamed(context, '/create_admin');
                              if (context.mounted) {
                                context.read<DashboardBloc>().add(LoadDashboardStats(state.globalLocation?.id ?? authState.loginData?.locationId));
                              }
                            }),
                            buildModernActionBtn('Add Sub Admin', Icons.person_add_alt_outlined, const Color(0xFF004D2A), () async {
                              await Navigator.pushNamed(context, '/create_sub_admin');
                              if (context.mounted) {
                                context.read<DashboardBloc>().add(LoadDashboardStats(state.globalLocation?.id ?? authState.loginData?.locationId));
                              }
                            }),
                            buildModernActionBtn('Add Member', Icons.person_add_outlined, const Color(0xFF004D2A), () async {
                              await Navigator.pushNamed(context, '/create_member');
                              if (context.mounted) {
                                context.read<DashboardBloc>().add(LoadDashboardStats(state.globalLocation?.id ?? authState.loginData?.locationId));
                              }
                            }),
                            buildModernActionBtn('Broadcasts', Icons.campaign_outlined, const Color(0xFF004D2A), () {
                              MainScreen.of(context)?.setSelectedIndex(2);
                              EventsOverviewScreen.eventsOverviewKey.currentState?.selectTab(0, subTabIndex: 1);
                            }),
                            buildModernActionBtn('Events', Icons.event_note_outlined, const Color(0xFF004D2A), () {
                              MainScreen.of(context)?.setSelectedIndex(2);
                              EventsOverviewScreen.eventsOverviewKey.currentState?.selectTab(1);
                            }),
                            buildModernActionBtn('Emergency Alert', Icons.warning_amber_rounded, Colors.red, () {
                              MainScreen.of(context)?.setSelectedIndex(2);
                              EventsOverviewScreen.eventsOverviewKey.currentState?.selectTab(0, subTabIndex: 0);
                            }),
                            buildModernActionBtn('Requests', Icons.rule_folder_outlined, const Color(0xFF004D2A), () => Navigator.pushNamed(context, '/pending_requests')),
                            buildModernActionBtn('Community', Icons.forum_outlined, const Color(0xFF004D2A), () => MainScreen.of(context)?.setSelectedIndex(3)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        buildRecentActivitiesHeader(context),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: buildRecentActivitiesList(context, state.recentActivity),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
        );
      },
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
          height: 106,
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
