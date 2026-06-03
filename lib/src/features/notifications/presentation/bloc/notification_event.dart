import 'package:equatable/equatable.dart';
import 'package:ntk_project/src/features/notifications/data/models/notification_model.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class ConnectNotificationSocket extends NotificationEvent {}

class DisconnectNotificationSocket extends NotificationEvent {}

class FetchNotifications extends NotificationEvent {
  final int? locationId;
  final String? type;
  const FetchNotifications({this.locationId, this.type});
  @override
  List<Object?> get props => [locationId, type];
}

class MarkNotificationAsRead extends NotificationEvent {
  final int notificationId;
  const MarkNotificationAsRead(this.notificationId);
  @override
  List<Object?> get props => [notificationId];
}

class MarkAllNotificationsAsRead extends NotificationEvent {}

class DeleteNotificationEvent extends NotificationEvent {
  final int notificationId;
  const DeleteNotificationEvent(this.notificationId);
  @override
  List<Object?> get props => [notificationId];
}

class LiveNotificationReceived extends NotificationEvent {
  final NotificationModel notification;
  const LiveNotificationReceived(this.notification);
  @override
  List<Object?> get props => [notification];
}
