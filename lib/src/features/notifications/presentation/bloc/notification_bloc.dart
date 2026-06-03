import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/features/notifications/data/notification_socket_service.dart';
import 'package:ntk_project/src/features/notifications/domain/repositories/notification_repository.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository _repository;
  final NotificationSocketService _socketService;
  StreamSubscription? _socketSub;

  NotificationBloc(this._repository, this._socketService)
    : super(const NotificationState()) {
    on<FetchNotifications>(_onFetchNotifications);
    on<MarkNotificationAsRead>(_onMarkAsRead);
    on<MarkAllNotificationsAsRead>(_onMarkAllAsRead);
    on<DeleteNotificationEvent>(_onDeleteNotification);

    on<ConnectNotificationSocket>(_onConnectSocket);
    on<DisconnectNotificationSocket>(_onDisconnectSocket);
    on<LiveNotificationReceived>(_onLiveNotificationReceived);
  }

  Future<void> _onFetchNotifications(
    FetchNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final notifications = await _repository.getNotifications(
        locationId: event.locationId,
        type: event.type,
      );
      emit(state.copyWith(isLoading: false, notifications: notifications));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onMarkAsRead(
    MarkNotificationAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _repository.markAsRead(event.notificationId);
      final updatedList = state.notifications.map((n) {
        if (n.id == event.notificationId) {
          return n.copyWith(isRead: true);
        }
        return n;
      }).toList();
      emit(state.copyWith(notifications: updatedList));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to mark as read: $e'));
    }
  }

  Future<void> _onMarkAllAsRead(
    MarkAllNotificationsAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _repository.markAllAsRead();
      final updatedList = state.notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
      emit(state.copyWith(notifications: updatedList));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to mark all as read: $e'));
    }
  }

  Future<void> _onDeleteNotification(
    DeleteNotificationEvent event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _repository.deleteNotification(event.notificationId);
      final updatedList = state.notifications
          .where((n) => n.id != event.notificationId)
          .toList();
      emit(state.copyWith(notifications: updatedList));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to delete notification: $e'));
    }
  }

  void _onConnectSocket(
    ConnectNotificationSocket event,
    Emitter<NotificationState> emit,
  ) {
    _socketSub?.cancel();
    _socketSub = _socketService.onNotificationReceived.listen((notification) {
      if (!isClosed) add(LiveNotificationReceived(notification));
    });
  }

  void _onDisconnectSocket(
    DisconnectNotificationSocket event,
    Emitter<NotificationState> emit,
  ) {
    _socketSub?.cancel();
  }

  void _onLiveNotificationReceived(
    LiveNotificationReceived event,
    Emitter<NotificationState> emit,
  ) {
    if (state.notifications.any((n) => n.id == event.notification.id)) return;
    emit(
      state.copyWith(
        notifications: [event.notification, ...state.notifications],
      ),
    );
  }

  @override
  Future<void> close() {
    _socketSub?.cancel();
    return super.close();
  }
}
