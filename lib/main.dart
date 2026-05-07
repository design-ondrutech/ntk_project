import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/dashboard/presentation/screens/main_screen.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'features/requests_broadcasts/presentation/screens/requests_broadcasts_screen.dart';
import 'features/members/presentation/screens/members_list_screen.dart';
import 'features/members/presentation/screens/member_profile_screen.dart';
import 'features/events/presentation/screens/events_overview_screen.dart';
import 'features/events/presentation/screens/event_details_screen.dart';
import 'features/community/presentation/screens/community_feed_screen.dart';
import 'features/notifications/presentation/screens/notifications_screen.dart';
import 'features/members/presentation/screens/add_member_screen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const MainScreen(),
        '/requests': (context) => const RequestsBroadcastsScreen(),
        '/members': (context) => const MembersListScreen(),
        '/profile': (context) => const MemberProfileScreen(),
        '/events': (context) => const EventsOverviewScreen(),
        '/event_details': (context) => const EventDetailsScreen(),
        '/community': (context) => const CommunityFeedScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/add_member': (context) => const AddMemberScreen(),
      },
    );
  }
}
