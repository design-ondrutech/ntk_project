import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:ntk_project/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:ntk_project/src/core/widgets/ntk_snackbar.dart';
import 'package:ntk_project/src/injection_container.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';

// BLoC and State imports for real-time refresh
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ntk_project/src/features/events/presentation/bloc/event_bloc.dart';
import 'package:ntk_project/src/features/events/presentation/bloc/event_event.dart';
import 'package:ntk_project/src/features/requests_broadcasts/presentation/bloc/request_bloc.dart';
import 'package:ntk_project/src/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:ntk_project/src/features/dashboard/presentation/bloc/dashboard_event.dart';

class FCMService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final AuthRepository _authRepository = sl<AuthRepository>();

  final StreamController<RemoteMessage> _messageStreamController =
      StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get messageStream => _messageStreamController.stream;

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description: 'This channel is used for important notifications.',
    importance: Importance.max,
    playSound: true,
  );

  Future<void> init(GlobalKey<NavigatorState> navigatorKey) async {
    // Request permission (Apple & Web)
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Request permission specifically for Android 13+ via local notifications
    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    // Initialize Local Notifications
    const initializationSettingsAndroid = AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );
    const initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          try {
            final Map<String, dynamic> data = jsonDecode(response.payload!);
            final message = RemoteMessage(data: data);
            _handleNotificationNavigation(message, navigatorKey);
          } catch (e) {
            debugPrint('Error handling local notification payload: $e');
          }
        }
      },
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // Terminated state notification tapped
    FirebaseMessaging.instance.getInitialMessage().then((
      RemoteMessage? message,
    ) {
      if (message != null) {
        _handleNotificationNavigation(message, navigatorKey);
      }
    });

    // Foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      _messageStreamController.add(message);
      _refreshData(navigatorKey);

      String? title = message.notification?.title;
      String? body = message.notification?.body;

      if (title == null && message.data.isNotEmpty) {
        title =
            message.data['title'] ??
            message.data['subject'] ??
            'New Notification';
        body =
            message.data['body'] ??
            message.data['message'] ??
            message.data['description'] ??
            '';
      }

      if (title != null || body != null) {
        final displayTitle = title ?? 'New Notification';
        final displayBody = body ?? '';

        _localNotificationsPlugin.show(
          message.hashCode,
          displayTitle,
          displayBody,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: '@mipmap/launcher_icon',
              importance: Importance.max,
              priority: Priority.high,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: jsonEncode(message.data),
        );
      }
    });

    // Background / Terminated notification tapped
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("Notification clicked!");
      _refreshData(navigatorKey);
      _handleNotificationNavigation(message, navigatorKey);
    });

    // Listen to token refresh to update backend
    _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      debugPrint("FCM Token Refreshed: $newToken");
      try {
        await _authRepository.updateFcmToken(newToken);
      } catch (e) {
        debugPrint("Error updating refreshed token: $e");
      }
    });
  }

  void _refreshData(GlobalKey<NavigatorState> navigatorKey) {
    try {
      final context = navigatorKey.currentState?.context;
      if (context != null) {
        final authState = context.read<AuthBloc>().state;
        final dashboardBloc = context.read<DashboardBloc>();
        final globalLocId = dashboardBloc.state.globalLocation?.id;
        final authLocId = authState.loginData?.locationId;
        final locId = globalLocId ?? authLocId;

        context.read<EventBloc>().add(FetchEvents(locationId: locId));
        context.read<EventBloc>().add(FetchEmergencies(locationId: locId));
        context.read<RequestBloc>().add(LoadRequests(locationId: locId));

        if (locId != null) {
          context.read<DashboardBloc>().add(LoadDashboardStats(locId));
        }
      }
    } catch (e) {
      debugPrint("Failed to refresh data on FCM notification: $e");
    }
  }

  void _handleNotificationNavigation(
    RemoteMessage message,
    GlobalKey<NavigatorState> navigatorKey,
  ) {
    final type = message.data['type'];
    final requestId = message.data['requestId'];

    if (type == 'EMERGENCY') {
      if (requestId != null) {
        final id = int.tryParse(requestId.toString());
        if (id != null) {
          navigatorKey.currentState?.pushNamed(
            '/emergency_details',
            arguments: id,
          );
          return;
        }
      }
      navigatorKey.currentState?.pushNamed('/emergency_details');
    } else if (type == 'CHAT') {
      navigatorKey.currentState?.pushNamed('/community');
    } else if (type == 'REPORTED_POST' || type == 'POST_MODERATION') {
      navigatorKey.currentState?.pushNamed('/moderation_queue');
    } else {
      navigatorKey.currentState?.pushNamed('/notifications');
    }
  }

  Future<void> saveTokenToBackend() async {
    try {
      String? fcmToken = await _firebaseMessaging.getToken();
      if (fcmToken != null) {
        await _authRepository.updateFcmToken(fcmToken);
        debugPrint("Token saved to backend: $fcmToken");
      }
    } catch (e) {
      debugPrint("Failed to save FCM token to backend: $e");
    }
  }
}
