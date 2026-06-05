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
                  'SUB ADMIN PORTAL',
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
                                // Location selector chip/dropdown on the right
                                BlocBuilder<LocationBloc, LocationState>(
                                  builder: (context, locationState) {
                                    final currentSelectedId = state.globalLocation?.id;
                                    final listToUse = locationState.constituencies.isNotEmpty
                                        ? locationState.constituencies
                                        : locationState.districts;
                                    
                                    final hasSelected = listToUse.any((item) => item.id == currentSelectedId);

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
                                          icon: const Icon(
                                            Icons.keyboard_arrow_down,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                          value: hasSelected ? currentSelectedId : null,
                                          hint: const Icon(
                                            Icons.location_on,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                          selectedItemBuilder: (context) {
                                            return [
                                              const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.location_on, color: Colors.white, size: 18),
                                                  SizedBox(width: 4),
                                                  Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 18),
                                                ],
                                              ),
                                              ...listToUse.map((e) => const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.location_on, color: Colors.white, size: 18),
                                                  SizedBox(width: 4),
                                                  Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 18),
                                                ],
                                              )),
                                            ];
                                          },
                                          items: [
                                            DropdownMenuItem<int>(
                                              value: null,
                                              child: Text(
                                                authState.loginData?.locationName ?? 'Default Region',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            ...listToUse.map((c) => DropdownMenuItem<int>(
                                              value: c.id,
                                              child: Text(
                                                c.name,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            )).toList(),
                                          ],
                                          onChanged: (val) {
                                            final selectedLoc = val == null
                                                ? null
                                                : listToUse.firstWhere((c) => c.id == val);
                                            
                                            final targetLocName = selectedLoc?.name ?? authState.loginData?.locationName ?? 'Tamil Nadu';
                                            context.read<AuthBloc>().add(
                                              ChangeLocationRequested(
                                                locationId: val ?? authLocationId ?? 1,
                                                locationName: targetLocName,
                                              ),
                                            );
                                            
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
                        
                        // Today's Activity Section
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            "Today's Activity",
                            style: TextStyle(
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
                              context: context,
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
                              context: context,
                              title: 'Total Towns',
                              value: '${stats?.totalTowns ?? 0}',
                              subtext: 'Total towns in scope',
                              icon: Icons.location_city_outlined,
                              color: const Color(0xFF2563EB),
                            ),
                            _buildActivityCard(
                              context: context,
                              title: 'Total Streets',
                              value: '${stats?.totalStreets ?? 0}',
                              subtext: 'Total streets in scope',
                              icon: Icons.streetview_outlined,
                              color: const Color(0xFFD97706),
                            ),
                            _buildActivityCard(
                              context: context,
                              title: 'Active Events',
                              value: '${stats?.activeEvents ?? 0}',
                              subtext: 'Upcoming events',
                              icon: Icons.calendar_today_outlined,
                              color: const Color(0xFF2563EB),
                              onTap: () => MainScreen.of(context)?.setSelectedIndex(2),
                            ),
                            _buildActivityCard(
                              context: context,
                              title: 'Emergency Requests',
                              value: '${stats?.emergencyRequests ?? 0}',
                              subtext: 'Active alerts',
                              icon: Icons.warning_amber_rounded,
                              color: const Color(0xFFEF4444),
                              onTap: () => MainScreen.of(context)?.setSelectedIndex(2),
                            ),
                            _buildActivityCard(
                              context: context,
                              title: 'Active Broadcasts',
                              value: '${stats?.activeBroadcasts ?? 0}',
                              subtext: 'Active broadcasts',
                              icon: Icons.campaign_outlined,
                              color: const Color(0xFF8B5CF6),
                              onTap: () => MainScreen.of(context)?.setSelectedIndex(2),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 28),
                        
                        // Quick Actions Section
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'Quick Actions',
                            style: TextStyle(
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
                                label: 'Add Member',
                                icon: Icons.person_add_alt_1_outlined,
                                color: const Color(0xFF2563EB),
                                onTap: () => Navigator.pushNamed(context, '/add_member'),
                              ),
                              _buildQuickActionCard(
                                label: 'Broadcast',
                                icon: Icons.campaign_outlined,
                                color: const Color(0xFF10B981),
                                onTap: () => MainScreen.of(context)?.setSelectedIndex(2),
                              ),
                              _buildQuickActionCard(
                                label: 'Event',
                                icon: Icons.event_note_outlined,
                                color: const Color(0xFF2563EB),
                                onTap: () => MainScreen.of(context)?.setSelectedIndex(2),
                              ),
                              _buildQuickActionCard(
                                label: 'Emergency',
                                icon: Icons.warning_amber_rounded,
                                color: const Color(0xFFEF4444),
                                onTap: () => MainScreen.of(context)?.setSelectedIndex(2),
                              ),
                              _buildQuickActionCard(
                                label: 'Community',
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
