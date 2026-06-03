import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:ntk_project/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:ntk_project/src/core/widgets/ntk_snackbar.dart';
import 'package:ntk_project/src/injection_container.dart';

class FCMService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final AuthRepository _authRepository = sl<AuthRepository>();

  Future<void> init(GlobalKey<NavigatorState> navigatorKey) async {
    // Request permission (Apple & Web)
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint(
            'Message also contained a notification: ${message.notification}');
        
        final context = navigatorKey.currentState?.context;
        if (context != null) {
          final title = message.notification!.title ?? 'New Notification';
          final body = message.notification!.body ?? '';
          NTKSnackbar.showNotification(
            context,
            message: body.isNotEmpty ? '$title\n$body' : title,
            duration: const Duration(seconds: 5),
          );
        }
      }
    });

    // Background / Terminated notification tapped
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("Notification clicked!");
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

  void _handleNotificationNavigation(
      RemoteMessage message, GlobalKey<NavigatorState> navigatorKey) {
    final type = message.data['type'];
    if (type == 'EMERGENCY') {
      navigatorKey.currentState?.pushNamed('/emergency_details');
    } else if (type == 'CHAT') {
      navigatorKey.currentState?.pushNamed('/community');
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
