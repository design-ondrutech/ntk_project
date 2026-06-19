import 'package:ntk_project/src/core/network/graphql_service.dart';
import 'package:ntk_project/src/features/notifications/data/models/notification_model.dart';
import 'package:ntk_project/src/features/notifications/domain/repositories/notification_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final GraphQLService _graphQLService;

  NotificationRepositoryImpl(this._graphQLService);

  @override
  Future<List<NotificationModel>> getNotifications({
    int? locationId,
    String? type,
  }) async {
    const String query = r'''
      query Notifications($locationId: Int) {
        notifications(locationId: $locationId) {
          id
          message
          location {
            name
          }
          type
          title
          createdAt
        }
      }
    ''';

    final result = await _graphQLService.performQuery(
      query,
      variables: {'locationId': locationId},
    );

    if (result.hasException) {
      throw Exception('Failed to load notifications: ${result.exception}');
    }

    final List data = result.data?['notifications'] as List? ?? [];

    final prefs = await SharedPreferences.getInstance();
    final readIds = prefs.getStringList('read_notifications') ?? [];
    final allReadUntilStr = prefs.getString('all_notifications_read_until');
    final allReadUntil = allReadUntilStr != null
        ? DateTime.tryParse(allReadUntilStr)
        : null;

    // Parse all notifications
    var notifications = data.map<NotificationModel>((json) {
      final n = NotificationModel.fromJson(json);
      final uniqueId = n.id != 0
          ? n.id
          : (n.title + (n.createdAt ?? n.time ?? '') + n.message).hashCode;

      bool isRead = readIds.contains(uniqueId.toString());
      if (!isRead && allReadUntil != null && n.createdAt != null) {
        final createdAtDate = DateTime.tryParse(n.createdAt!);
        if (createdAtDate != null && createdAtDate.isBefore(allReadUntil)) {
          isRead = true;
        }
      }

      return n.copyWith(id: uniqueId, isRead: isRead);
    }).toList();

    // Filter by type on the frontend as requested by user
    if (type != null && type != 'All') {
      notifications = notifications.where((n) {
        final String nType = n.type?.toUpperCase() ?? '';
        final String fType = type.toUpperCase();

        // Handle common mapping like "Events" -> "EVENT", "Approvals" -> "APPROVAL"
        if (fType == 'EVENTS' && nType == 'EVENT') return true;
        if (fType == 'APPROVALS' && nType == 'APPROVAL') return true;

        if (nType.isEmpty) return false;
        return nType == fType || nType.contains(fType) || fType.contains(nType);
      }).toList();
    }

    return notifications;
  }

  @override
  Future<Map<String, dynamic>> getNotificationDetails({required int id}) async {
    const String query = r'''
      query GetNotificationDetails($id: Int!) {
        getNotificationDetails(id: $id) {
          notificationId
          notificationTypeBadge
          statusBadge
          purpose
          responseRequired
          createdBy {
            name
            role
          }
          locationScope {
            label
            district
            constituency
            area
            street
          }
          event {
            id
            title
            description
            date
            status
            location {
              name
            }
          }
          broadcast {
            id
            title
            message
            image
          }
          emergency {
            id
            title
            description
            type
            contactName
            contactPhone
            bloodGroup
            unitsRequired
            hospitalName
            patientCondition
            disasterType
            affectedArea
            requiredSupport
            volunteerType
            responses {
              status
              note
              member {
                name
                phone
                role
              }
            }
            stats {
              total
              going
              maybe
              notGoing
              coming
              onTheWay
              reached
              unable
              contactRequested
            }
          }
          availableActions {
            key
            label
            style
          }
          activityHistory {
            title
            description
            actorName
            status
            createdAt
          }
        }
      }
    ''';

    final result = await _graphQLService.performQuery(
      query,
      variables: {'id': id},
    );

    if (result.hasException) {
      throw Exception(
        'Failed to load notification details: ${result.exception}',
      );
    }

    final data = result.data?['getNotificationDetails'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Notification details not found');
    }
    return data;
  }

  @override
  Future<NotificationModel> createNotification({
    required String title,
    required String message,
    required String type,
    String? time,
    required int locationId,
  }) async {
    const String mutation = r'''
      mutation CreateNotification($title: String!, $message: String!, $type: String!, $locationId: Int!) {
        createNotification(
          title: $title
          message: $message
          type: $type
          locationId: $locationId
        ) {
          id
          title
          message
          type
          createdAt
          isRead
        }
      }
    ''';

    final result = await _graphQLService.performMutation(
      mutation,
      variables: {
        'title': title,
        'message': message,
        'type': type,
        'locationId': locationId,
      },
    );

    if (result.hasException) {
      throw Exception('Failed to create notification: ${result.exception}');
    }

    final data = result.data?['createNotification'];
    if (data == null) throw Exception('Create notification failed');
    return NotificationModel.fromJson(data);
  }

  @override
  Future<void> markAsRead(int notificationId) async {
    final prefs = await SharedPreferences.getInstance();
    final readIds = prefs.getStringList('read_notifications') ?? [];
    if (!readIds.contains(notificationId.toString())) {
      readIds.add(notificationId.toString());
      await prefs.setStringList('read_notifications', readIds);
    }
  }

  @override
  Future<void> markAllAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'all_notifications_read_until',
      DateTime.now().toIso8601String(),
    );
  }

  @override
  Future<void> deleteNotification(int notificationId) async {
    const String mutation = r'''
      mutation DeleteNotification($id: Int!) {
        deleteNotification(id: $id)
      }
    ''';

    final result = await _graphQLService.performMutation(
      mutation,
      variables: {'id': notificationId},
    );

    if (result.hasException) {
      throw Exception('Failed to delete notification: ${result.exception.toString()}');
    }
  }

  @override
  Future<Map<String, bool>> getNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'events': prefs.getBool('pref_notify_events') ?? true,
      'community': prefs.getBool('pref_notify_community') ?? true,
      'emergency': prefs.getBool('pref_notify_emergency') ?? true,
      'approval': prefs.getBool('pref_notify_approval') ?? true,
      'poll': prefs.getBool('pref_notify_poll') ?? true,
      'broadcast': prefs.getBool('pref_notify_broadcast') ?? true,
      'sound': prefs.getBool('pref_notify_sound') ?? true,
      'vibration': prefs.getBool('pref_notify_vibration') ?? true,
    };
  }

  @override
  Future<void> updateNotificationSettings(Map<String, bool> settings) async {
    final prefs = await SharedPreferences.getInstance();
    settings.forEach((key, value) async {
      await prefs.setBool('pref_notify_$key', value);
    });
  }

  List<NotificationModel> _getMockNotifications() {
    return [
      NotificationModel(
        id: 1,
        title: 'District Meeting Created',
        message: 'New district meeting scheduled for tomorrow.',
        type: 'EVENT',
        createdAt: DateTime.now()
            .subtract(const Duration(minutes: 5))
            .toIso8601String(),
        isRead: false,
      ),
      NotificationModel(
        id: 2,
        title: 'Member Approved',
        message: 'Arun Kumar has been approved successfully.',
        type: 'APPROVAL',
        createdAt: DateTime.now()
            .subtract(const Duration(minutes: 10))
            .toIso8601String(),
        isRead: false,
      ),
      NotificationModel(
        id: 3,
        title: 'Broadcast Sent',
        message: 'Community broadcast delivered to 120 members.',
        type: 'BROADCAST',
        createdAt: DateTime.now()
            .subtract(const Duration(minutes: 20))
            .toIso8601String(),
        isRead: true,
      ),
      NotificationModel(
        id: 4,
        title: 'Blood Required',
        message: 'Urgent blood requirement in Nagapattinam.',
        type: 'EMERGENCY',
        createdAt: DateTime.now()
            .subtract(const Duration(minutes: 2))
            .toIso8601String(),
        isRead: false,
        locationName: 'Nagapattinam',
      ),
      NotificationModel(
        id: 5,
        title: 'New Poll Created',
        message: 'Vote for next district meeting location.',
        type: 'POLL',
        createdAt: DateTime.now()
            .subtract(const Duration(hours: 1))
            .toIso8601String(),
        isRead: true,
      ),
      NotificationModel(
        id: 6,
        title: 'New Member Joined',
        message: '5 new members joined the community.',
        type: 'COMMUNITY',
        createdAt: DateTime.now()
            .subtract(const Duration(hours: 2))
            .toIso8601String(),
        isRead: true,
      ),
    ];
  }
}
