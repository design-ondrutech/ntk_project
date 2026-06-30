import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:ntk_project/src/core/theme/app_theme.dart';
import 'package:ntk_project/src/features/auth/presentation/screens/login_screen.dart';
import 'package:ntk_project/src/features/dashboard/presentation/screens/main_screen.dart';
import 'package:ntk_project/src/features/requests_broadcasts/presentation/screens/requests_broadcasts_screen.dart';
import 'package:ntk_project/src/features/requests_broadcasts/presentation/screens/create_announcement_screen.dart';
import 'package:ntk_project/src/features/requests_broadcasts/presentation/screens/broadcast_details_screen.dart';
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
import 'package:ntk_project/src/features/community/presentation/screens/moderation_queue_screen.dart';
import 'package:ntk_project/src/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:ntk_project/src/features/members/presentation/screens/add_member_screen.dart';
import 'package:ntk_project/src/features/auth/presentation/screens/verification_screen.dart';
import 'package:ntk_project/src/features/auth/presentation/screens/register_screen.dart';
import 'package:ntk_project/src/features/users/presentation/screens/create_admin_screen.dart';
import 'package:ntk_project/src/features/users/presentation/screens/create_sub_admin_screen.dart';
import 'package:ntk_project/src/features/users/presentation/screens/create_district_incharge_screen.dart';
import 'package:ntk_project/src/features/users/presentation/screens/create_member_screen.dart';
import 'package:ntk_project/src/features/users/presentation/screens/pending_requests_screen.dart';
import 'package:ntk_project/src/features/users/presentation/screens/user_management_screen.dart';
import 'package:ntk_project/src/features/dashboard/presentation/screens/settings_screen.dart';
import 'package:ntk_project/src/features/dashboard/presentation/screens/activity_log_screen.dart';
import 'package:ntk_project/src/features/auth/presentation/screens/edit_profile_screen.dart';
import 'package:ntk_project/src/features/auth/presentation/screens/change_password_screen.dart';
import 'package:ntk_project/src/features/users/presentation/screens/location_access_request_screen.dart';
import 'package:ntk_project/src/features/users/presentation/screens/my_location_requests_screen.dart';
import 'package:ntk_project/src/features/users/presentation/screens/location_requests_management_screen.dart';
import 'package:ntk_project/src/features/users/presentation/screens/user_locations_management_screen.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import 'package:ntk_project/src/core/services/fcm_service.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:ntk_project/src/core/network/graphql_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/injection_container.dart' as di;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ntk_project/l10n/app_localizations.dart';
import 'package:ntk_project/src/features/dashboard/presentation/bloc/language_cubit.dart';
import 'package:ntk_project/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ntk_project/src/features/auth/data/models/admin_login_model.dart';
import 'package:ntk_project/src/features/location/presentation/bloc/location_bloc.dart';
import 'package:ntk_project/src/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:ntk_project/src/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:ntk_project/src/features/members/presentation/bloc/member_bloc.dart';
import 'package:ntk_project/src/features/members/presentation/bloc/member_event.dart';
import 'package:ntk_project/src/features/events/presentation/bloc/event_bloc.dart';
import 'package:ntk_project/src/features/events/presentation/bloc/event_event.dart';
import 'package:ntk_project/src/features/users/presentation/bloc/user_management_bloc.dart';
import 'package:ntk_project/src/features/users/presentation/bloc/user_management_event.dart';
import 'package:ntk_project/src/features/users/presentation/bloc/user_bloc.dart';
import 'package:ntk_project/src/features/requests_broadcasts/presentation/bloc/pending_requests_bloc.dart';
import 'package:ntk_project/src/features/requests_broadcasts/presentation/bloc/request_bloc.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/community_bloc.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/community_list_bloc.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/community_list_event.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/community_member_bloc.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/community_chat_bloc.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/community_posts_bloc.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/community_posts_event.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/community_polls_bloc.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/moderation_queue/moderation_queue_bloc.dart';
import 'package:ntk_project/src/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:ntk_project/src/features/notifications/presentation/bloc/notification_settings_bloc.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");

  // Show a local notification for data-only messages
  if (message.notification == null && message.data.isNotEmpty) {
    String title =
        message.data['title'] ?? message.data['subject'] ?? 'New Notification';
    String body =
        message.data['body'] ??
        message.data['message'] ??
        message.data['description'] ??
        '';

    final FlutterLocalNotificationsPlugin localNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(),
    );

    await localNotificationsPlugin.show(
      message.hashCode,
      title,
      body,
      platformChannelSpecifics,
      payload: jsonEncode(message.data),
    );
  }
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
  if (initialSession != null) {
    di.sl<FCMService>().saveTokenToBackend();
  }

  final prefs = await SharedPreferences.getInstance();
  String langCode = prefs.getString('languageCode') ?? 'en';
  if (langCode != 'en' && langCode != 'ta') {
    langCode = 'en';
  }
  di.sl<GraphQLService>().setLanguage(langCode);

  runApp(MainApp(initialSession: initialSession, languageCode: langCode));
}

