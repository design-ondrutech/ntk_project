import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:ntk_project/src/features/notifications/data/models/notification_model.dart';

class NotificationSocketService {
  IO.Socket? _socket;

  final _notificationController =
      StreamController<NotificationModel>.broadcast();

  Stream<NotificationModel> get onNotificationReceived =>
      _notificationController.stream;

  void connect(String token) {
    if (_socket != null && _socket!.connected) return;

    _socket = IO.io(
      'https://naam-tamilar-katchi-5.onrender.com',
      IO.OptionBuilder().setTransports(['websocket']).setExtraHeaders({
        'Authorization': 'Bearer $token',
      }).build(),
    );

    _socket?.onConnect((_) {
      print('Notification Socket.IO connected');
    });

    _socket?.on('newNotification', (data) {
      if (data != null) {
        _notificationController.add(
          NotificationModel.fromJson(data as Map<String, dynamic>),
        );
      }
    });

    _socket?.onDisconnect((_) => print('Notification Socket.IO disconnected'));
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }

  void dispose() {
    disconnect();
    _notificationController.close();
  }
}
