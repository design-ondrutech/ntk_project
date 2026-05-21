import 'package:ntk_project/src/core/network/graphql_service.dart';
import 'package:ntk_project/src/features/notifications/data/models/notification_model.dart';
import 'package:ntk_project/src/features/notifications/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final GraphQLService _graphQLService;

  NotificationRepositoryImpl(this._graphQLService);

  @override
  Future<List<NotificationModel>> getNotifications({int? locationId}) async {
    const String query = r'''
      query Notifications($locationId: Int) {
        notifications(locationId: $locationId) {
          id
          title
          message
          type
          time
          createdAt
        }
      }
    ''';

    final result = await _graphQLService.performQuery(
      query,
      variables: {'locationId': locationId},
    );

    if (result.hasException) {
      throw Exception('Failed to fetch notifications: ${result.exception}');
    }

    final List data = result.data?['notifications'] as List? ?? [];
    return data
        .map<NotificationModel>((json) => NotificationModel.fromJson(json))
        .toList();
  }

  @override
  Future<NotificationModel> createNotification({
    required String title,
    required String message,
    required String type,
    required String time,
    required int locationId,
  }) async {
    const String mutation = r'''
      mutation CreateNotification($title: String!, $message: String!, $type: String!, $time: String!, $locationId: Int!) {
        createNotification(
          title: $title
          message: $message
          type: $type
          time: $time
          locationId: $locationId
        ) {
          id
          title
          message
          type
          time
          createdAt
        }
      }
    ''';

    final result = await _graphQLService.performMutation(
      mutation,
      variables: {
        'title': title,
        'message': message,
        'type': type,
        'time': time,
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
}
