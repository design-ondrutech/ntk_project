import 'package:ntk_project/src/features/notifications/data/models/notification_model.dart';
import 'package:ntk_project/src/features/location/data/models/location_model.dart';

abstract class NotificationRepository {
  Future<List<NotificationModel>> getNotifications({
    int? locationId,
    String? type,
  });
  Future<Map<String, dynamic>> getNotificationDetails({required int id});

  Future<NotificationModel> createNotification({
    required String title,
    required String message,
    required String type,
    String? time,
    required int locationId,
  });

  Future<void> markAsRead(int notificationId);
  Future<void> markAllAsRead();
  Future<void> deleteNotification(int notificationId);

  // Forwarding methods
  Future<List<LocationModel>> getForwardLocations({
    required int entityId,
    required String type,
  });

  Future<bool> forwardNotification({
    required int entityId,
    required String type,
    required List<int> targetLocationIds,
  });

  // Settings methods
  Future<Map<String, bool>> getNotificationSettings();
  Future<void> updateNotificationSettings(Map<String, bool> settings);
}
