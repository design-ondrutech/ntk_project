import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/core/theme/app_theme.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_state.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_event.dart';
import 'package:ntk_project/src/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:ntk_project/src/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:ntk_project/src/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:ntk_project/src/features/dashboard/presentation/screens/dashboard_widgets.dart';
import 'package:ntk_project/src/features/dashboard/presentation/screens/main_screen.dart';
import 'package:ntk_project/src/features/users/presentation/screens/user_management_screen.dart';
import 'package:ntk_project/src/features/location/presentation/bloc/location_bloc.dart';
import 'package:ntk_project/src/features/location/presentation/bloc/location_state.dart';
import 'package:ntk_project/src/features/location/presentation/bloc/location_event.dart';
import 'package:ntk_project/src/features/requests_broadcasts/presentation/bloc/pending_requests_bloc.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key, required this.authState});

  final AuthState authState;

  @override
  Widget build(BuildContext context) {
    final name = authState.loginData?.name ?? 'Mannargudi Admin';
    final authLocationId = authState.loginData?.locationId;

    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        final stats = state.stats;
        final locationName = state.globalLocation?.name ?? stats?.locationName ?? authState.loginData?.locationName ?? 'Your Region';

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: buildFigmaAppBar(context, locationName),
          body: RefreshIndicator(
            onRefresh: () async {
              context.read<DashboardBloc>().add(
                LoadDashboardStats(state.globalLocation?.id ?? authLocationId),
              );
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Green Greeting Card with Margins
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF004D2A),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Vanakkam, $name! 👋',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, color: Colors.white70, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      locationName,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Small location selector button on the right
                          BlocBuilder<LocationBloc, LocationState>(
                            builder: (context, locationState) {
                              final currentSelectedId = state.globalLocation?.type?.toUpperCase() == 'TALUK' 
                                  ? state.globalLocation?.id 
                                  : null;

                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    dropdownColor: const Color(0xFF004D2A),
                                    isExpanded: false,
                                    icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 18),
                                    value: currentSelectedId,
                                    hint: const Icon(Icons.location_on, color: Colors.white, size: 18),
                                    selectedItemBuilder: (context) {
                                      return [
                                        const Icon(Icons.location_on, color: Colors.white, size: 18),
                                        ...locationState.constituencies.map((e) => const Icon(Icons.location_on, color: Colors.white, size: 18)),
                                      ];
                                    },
                                    items: [
                                      DropdownMenuItem<int>(
                                        value: null,
                                        child: Text(
                                          authState.loginData?.locationName ?? 'All Constituencies',
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      ...locationState.constituencies.map((c) => DropdownMenuItem<int>(
                                        value: c.id,
                                        child: Text(
                                          c.name,
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                      )).toList(),
                                    ],
                                    onChanged: (val) {
                                      final selectedLoc = val == null 
                                          ? null 
                                          : locationState.constituencies.firstWhere((c) => c.id == val);
                                      
                                      final targetLocName = selectedLoc?.name ?? authState.loginData?.locationName ?? 'Tamil Nadu';
                                      context.read<AuthBloc>().add(ChangeLocationRequested(locationId: val ?? authLocationId ?? 1, locationName: targetLocName));
                                      
                                      context.read<DashboardBloc>().add(UpdateGlobalLocation(selectedLoc));
                                      context.read<DashboardBloc>().add(LoadDashboardStats(val ?? authLocationId ?? 1));
                                      context.read<PendingRequestsBloc>().add(LoadPendingRequests(locationId: val ?? authLocationId ?? 1));
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Today's Activity Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Today's Activity",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            'View All >',
                            style: TextStyle(
                              color: Color(0xFF004D2A),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  DashboardCarousel(
                    height: 135,
                    cards: [
                      _buildActivityCard(
                        title: 'New Members',
                        value: '${stats?.newMembersToday ?? 0}',
                        subtext: 'Registered today',
                        icon: Icons.person_add_outlined,
                        color: const Color(0xFF004D2A),
                        onTap: () {
                          MainScreen.of(context)?.setSelectedIndex(1);
                          UserManagementScreen.userManagementKey.currentState?.selectTab('Member');
                        },
                      ),
                      _buildActivityCard(
                        title: 'Approved Today',
                        value: '${stats?.approvedToday ?? 0}',
                        subtext: 'Approved today',
                        icon: Icons.how_to_reg_outlined,
                        color: const Color(0xFF10B981),
                        onTap: () {
                          MainScreen.of(context)?.setSelectedIndex(1);
                          UserManagementScreen.userManagementKey.currentState?.selectTab('Member');
                        },
                      ),
                      _buildActivityCard(
                        title: 'Total Towns',
                        value: '${stats?.totalTowns ?? 0}',
                        subtext: 'Total towns in scope',
                        icon: Icons.location_city_outlined,
                        color: const Color(0xFF2563EB),
                      ),
                      _buildActivityCard(
                        title: 'Total Streets',
                        value: '${stats?.totalStreets ?? 0}',
                        subtext: 'Total streets in scope',
                        icon: Icons.streetview_outlined,
                        color: const Color(0xFFD97706),
                      ),
                      _buildActivityCard(
                        title: 'Active Events',
                        value: '${stats?.activeEvents ?? 0}',
                        subtext: 'Upcoming events',
                        icon: Icons.calendar_today_outlined,
                        color: const Color(0xFF2563EB),
                        onTap: () => MainScreen.of(context)?.setSelectedIndex(2),
                      ),
                      _buildActivityCard(
                        title: 'Emergency Requests',
                        value: '${stats?.emergencyRequests ?? 0}',
                        subtext: 'Active alerts',
                        icon: Icons.warning_amber_rounded,
                        color: const Color(0xFFEF4444),
                        onTap: () => MainScreen.of(context)?.setSelectedIndex(2),
                      ),
                      _buildActivityCard(
                        title: 'Active Broadcasts',
                        value: '${stats?.activeBroadcasts ?? 0}',
                        subtext: 'Active broadcasts',
                        icon: Icons.campaign_outlined,
                        color: const Color(0xFF8B5CF6),
                        onTap: () => MainScreen.of(context)?.setSelectedIndex(2),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Statistics Overview Section (Horizontal List)
                  DashboardCarousel(
                    height: 150,
                    cards: [
                      _buildCustomStatCard(
                        title: 'Sub Admins',
                        value: '${stats?.totalSubAdmins ?? 0}',
                        icon: Icons.person_add_alt_1_outlined,
                        color: const Color(0xFF059669), // Green
                        actionText: 'View all',
                        onTap: () {
                          MainScreen.of(context)?.setSelectedIndex(1);
                          UserManagementScreen.userManagementKey.currentState?.selectTab('Sub Admin');
                        },
                      ),
                      _buildCustomStatCard(
                        title: 'Members',
                        value: '${stats?.totalMembers ?? 0}',
                        icon: Icons.people_alt_outlined,
                        color: const Color(0xFF2563EB), // Blue
                        actionText: 'View all',
                        onTap: () {
                          MainScreen.of(context)?.setSelectedIndex(1);
                          UserManagementScreen.userManagementKey.currentState?.selectTab('Member');
                        },
                      ),
                      _buildCustomStatCard(
                        title: 'Pending Requests',
                        value: '${stats?.pendingApprovals ?? 0}',
                        icon: Icons.assignment_late_outlined,
                        color: const Color(0xFFD97706), // Amber
                        actionText: 'View queue',
                        onTap: () {
                          Navigator.pushNamed(context, '/pending_requests');
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Quick Actions Section
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 2.8,
                      children: [
                        _buildCustomActionCard(
                          label: 'Add Sub Admin',
                          icon: Icons.person_add_alt_1_outlined,
                          color: const Color(0xFF059669),
                          onTap: () => Navigator.pushNamed(context, '/create_sub_admin'),
                        ),
                        _buildCustomActionCard(
                          label: 'Add Member',
                          icon: Icons.person_add_outlined,
                          color: const Color(0xFF2563EB),
                          onTap: () => Navigator.pushNamed(context, '/create_member'),
                        ),
                        _buildCustomActionCard(
                          label: 'Broadcast',
                          icon: Icons.campaign_outlined,
                          color: const Color(0xFF059669),
                          onTap: () => MainScreen.of(context)?.setSelectedIndex(2),
                        ),
                        _buildCustomActionCard(
                          label: 'Event',
                          icon: Icons.event_note_outlined,
                          color: const Color(0xFF2563EB),
                          onTap: () => MainScreen.of(context)?.setSelectedIndex(2),
                        ),
                        _buildCustomActionCard(
                          label: 'Emergency',
                          icon: Icons.warning_amber_rounded,
                          color: Colors.red,
                          onTap: () => MainScreen.of(context)?.setSelectedIndex(2),
                        ),
                        _buildCustomActionCard(
                          label: 'Community',
                          icon: Icons.forum_outlined,
                          color: Colors.purple,
                          onTap: () => MainScreen.of(context)?.setSelectedIndex(3),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Recent Activities Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: buildRecentActivitiesHeader(context),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: buildRecentActivitiesList(context, state.recentActivity),
                    ),
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

  // Today's Activity Card Builder
  Widget _buildActivityCard({
    required String title,
    required String value,
    required String subtext,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 16, color: color),
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
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtext,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Custom Statistics Card Builder
  Widget _buildCustomStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String actionText,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Text(
                  actionText,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 10,
                  color: color,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Custom Quick Action Button Builder
  Widget _buildCustomActionCard({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardCarousel extends StatefulWidget {
  final List<Widget> cards;
  final double height;

  const DashboardCarousel({super.key, required this.cards, this.height = 145});

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
          height: widget.height,
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
