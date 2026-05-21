import 'package:ntk_project/src/features/notifications/data/models/notification_model.dart';

abstract class NotificationRepository {
  Future<List<NotificationModel>> getNotifications({int? locationId});

  Future<NotificationModel> createNotification({
    required String title,
    required String message,
    required String type,
    required String time,
    required int locationId,
  });
}
