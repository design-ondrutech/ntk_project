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
        'screen': const UserManagementScreen(),
        'label': 'Users',
        'icon': Icons.people_outline_rounded,
        'activeIcon': Icons.people_rounded,
        'roles': ['SUPER_ADMIN', 'ADMIN', 'SUB_ADMIN'],
      },
      {
        'screen': const RequestsBroadcastsScreen(),
        'label': 'Requests',
        'icon': Icons.assignment_outlined,
        'activeIcon': Icons.assignment_rounded,
        'roles': ['SUPER_ADMIN', 'ADMIN', 'SUB_ADMIN'],
      },
      {
        'screen': const CommunityFeedScreen(),
        'label': 'Community',
        'icon': Icons.forum_outlined,
        'activeIcon': Icons.forum_rounded,
        'roles': ['SUPER_ADMIN', 'ADMIN', 'SUB_ADMIN', 'MEMBER'],
      },
      {
        'screen': const EventsOverviewScreen(),
        'label': 'Events',
        'icon': Icons.event_note_outlined,
        'activeIcon': Icons.event_note_rounded,
        'roles': ['SUPER_ADMIN', 'ADMIN', 'SUB_ADMIN', 'MEMBER'],
      },
    ];

    // Filter tabs based on user role
    final List<Map<String, dynamic>> filteredTabs = allTabs
        .where((tab) => (tab['roles'] as List<String>).contains(userRole))
        .toList();

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex >= filteredTabs.length ? 0 : _selectedIndex,
        children: filteredTabs.map((tab) => tab['screen'] as Widget).toList(),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF059669), // NTK Green
          unselectedItemColor: const Color(0xFF6B7280), // Gray 500
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
                  color: isSelected ? const Color(0xFF059669).withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(isSelected ? tab['activeIcon'] : tab['icon']),
              ),
              label: tab['label'] as String,
            );
          }).toList(),
        ),
      ),
    );
  }
}
