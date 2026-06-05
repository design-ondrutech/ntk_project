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

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  static MainScreenState? of(BuildContext context) =>
      context.findAncestorStateOfType<MainScreenState>();

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  void setSelectedIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final userRole = authState.loginData?.role ?? 'MEMBER';

    // Define all possible tabs based on the new Figma design
    final List<Map<String, dynamic>> allTabs = [
      {
        'screen': const DashboardScreen(),
        'label': 'Dashboard',
        'icon': Icons.grid_view_outlined,
        'activeIcon': Icons.grid_view_rounded,
        'roles': ['SUPER_ADMIN', 'ADMIN', 'SUB_ADMIN', 'MEMBER'],
      },
      {
        'screen': UserManagementScreen(key: UserManagementScreen.userManagementKey),
        'label': 'Users',
        'icon': Icons.people_outline_rounded,
        'activeIcon': Icons.people_rounded,
        'roles': ['SUPER_ADMIN', 'ADMIN', 'SUB_ADMIN'],
      },
      {
        'screen': const EventsOverviewScreen(),
        'label': userRole == 'MEMBER' ? 'Announcements' : 'Announcem...',
        'icon': Icons.assignment_outlined,
        'activeIcon': Icons.assignment_rounded,
        'roles': ['SUPER_ADMIN', 'ADMIN', 'SUB_ADMIN', 'MEMBER'],
      },
      {
        'screen': const CommunityFeedScreen(),
        'label': 'Community',
        'icon': Icons.forum_outlined,
        'activeIcon': Icons.forum_rounded,
        'roles': ['SUPER_ADMIN', 'ADMIN', 'SUB_ADMIN', 'MEMBER'],
      },
      {
        'screen': const MeScreen(),
        'label': 'Me',
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
        body: IndexedStack(
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
