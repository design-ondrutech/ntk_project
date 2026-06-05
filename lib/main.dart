import 'package:flutter/material.dart';
import 'package:ntk_project/src/core/theme/app_theme.dart';
import 'package:ntk_project/src/features/auth/presentation/screens/login_screen.dart';
import 'package:ntk_project/src/features/dashboard/presentation/screens/main_screen.dart';
import 'package:ntk_project/src/features/requests_broadcasts/presentation/screens/requests_broadcasts_screen.dart';
import 'package:ntk_project/src/features/requests_broadcasts/presentation/screens/create_announcement_screen.dart';
import 'package:ntk_project/src/features/members/presentation/screens/members_list_screen.dart';
import 'package:ntk_project/src/features/members/presentation/screens/member_profile_screen.dart';
import 'package:ntk_project/src/features/events/presentation/screens/events_overview_screen.dart';
import 'package:ntk_project/src/features/events/presentation/screens/event_details_screen.dart';
import 'package:ntk_project/src/features/events/presentation/screens/emergency_details_screen.dart';
import 'package:ntk_project/src/features/events/presentation/screens/all_alerts_screen.dart';
import 'package:ntk_project/src/features/events/presentation/screens/create_event_screen.dart';
import 'package:ntk_project/src/features/events/presentation/screens/event_responses_screen.dart';
import 'package:ntk_project/src/features/events/presentation/screens/member_event_response_screen.dart';
import 'package:ntk_project/src/features/events/presentation/screens/response_success_screen.dart';
import 'package:ntk_project/src/features/community/presentation/screens/community_groups_screen.dart';
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
import 'package:ntk_project/src/features/dashboard/presentation/screens/activity_log_screen.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:ntk_project/src/core/services/fcm_service.dart';


import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/injection_container.dart' as di;
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ntk_project/src/features/auth/data/models/admin_login_model.dart';
import 'package:ntk_project/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:ntk_project/src/features/location/presentation/bloc/location_bloc.dart';
import 'package:ntk_project/src/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:ntk_project/src/features/members/presentation/bloc/member_bloc.dart';
import 'package:ntk_project/src/features/events/presentation/bloc/event_bloc.dart';
import 'package:ntk_project/src/features/users/presentation/bloc/user_management_bloc.dart';
import 'package:ntk_project/src/features/users/presentation/bloc/user_bloc.dart';
import 'package:ntk_project/src/features/requests_broadcasts/presentation/bloc/pending_requests_bloc.dart';
import 'package:ntk_project/src/features/requests_broadcasts/presentation/bloc/request_bloc.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/community_bloc.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/community_list_bloc.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/community_chat_bloc.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/community_posts_bloc.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/community_polls_bloc.dart';
import 'package:ntk_project/src/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:ntk_project/src/features/notifications/presentation/bloc/notification_settings_bloc.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
    // App will continue to run even if Firebase config is missing
  }
  await di.init();
  di.sl<FCMService>().init(navigatorKey);

  final initialSession = await di.sl<AuthRepository>().getPersistedSession();

  runApp(MainApp(initialSession: initialSession));
}

class MainApp extends StatelessWidget {
  final AdminLoginModel? initialSession;
  const MainApp({super.key, this.initialSession});

  String _getInitialRoute(AdminLoginModel? session) {
    if (session == null) return '/login';
    final role = session.role;
    final status = session.approvalStatus.toUpperCase();
    if (role == 'MEMBER' && status != 'APPROVED') {
      return '/verification';
    }
    return '/dashboard';
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => di.sl<AuthBloc>(param1: initialSession),
        ),
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
        BlocProvider<RequestBloc>(create: (context) => di.sl<RequestBloc>()),
        BlocProvider<CommunityBloc>(create: (context) => di.sl<CommunityBloc>()),
        BlocProvider<CommunityListBloc>(create: (context) => di.sl<CommunityListBloc>()),
        BlocProvider<CommunityChatBloc>(create: (context) => di.sl<CommunityChatBloc>()),
        BlocProvider<CommunityPostsBloc>(create: (context) => di.sl<CommunityPostsBloc>()),
        BlocProvider<CommunityPollsBloc>(create: (context) => di.sl<CommunityPollsBloc>()),
        BlocProvider<NotificationBloc>(create: (context) => di.sl<NotificationBloc>()),
        BlocProvider<NotificationSettingsBloc>(create: (context) => di.sl<NotificationSettingsBloc>()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: _getInitialRoute(initialSession),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/dashboard': (context) => const MainScreen(),
          '/requests': (context) => const RequestsBroadcastsScreen(),
          '/members': (context) => const MembersListScreen(),
          '/profile': (context) => const MemberProfileScreen(),
          '/events': (context) => const EventsOverviewScreen(),
          '/create_event': (context) => const CreateEventScreen(),
          '/create_announcement': (context) => const CreateAnnouncementScreen(),
          '/event_details': (context) => const EventDetailsScreen(),
          '/emergency_details': (context) => const EmergencyDetailsScreen(),
          '/all_alerts': (context) {
            final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
            final type = args['type'] as String? ?? 'EMERGENCY';
            return AllAlertsScreen(type: type);
          },
          '/community': (context) => const CommunityGroupsScreen(),
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
          '/event_responses': (context) => const EventResponsesScreen(),
          '/member_event_response': (context) => const MemberEventResponseScreen(),
          '/response_success': (context) => const ResponseSuccessScreen(),
          '/activity_log': (context) => const ActivityLogScreen(),
        },
      ),
    );
  }
}
