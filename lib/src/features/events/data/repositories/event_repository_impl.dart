import 'package:ntk_project/src/core/network/graphql_service.dart';
import 'package:ntk_project/src/features/events/data/models/event_model.dart';
import 'package:ntk_project/src/features/events/domain/repositories/event_repository.dart';

class EventRepositoryImpl implements EventRepository {
  final GraphQLService _graphQLService;

  EventRepositoryImpl(this._graphQLService);

  @override
  Future<List<EventModel>> getRecentEvents({
    int? locationId,
    int limit = 10,
  }) async {
    const String query = r'''
      query GetEventList($locId: Int, $limit: Int!) {
        recentActivity(locationId: $locId, limit: $limit) {
          __typename
          ... on Event {
            id
            title
            description
            date
            location {
              name
            }
            stats {
              going
              maybe
              notGoing
            }
          }
        }
      }
    ''';

    final result = await _graphQLService.performQuery(
      query,
      variables: {if (locationId != null) 'locId': locationId, 'limit': limit},
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    final data = result.data?['recentActivity'] as List?;
    if (data == null) {
      return [];
    }

    return data
        .where((e) => e != null && e['__typename'] == 'Event')
        .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<String> respondToEvent({
    required String eventId,
    required int memberId,
    required String status,
  }) async {
    const String mutation = r'''
      mutation RespondToEvent($eventId: Int!, $memberId: Int!, $status: String!) {
        respondToEvent(
          eventId: $eventId
          memberId: $memberId
          status: $status
        ) {
          status
        }
      }
    ''';

    final result = await _graphQLService.performMutation(
      mutation,
      variables: {'eventId': int.parse(eventId), 'memberId': memberId, 'status': status},
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    final data = result.data?['respondToEvent'];
    if (data == null) {
      throw Exception('Failed to respond to event');
    }

    return data['status'] ?? status;
  }

  @override
  Future<EventModel> createEvent({
    required String title,
    required String description,
    required String date,
    required int locationId,
  }) async {
    // Step 1: Create the event
    const String mutation = r'''
      mutation CreateEvent($title: String!, $description: String!, $date: String!, $locationId: Int!) {
        createEvent(
          title: $title
          description: $description
          date: $date
          locationId: $locationId
        ) {
          id
        }
      }
    ''';

    final result = await _graphQLService.performMutation(
      mutation,
      variables: {
        'title': title,
        'description': description,
        'date': date,
        'locationId': locationId,
      },
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    final data = result.data?['createEvent'];
    if (data == null) {
      throw Exception('Failed to create event');
    }

    // Step 2: Return the EventModel with the created ID
    return EventModel(
      id: data['id'].toString(),
      title: title,
      description: description,
      date: date,
      locationName: '',
      going: 0,
      maybe: 0,
      notGoing: 0,
    );
  }
}
