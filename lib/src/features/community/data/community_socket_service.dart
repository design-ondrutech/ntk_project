import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:ntk_project/src/features/community/data/models/community_message_model.dart';
import 'package:ntk_project/src/features/community/data/models/community_model.dart';

class CommunitySocketService {
  IO.Socket? _socket;

  final _messageController =
      StreamController<CommunityMessageModel>.broadcast();
  final _messageEditedController =
      StreamController<CommunityMessageModel>.broadcast();
  final _messageDeletedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _messageReactionController =
      StreamController<CommunityMessageModel>.broadcast();
  final _messagesReadController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _settingsUpdatedController =
      StreamController<CommunityModel>.broadcast();
  final _memberMutedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _memberRemovedController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<CommunityMessageModel> get onMessageReceived =>
      _messageController.stream;
  Stream<CommunityMessageModel> get onMessageEdited =>
      _messageEditedController.stream;
  Stream<Map<String, dynamic>> get onMessageDeleted =>
      _messageDeletedController.stream;
  Stream<CommunityMessageModel> get onMessageReaction =>
      _messageReactionController.stream;
  Stream<Map<String, dynamic>> get onMessagesRead =>
      _messagesReadController.stream;
  Stream<CommunityModel> get onSettingsUpdated =>
      _settingsUpdatedController.stream;
  Stream<Map<String, dynamic>> get onMemberMuted =>
      _memberMutedController.stream;
  Stream<Map<String, dynamic>> get onMemberRemoved =>
      _memberRemovedController.stream;

  void connect(String token) {
    if (_socket != null && _socket!.connected) return;

    _socket = IO.io(
      'https://naam-tamilar-katchi.onrender.com',
      IO.OptionBuilder().setTransports(['websocket']).setExtraHeaders({
        'Authorization': 'Bearer $token',
      }).build(),
    );

    _socket?.onConnect((_) {
      print('Socket.IO connected');
    });

    _socket?.on('communityMessage', (data) {
      if (data != null) {
        _messageController.add(
          CommunityMessageModel.fromJson(data as Map<String, dynamic>),
        );
      }
    });

    _socket?.on('communityMessageEdited', (data) {
      if (data != null) {
        _messageEditedController.add(
          CommunityMessageModel.fromJson(data as Map<String, dynamic>),
        );
      }
    });

    _socket?.on('communityMessageDeleted', (data) {
      if (data != null) {
        _messageDeletedController.add(data as Map<String, dynamic>);
      }
    });

    _socket?.on('communityMessageReaction', (data) {
      if (data != null) {
        _messageReactionController.add(
          CommunityMessageModel.fromJson(data as Map<String, dynamic>),
        );
      }
    });

    _socket?.on('communityMessagesRead', (data) {
      if (data != null) {
        _messagesReadController.add(data as Map<String, dynamic>);
      }
    });

    _socket?.on('communityChatSettingsUpdated', (data) {
      if (data != null) {
        _settingsUpdatedController.add(
          CommunityModel.fromJson(data as Map<String, dynamic>),
        );
      }
    });

    _socket?.on('communityMemberMuted', (data) {
      if (data != null) {
        _memberMutedController.add(data as Map<String, dynamic>);
      }
    });

    _socket?.on('communityMemberRemoved', (data) {
      if (data != null) {
        _memberRemovedController.add(data as Map<String, dynamic>);
      }
    });

    _socket?.onDisconnect((_) => print('Socket.IO disconnected'));
  }

  void joinCommunity(int communityId) {
    _socket?.emit('joinCommunity', {'communityId': communityId});
  }

  void leaveCommunity(int communityId) {
    _socket?.emit('leaveCommunity', {'communityId': communityId});
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _messageEditedController.close();
    _messageDeletedController.close();
    _messageReactionController.close();
    _messagesReadController.close();
    _settingsUpdatedController.close();
    _memberMutedController.close();
    _memberRemovedController.close();
  }
}
