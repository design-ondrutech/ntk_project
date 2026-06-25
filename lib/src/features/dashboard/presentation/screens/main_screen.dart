import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ntk_project/src/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:ntk_project/src/features/users/presentation/screens/user_management_screen.dart';
import 'package:ntk_project/src/features/members/presentation/screens/members_list_screen.dart';
import 'package:ntk_project/src/features/requests_broadcasts/presentation/screens/requests_broadcasts_screen.dart';
import 'package:ntk_project/src/features/events/presentation/screens/events_overview_screen.dart';
import 'package:ntk_project/src/features/community/presentation/screens/community_feed_screen.dart';
import 'package:ntk_project/src/features/auth/presentation/screens/me_screen.dart';
import 'package:ntk_project/l10n/app_localizations.dart';
import 'package:ntk_project/src/core/widgets/lazy_indexed_stack.dart';

// BLoC imports for refreshing
import 'package:ntk_project/src/features/events/presentation/bloc/event_bloc.dart';
import 'package:ntk_project/src/features/events/presentation/bloc/event_event.dart';
import 'package:ntk_project/src/features/requests_broadcasts/presentation/bloc/request_bloc.dart';
import 'package:ntk_project/src/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:ntk_project/src/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:ntk_project/src/features/requests_broadcasts/presentation/bloc/pending_requests_bloc.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  static MainScreenState? of(BuildContext context) =>
      context.findAncestorStateOfType<MainScreenState>();

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshCurrentTabData();
    }
  }

  void _refreshCurrentTabData() {
    try {
      final authState = context.read<AuthBloc>().state;
      final dashboardBloc = context.read<DashboardBloc>();
      final globalLocId = dashboardBloc.state.globalLocation?.id;
      final authLocId = authState.loginData?.locationId;
      final locId = globalLocId ?? authLocId;

      final userRole = authState.loginData?.role ?? 'MEMBER';
      final List<Map<String, dynamic>> allTabs = [
        {
          'screen': const DashboardScreen(),
          'roles': ['SUPER_ADMIN', 'ADMIN', 'SUB_ADMIN', 'MEMBER'],
        },
        {
          'screen': UserManagementScreen(key: UserManagementScreen.userManagementKey),
          'roles': ['SUPER_ADMIN', 'ADMIN', 'SUB_ADMIN'],
        },
        {
          'screen': EventsOverviewScreen(key: EventsOverviewScreen.eventsOverviewKey),
          'roles': ['SUPER_ADMIN', 'ADMIN', 'SUB_ADMIN', 'MEMBER'],
        },
        {
          'screen': const CommunityFeedScreen(),
          'roles': ['SUPER_ADMIN', 'ADMIN', 'SUB_ADMIN', 'MEMBER'],
        },
        {
          'screen': const MeScreen(),
          'roles': ['SUPER_ADMIN', 'ADMIN', 'SUB_ADMIN', 'MEMBER'],
        },
      ];

      final List<Map<String, dynamic>> filteredTabs = allTabs.where((tab) {
        final roles = tab['roles'] as List<String>;
        return roles.contains(userRole);
      }).toList();

      if (_selectedIndex >= 0 && _selectedIndex < filteredTabs.length) {
        final tab = filteredTabs[_selectedIndex];
        final screen = tab['screen'];
        if (screen is EventsOverviewScreen) {
          context.read<EventBloc>().add(FetchEvents(locationId: locId));
          context.read<EventBloc>().add(FetchEmergencies(locationId: locId));
          context.read<RequestBloc>().add(LoadRequests(locationId: locId));
        } else if (screen is DashboardScreen && authLocId != null) {
          context.read<DashboardBloc>().add(LoadDashboardStats(authLocId, filterLocationId: globalLocId != authLocId ? globalLocId : null, userId: authState.loginData?.id));
          context.read<PendingRequestsBloc>().add(LoadPendingRequests(locationId: locId));
        }
      }
    } catch (e) {
      debugPrint('Error auto-refreshing tab on lifecycle resume: $e');
    }
  }

  void setSelectedIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    try {
      final authState = context.read<AuthBloc>().state;
      final userRole = authState.loginData?.role ?? 'MEMBER';
      
      final List<Map<String, dynamic>> allTabs = [
        {
          'screen': const DashboardScreen(),
          'roles': ['SUPER_ADMIN', 'ADMIN', 'SUB_ADMIN', 'MEMBER'],
        },
        {
          'screen': UserManagementScreen(key: UserManagementScreen.userManagementKey),
          'roles': ['SUPER_ADMIN', 'ADMIN', 'SUB_ADMIN'],
        },
        {
          'screen': EventsOverviewScreen(key: EventsOverviewScreen.eventsOverviewKey),
          'roles': ['SUPER_ADMIN', 'ADMIN', 'SUB_ADMIN', 'MEMBER'],
        },
        {
          'screen': const CommunityFeedScreen(),
          'roles': ['SUPER_ADMIN', 'ADMIN', 'SUB_ADMIN', 'MEMBER'],
        },
        {
          'screen': const MeScreen(),
          'roles': ['SUPER_ADMIN', 'ADMIN', 'SUB_ADMIN', 'MEMBER'],
        },
      ];

      final List<Map<String, dynamic>> filteredTabs = allTabs.where((tab) {
        final roles = tab['roles'] as List<String>;
        return roles.contains(userRole);
      }).toList();

      if (index >= 0 && index < filteredTabs.length) {
        final tab = filteredTabs[index];
        final screen = tab['screen'];
        final dashboardBloc = context.read<DashboardBloc>();
        final globalLocId = dashboardBloc.state.globalLocation?.id;
        final authLocId = authState.loginData?.locationId;
        final locId = globalLocId ?? authLocId;

        if (screen is EventsOverviewScreen) {
          context.read<EventBloc>().add(FetchEvents(locationId: locId));
          context.read<EventBloc>().add(FetchEmergencies(locationId: locId));
          context.read<RequestBloc>().add(LoadRequests(locationId: locId));
        } else if (screen is DashboardScreen && authLocId != null) {
          context.read<DashboardBloc>().add(LoadDashboardStats(authLocId, filterLocationId: globalLocId != authLocId ? globalLocId : null, userId: authState.loginData?.id));
          context.read<PendingRequestsBloc>().add(LoadPendingRequests(locationId: locId));
        }
      }
    } catch (e) {
      debugPrint('Error auto-refreshing tab on selection: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final userRole = authState.loginData?.role ?? 'MEMBER';
    final loc = AppLocalizations.of(context)!;

    // Define all possible tabs based on the new Figma design
    final List<Map<String, dynamic>> allTabs = [
      {
        'screen': const DashboardScreen(),
        'label': loc.dashboard,
        'icon': Icons.grid_view_outlined,
        'activeIcon': Icons.grid_view_rounded,
        'roles': ['SUPER_ADMIN', 'ADMIN', 'SUB_ADMIN', 'MEMBER'],
      },
      {
        'screen': UserManagementScreen(key: UserManagementScreen.userManagementKey),
        'label': loc.users,
        'icon': Icons.people_outline_rounded,
        'activeIcon': Icons.people_rounded,
        'roles': ['SUPER_ADMIN', 'ADMIN', 'SUB_ADMIN'],
      },
      {
        'screen': EventsOverviewScreen(key: EventsOverviewScreen.eventsOverviewKey),
        'label': userRole == 'MEMBER' ? loc.announcements : loc.announcements,
        'icon': Icons.assignment_outlined,
        'activeIcon': Icons.assignment_rounded,
        'roles': ['SUPER_ADMIN', 'ADMIN', 'SUB_ADMIN', 'MEMBER'],
      },
      {
        'screen': const CommunityFeedScreen(),
        'label': loc.community,
        'icon': Icons.forum_outlined,
        'activeIcon': Icons.forum_rounded,
        'roles': ['SUPER_ADMIN', 'ADMIN', 'SUB_ADMIN', 'MEMBER'],
      },
      {
        'screen': const MeScreen(),
        'label': loc.me,
        'icon': Icons.person_outline_rounded,
        'activeIcon': Icons.person_rounded,
        'roles': ['SUPER_ADMIN', 'ADMIN', 'SUB_ADMIN', 'MEMBER'],
      },
    ];

    // Filter tabs based on user role
    final List<Map<String, dynamic>> filteredTabs = allTabs.where((tab) {
      final roles = tab['roles'] as List<String>;
      return roles.contains(userRole);
    }).toList();

    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
        }
      },
      child: Scaffold(
        body: LazyIndexedStack(
          index: _selectedIndex >= filteredTabs.length ? 0 : _selectedIndex,
          children: filteredTabs.map((tab) => tab['screen'] as Widget).toList(),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF004D2A),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex >= filteredTabs.length
                ? 0
                : _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: const Color(0xFF004D2A),
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white70,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            elevation: 0,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            items: filteredTabs.map((tab) {
              final isSelected = filteredTabs.indexOf(tab) == _selectedIndex;
              return BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white.withOpacity(0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(isSelected ? tab['activeIcon'] : tab['icon']),
                ),
                label: tab['label'] as String,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
