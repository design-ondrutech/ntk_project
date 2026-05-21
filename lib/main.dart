import 'package:flutter/material.dart';
import 'package:ntk_project/src/core/theme/app_theme.dart';
import 'package:ntk_project/src/features/auth/presentation/screens/login_screen.dart';
import 'package:ntk_project/src/features/dashboard/presentation/screens/main_screen.dart';
import 'package:ntk_project/src/features/requests_broadcasts/presentation/screens/requests_broadcasts_screen.dart';
import 'package:ntk_project/src/features/members/presentation/screens/members_list_screen.dart';
import 'package:ntk_project/src/features/members/presentation/screens/member_profile_screen.dart';
import 'package:ntk_project/src/features/events/presentation/screens/events_overview_screen.dart';
import 'package:ntk_project/src/features/events/presentation/screens/event_details_screen.dart';
import 'package:ntk_project/src/features/community/presentation/screens/community_feed_screen.dart';
import 'package:ntk_project/src/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:ntk_project/src/features/members/presentation/screens/add_member_screen.dart';
import 'package:ntk_project/src/features/auth/presentation/screens/verification_screen.dart';
import 'package:ntk_project/src/features/auth/presentation/screens/register_screen.dart';
import 'package:ntk_project/src/features/users/presentation/screens/create_admin_screen.dart';
import 'package:ntk_project/src/features/users/presentation/screens/create_sub_admin_screen.dart';
import 'package:ntk_project/src/features/users/presentation/screens/create_member_screen.dart';
import 'package:ntk_project/src/features/users/presentation/screens/pending_requests_screen.dart';
import 'package:ntk_project/src/features/users/presentation/screens/user_management_screen.dart';
import 'package:ntk_project/src/features/dashboard/presentation/screens/settings_screen.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/injection_container.dart' as di;
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ntk_project/src/features/location/presentation/bloc/location_bloc.dart';
import 'package:ntk_project/src/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:ntk_project/src/features/members/presentation/bloc/member_bloc.dart';
import 'package:ntk_project/src/features/events/presentation/bloc/event_bloc.dart';
import 'package:ntk_project/src/features/users/presentation/bloc/user_management_bloc.dart';
import 'package:ntk_project/src/features/users/presentation/bloc/user_bloc.dart';
import 'package:ntk_project/src/features/requests_broadcasts/presentation/bloc/pending_requests_bloc.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/community_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (context) => di.sl<AuthBloc>()),
        BlocProvider<LocationBloc>(create: (context) => di.sl<LocationBloc>()),
        BlocProvider<DashboardBloc>(
          create: (context) => di.sl<DashboardBloc>(),
        ),
        BlocProvider<MemberBloc>(create: (context) => di.sl<MemberBloc>()),
        BlocProvider<EventBloc>(create: (context) => di.sl<EventBloc>()),
        BlocProvider<UserManagementBloc>(
          create: (context) => di.sl<UserManagementBloc>(),
        ),
        BlocProvider<UserBloc>(create: (context) => di.sl<UserBloc>()),
        BlocProvider<PendingRequestsBloc>(create: (context) => di.sl<PendingRequestsBloc>()),
        BlocProvider<CommunityBloc>(create: (context) => di.sl<CommunityBloc>()),
      ],
      child: MaterialApp(
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
          '/verification': (context) => const VerificationScreen(),
          '/register': (context) => const RegisterScreen(),
          '/create_admin': (context) => MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => di.sl<LocationBloc>()),
              BlocProvider(create: (_) => di.sl<UserBloc>()),
            ],
            child: const CreateAdminScreen(),
          ),
          '/create_sub_admin': (context) => MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => di.sl<LocationBloc>()),
              BlocProvider(create: (_) => di.sl<UserBloc>()),
            ],
            child: const CreateSubAdminScreen(),
          ),
          '/create_member': (context) => MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => di.sl<LocationBloc>()),
              BlocProvider(create: (_) => di.sl<UserBloc>()),
            ],
            child: const CreateMemberScreen(),
          ),
          '/pending_requests': (context) => const PendingRequestsScreen(),
          '/user_management': (context) => const UserManagementScreen(),
          '/settings': (context) => const SettingsScreen(),
        },
      ),
    );
  }
}
