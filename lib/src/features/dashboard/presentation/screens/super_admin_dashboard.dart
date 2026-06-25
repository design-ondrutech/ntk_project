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
import 'package:ntk_project/src/features/dashboard/presentation/widgets/dashboard_location_filter.dart';
import 'package:ntk_project/src/features/dashboard/presentation/screens/dashboard_widgets.dart';
import 'package:ntk_project/src/features/users/presentation/screens/user_management_screen.dart';
import 'package:ntk_project/src/features/events/presentation/screens/events_overview_screen.dart';
import 'package:ntk_project/l10n/app_localizations.dart';
import 'package:ntk_project/src/core/widgets/ntk_app_bar.dart';
import 'package:ntk_project/src/features/location/data/models/location_model.dart';
import 'package:ntk_project/src/features/users/data/models/user_location_assignment.dart';
class SuperAdminDashboard extends StatelessWidget {
  const SuperAdminDashboard({super.key, required this.authState});

  final AuthState authState;

  @override
  Widget build(BuildContext context) {
    final name = authState.loginData?.name ?? 'Thalaivar Seeman';
    final authLocationId = authState.loginData?.locationId;
    final userId = authState.loginData?.id;

    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        final locationName = state.globalLocation?.name ?? authState.loginData?.locationName ?? state.stats?.locationName ?? 'Tamil Nadu';
        final selectedFilterLocationId = state.globalLocation?.id ?? authLocationId;

        // Combine primary location with secondary assigned locations
        final List<UserLocationAssignment> combinedAssignments = [];
        if (authLocationId != null) {
          combinedAssignments.add(UserLocationAssignment(
            id: 0,
            userId: userId ?? 0,
            locationId: authLocationId,
            isPrimary: true,
            location: LocationModel(
              id: authLocationId,
              name: authState.loginData?.locationName ?? 'Primary',
              type: 'STATE',
            ),
          ));
        }
        for (var a in state.assignedLocations) {
          if (a.locationId != authLocationId) combinedAssignments.add(a);
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),
          appBar: buildFigmaAppBar(context, locationName),
          body: authState.loginData == null
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () async {
                    context.read<DashboardBloc>().add(
                      LoadDashboardStats(authLocationId, filterLocationId: selectedFilterLocationId, userId: userId),
                    );
                    context.read<DashboardBloc>().add(
                      LoadModerationStats(selectedFilterLocationId),
                    );
                    context.read<PendingRequestsBloc>().add(
                      LoadPendingRequests(
                        locationId: selectedFilterLocationId,
                        role: 'All',
                      ),
                    );
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildGreetingText(AppLocalizations.of(context)!.vanakkam(name), AppLocalizations.of(context)!.overviewPartyAdministration),
                        const SizedBox(height: 20),
                        
                        // User Location Assignment Filter
                        DashboardLocationFilter(
                          assignments: combinedAssignments,
                          selectedLocationId: selectedFilterLocationId,
                          onLocationChanged: (newLocId) {
                            if (newLocId != null) {
                              final assignment = combinedAssignments.firstWhere((a) => a.location?.id == newLocId);
                              if (assignment.location != null) {
                                context.read<DashboardBloc>().add(UpdateGlobalLocation(assignment.location));
                                context.read<DashboardBloc>().add(LoadDashboardStats(authLocationId, filterLocationId: newLocId, userId: userId));
                                context.read<DashboardBloc>().add(LoadModerationStats(newLocId));
                              }
                            } else {
                              context.read<DashboardBloc>().add(const UpdateGlobalLocation(null));
                              context.read<DashboardBloc>().add(LoadDashboardStats(authLocationId, userId: userId));
                              context.read<DashboardBloc>().add(LoadModerationStats(authLocationId));
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        
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
                                    children: [
                                      Text(AppLocalizations.of(context)!.district, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 2),
                                      Text(AppLocalizations.of(context)!.allDistricts, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                    ],
                                  ),
                                  value: hasDistrict ? currentSelectedId : null,
                                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                                  items: [
                                    DropdownMenuItem(
                                      value: null,
                                      child: Text(AppLocalizations.of(context)!.allDistricts, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                    ),
                                    ...{ for (var d in locationState.districts) d.id: d }.values.map((d) => DropdownMenuItem(
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
                        Text(AppLocalizations.of(context)!.todaysActivity, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        const SizedBox(height: 12),
                        DashboardCarousel(
                          cards: [
                            buildHorizontalActivityCard(AppLocalizations.of(context)!.newMembersMultiLine, '${state.stats?.newMembersToday ?? 0}', const Color(0xFF004D2A), width: null),
                            buildHorizontalActivityCard(AppLocalizations.of(context)!.approved, '${state.stats?.approvedToday ?? 0}', const Color(0xFF004D2A), width: null),
                            buildHorizontalActivityCard(AppLocalizations.of(context)!.events, '${state.stats?.activeEvents ?? 0}', Colors.blue, width: null),
                            buildHorizontalActivityCard(AppLocalizations.of(context)!.broadcasts, '${state.stats?.activeBroadcasts ?? 0}', Colors.purple, width: null),
                            buildHorizontalActivityCard(AppLocalizations.of(context)!.emergencyAlertsMultiLine, '${state.stats?.emergencyRequests ?? 0}', Colors.red, width: null),
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
                              AppLocalizations.of(context)!.totalAdmins,
                              '${state.stats?.totalAdmins ?? 19}',
                              Icons.security_outlined,
                              const Color(0xFF004D2A),
                              onTap: () {
                                MainScreen.of(context)?.setSelectedIndex(1);
                                UserManagementScreen.userManagementKey.currentState?.selectTab('Admin');
                              },
                            ),
                            buildModernStatCard(
                              AppLocalizations.of(context)!.totalSubAdmins,
                              '${state.stats?.totalSubAdmins ?? 14}',
                              Icons.badge_outlined,
                              const Color(0xFF004D2A),
                              onTap: () {
                                MainScreen.of(context)?.setSelectedIndex(1);
                                UserManagementScreen.userManagementKey.currentState?.selectTab('Sub Admin');
                              },
                            ),
                            buildModernStatCard(
                              AppLocalizations.of(context)!.totalMembers,
                              '${state.stats?.totalMembers ?? 45}',
                              Icons.people_alt_outlined,
                              const Color(0xFF004D2A),
                              onTap: () {
                                MainScreen.of(context)?.setSelectedIndex(1);
                                UserManagementScreen.userManagementKey.currentState?.selectTab('Member');
                              },
                            ),
                            buildModernStatCard(
                              AppLocalizations.of(context)!.pendingRequests,
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
                        
                        // Location Requests Review Section
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/location-requests-management');
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFF59E0B).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.transfer_within_a_station_rounded, color: Colors.white, size: 24),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Review Location Requests',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Approve or reject role and location changes',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Moderation Section
                        if (state.moderationStats != null) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.reportedPosts,
                                style: const TextStyle(
                                  fontSize: 15,
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
                          const SizedBox(height: 24),
                        ],

                        
                        // Quick Actions Section
                        Text(AppLocalizations.of(context)!.quickActions, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        const SizedBox(height: 12),
                        GridView.count(
                          crossAxisCount: 4,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.95,
                          children: [
                            buildModernActionBtn(AppLocalizations.of(context)!.addAdmin, Icons.person_add_alt_1_outlined, const Color(0xFF004D2A), () async {
                              await Navigator.pushNamed(context, '/create_admin');
                              if (context.mounted) {
                                context.read<DashboardBloc>().add(LoadDashboardStats(state.globalLocation?.id ?? authState.loginData?.locationId));
                              }
                            }),
                            buildModernActionBtn(AppLocalizations.of(context)!.addSubAdmin, Icons.person_add_alt_outlined, const Color(0xFF004D2A), () async {
                              await Navigator.pushNamed(context, '/create_sub_admin');
                              if (context.mounted) {
                                context.read<DashboardBloc>().add(LoadDashboardStats(state.globalLocation?.id ?? authState.loginData?.locationId));
                              }
                            }),
                            buildModernActionBtn(AppLocalizations.of(context)!.addMember, Icons.person_add_outlined, const Color(0xFF004D2A), () async {
                              await Navigator.pushNamed(context, '/create_member');
                              if (context.mounted) {
                                context.read<DashboardBloc>().add(LoadDashboardStats(state.globalLocation?.id ?? authState.loginData?.locationId));
                              }
                            }),
                            buildModernActionBtn(AppLocalizations.of(context)!.broadcasts, Icons.campaign_outlined, const Color(0xFF004D2A), () {
                              MainScreen.of(context)?.setSelectedIndex(2);
                              EventsOverviewScreen.eventsOverviewKey.currentState?.selectTab(0, subTabIndex: 1);
                            }),
                            buildModernActionBtn(AppLocalizations.of(context)!.events, Icons.event_note_outlined, const Color(0xFF004D2A), () {
                              MainScreen.of(context)?.setSelectedIndex(2);
                              EventsOverviewScreen.eventsOverviewKey.currentState?.selectTab(1);
                            }),
                            buildModernActionBtn(AppLocalizations.of(context)!.emergencyAlert, Icons.warning_amber_rounded, Colors.red, () {
                              MainScreen.of(context)?.setSelectedIndex(2);
                              EventsOverviewScreen.eventsOverviewKey.currentState?.selectTab(0, subTabIndex: 0);
                            }),
                            buildModernActionBtn(AppLocalizations.of(context)!.requests, Icons.rule_folder_outlined, const Color(0xFF004D2A), () => Navigator.pushNamed(context, '/pending_requests')),
                            buildModernActionBtn(AppLocalizations.of(context)!.community, Icons.forum_outlined, const Color(0xFF004D2A), () => MainScreen.of(context)?.setSelectedIndex(3)),
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
