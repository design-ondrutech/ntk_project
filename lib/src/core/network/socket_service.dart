import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? socket;
  bool isConnected = false;

  void connect({String? url}) {
    if (socket != null && socket!.connected) return;

    final targetUrl = url ?? 'https://naam-tamilar-katchi-5.onrender.com';
    debugPrint('Connecting to socket server: $targetUrl');

    socket = IO.io(
      targetUrl,
      IO.OptionBuilder()
          .setTransports(['websocket']) // Required for Flutter
          .disableAutoConnect()
          .build(),
    );

    socket!.connect();

    socket!.onConnect((_) {
      isConnected = true;
      debugPrint('Socket connected successfully');
    });

    socket!.onDisconnect((_) {
      isConnected = false;
      debugPrint('Socket disconnected');
    });

    socket!.onConnectError((err) {
      debugPrint('Socket connection error: $err');
    });
  }

  void joinRoom(int communityId) {
    if (socket == null) {
      debugPrint('Socket not initialized. Cannot join room.');
      return;
    }
    if (!socket!.connected) {
      // Connect first, then join
      socket!.onConnect((_) {
        debugPrint('Joining room community:$communityId after connection');
        socket!.emit('join', 'community:$communityId');
      });
      socket!.connect();
      return;
    }
    debugPrint('Joining room community:$communityId');
    socket!.emit('join', 'community:$communityId');
  }

  void leaveRoom(int communityId) {
    if (socket == null || !socket!.connected) return;
    debugPrint('Leaving room community:$communityId');
    socket!.emit('leave', 'community:$communityId');
  }

  void on(String event, Function(dynamic) callback) {
    socket?.on(event, callback);
  }

  void off(String event, [Function(dynamic)? callback]) {
    if (callback != null) {
      socket?.off(event, callback);
    } else {
      socket?.off(event);
    }
  }

  void disconnect() {
    socket?.disconnect();
    socket = null;
    isConnected = false;
  }
}