class MainApp extends StatelessWidget {
  final AdminLoginModel? initialSession;
  final String languageCode;
  const MainApp({super.key, this.initialSession, required this.languageCode});

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
        BlocProvider<PendingRequestsBloc>(
          create: (context) => di.sl<PendingRequestsBloc>(),
        ),
        BlocProvider<RequestBloc>(create: (context) => di.sl<RequestBloc>()),
        BlocProvider<CommunityBloc>(
          create: (context) => di.sl<CommunityBloc>(),
        ),
        BlocProvider<CommunityListBloc>(
          create: (context) => di.sl<CommunityListBloc>(),
        ),
        BlocProvider<CommunityMemberBloc>(
          create: (context) => di.sl<CommunityMemberBloc>(),
        ),
        BlocProvider<CommunityChatBloc>(
          create: (context) => di.sl<CommunityChatBloc>(),
        ),
        BlocProvider<CommunityPostsBloc>(
          create: (context) => di.sl<CommunityPostsBloc>(),
        ),
        BlocProvider<CommunityPollsBloc>(
          create: (context) => di.sl<CommunityPollsBloc>(),
        ),
        BlocProvider<ModerationQueueBloc>(
          create: (context) => di.sl<ModerationQueueBloc>(),
        ),
        BlocProvider<NotificationBloc>(
          create: (context) => di.sl<NotificationBloc>(),
        ),
        BlocProvider<NotificationSettingsBloc>(
          create: (context) => di.sl<NotificationSettingsBloc>(),
        ),
        BlocProvider<LanguageCubit>(
          create: (context) => LanguageCubit(languageCode),
        ),
      ],
      child: BlocBuilder<LanguageCubit, Locale>(
        builder: (context, locale) {
          return BlocListener<AuthBloc, AuthState>(
            listenWhen: (previous, current) =>
                previous.loginData != null && current.loginData == null,
            listener: (context, state) {
              context.read<RequestBloc>().add(ResetRequests());
              context.read<EventBloc>().add(const ResetEvents());
              context.read<DashboardBloc>().add(const ResetDashboard());
              context.read<MemberBloc>().add(const ResetMembers());
              context.read<CommunityListBloc>().add(const ResetCommunityList());
              context.read<CommunityPostsBloc>().add(
                const ResetCommunityPosts(),
              );
              context.read<UserManagementBloc>().add(const ResetUserManagement());
              context.read<PendingRequestsBloc>().add(const ResetPendingRequests());
            },
            child: MaterialApp(
              navigatorKey: navigatorKey,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              locale: locale,
              supportedLocales: const [Locale('en'), Locale('ta')],
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              builder: (context, child) {
                return ValueListenableBuilder<bool>(
                  valueListenable: di.sl<GraphQLService>().connectionStatus,
                  builder: (context, isConnected, _) {
                    return Stack(
                      children: [
                        if (child != null) child,
                        if (!isConnected)
                          Positioned.fill(
                            child: NoInternetOverlay(
                              errorDetails: di.sl<GraphQLService>().lastNetworkError.value,
                              onRetry: () async {
                                try {
                                  final response = await http
                                      .get(Uri.parse('https://www.google.com'))
                                      .timeout(const Duration(seconds: 5));
                                  if (response.statusCode >= 200 &&
                                      response.statusCode < 400) {
                                    di
                                            .sl<GraphQLService>()
                                            .connectionStatus
                                            .value =
                                        true;
                                    final ctx = navigatorKey.currentContext;
                                    if (ctx != null) {
                                      try {
                                        final authState = ctx
                                            .read<AuthBloc>()
                                            .state;
                                        final locationId =
                                            authState.loginData?.locationId;
                                        ctx.read<DashboardBloc>().add(
                                          LoadDashboardStats(locationId ?? 1),
                                        );
                                      } catch (_) {}
                                      try {
                                        final authState = ctx
                                            .read<AuthBloc>()
                                            .state;
                                        final locationId =
                                            authState.loginData?.locationId;
                                        ctx.read<MemberBloc>().add(
                                          LoadMembers(locationId: locationId),
                                        );
                                      } catch (_) {}
                                      try {
                                        ctx.read<EventBloc>().add(
                                          const FetchEvents(),
                                        );
                                      } catch (_) {}
                                      try {
                                        ctx.read<RequestBloc>().add(
                                          LoadRequests(),
                                        );
                                      } catch (_) {}
                                    }
                                  }
                                } catch (_) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Still no internet connection. Please check your network.',
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
              initialRoute: _getInitialRoute(initialSession),
              routes: {
                '/location-access-request': (context) =>
                    const LocationAccessRequestScreen(),
                '/location-requests-management': (context) =>
                    const LocationRequestsManagementScreen(),
                '/my-location-requests': (context) =>
                    const MyLocationRequestsScreen(),
                '/user-locations': (context) {
                  final userId =
                      ModalRoute.of(context)!.settings.arguments as int;
                  return UserLocationsManagementScreen(userId: userId);
                },
                '/login': (context) => const LoginScreen(),
                '/dashboard': (context) => const MainScreen(),
                '/requests': (context) => const RequestsBroadcastsScreen(),
                '/broadcast_details': (context) =>
                    const BroadcastDetailsScreen(),
                '/members': (context) => const MembersListScreen(),
                '/profile': (context) => const MemberProfileScreen(),
                '/events': (context) => const EventsOverviewScreen(),
                '/create_event': (context) => const CreateEventScreen(),
                '/create_announcement': (context) =>
                    const CreateAnnouncementScreen(),
                '/event_details': (context) => const EventDetailsScreen(),
                '/emergency_details': (context) =>
                    const EmergencyDetailsScreen(),
                '/all_alerts': (context) {
                  final args =
                      ModalRoute.of(context)?.settings.arguments
                          as Map<String, dynamic>? ??
                      {};
                  final type = args['type'] as String? ?? 'EMERGENCY';
                  return AllAlertsScreen(type: type);
                },
                '/community': (context) => const CommunityGroupsScreen(),
                '/moderation_queue': (context) => const ModerationQueueScreen(),
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
                '/create_district_incharge': (context) => MultiBlocProvider(
                  providers: [
                    BlocProvider(create: (_) => di.sl<LocationBloc>()),
                    BlocProvider(create: (_) => di.sl<UserBloc>()),
                  ],
                  child: const CreateDistrictInchargeScreen(),
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
                '/member_event_response': (context) =>
                    const MemberEventResponseScreen(),
                '/response_success': (context) => const ResponseSuccessScreen(),
                '/activity_log': (context) => const ActivityLogScreen(),
                '/edit-profile': (context) => const EditProfileScreen(),
                '/change-password': (context) => const ChangePasswordScreen(),
              },
            ),
          );
        },
      ),
    );
  }
}

class NoInternetOverlay extends StatefulWidget {
  final Future<void> Function() onRetry;
  final String? errorDetails;

  const NoInternetOverlay({super.key, required this.onRetry, this.errorDetails});

  @override
  State<NoInternetOverlay> createState() => _NoInternetOverlayState();
}

class _NoInternetOverlayState extends State<NoInternetOverlay> {
  bool _isChecking = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    CupertinoIcons.exclamationmark_circle_fill,
                    size: 64,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Connection Issue',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Please check your network or wait a moment while our server wakes up, then try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isChecking
                      ? null
                      : () async {
                          setState(() => _isChecking = true);
                          await widget.onRetry();
                          if (mounted) setState(() => _isChecking = false);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF004D2A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isChecking
                      ? const CupertinoActivityIndicator(color: Colors.white)
                      : const Text(
                          'Retry',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
