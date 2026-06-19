import 'package:ntk_project/src/core/network/graphql_service.dart';
import 'package:ntk_project/src/features/events/data/models/emergency_model.dart';
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
      query GetEventList($locationId: Int) {
        getEventList(locationId: $locationId) {
          id
          title
          description
          date
          location {
            id
            name
          }
          createdBy {
            id
            name
          }
          stats {
            going
            maybe
            notGoing
          }
        }
      }
    ''';

    final result = await _graphQLService.performQuery(
      query,
      variables: {
        if (locationId != null) 'locationId': locationId,
      },
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    final data = result.data?['getEventList'] as List?;
    if (data == null) {
      return [];
    }

    return data
        .where((e) => e != null)
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
      mutation RespondToEvent($eventId: Int!, $memberId: Int!, $status: RSVPStatus!) {
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
      variables: {
        'eventId': int.parse(eventId),
        'memberId': memberId,
        'status': status,
      },
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
    List<String>? professionNames,
  }) async {
    const String mutation = r'''
      mutation CreateEvent($title: String!, $description: String, $date: String!, $locationId: Int!, $professionNames: [String!]) {
        createEvent(
          title: $title
          description: $description
          date: $date
          locationId: $locationId
          professionNames: $professionNames
        ) {
          id
          title
          date
          location {
            id
            name
          }
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
        'professionNames': professionNames,
      },
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    final data = result.data?['createEvent'];
    if (data == null) {
      throw Exception('Failed to create event');
    }

    return EventModel(
      id: data['id'].toString(),
      title: data['title'] as String? ?? title,
      description: description,
      date: data['date'] as String? ?? date,
      locationName: data['location']?['name'] as String? ?? '',
      going: 0,
      maybe: 0,
      notGoing: 0,
    );
  }

  @override
  Future<List<EventResponseModel>> getEventResponses({
    required String eventId,
  }) async {
    const String query = r'''
      query GetEventResponses($eventId: Int!) {
        getEventList(eventId: $eventId) {
          id
          responses {
            status
            member {
              id
              name
              phone
              role
            }
          }
        }
      }
    ''';

    final result = await _graphQLService.performQuery(
      query,
      variables: {'eventId': int.parse(eventId)},
    );

    if (result.hasException) throw Exception(result.exception.toString());

    final list = result.data?['getEventList'] as List?;
    if (list == null || list.isEmpty) return [];

    final event = list.first as Map<String, dynamic>?;
    final responses = event?['responses'] as List?;
    if (responses == null) return [];

    return responses
        .where((r) => r != null)
        .map((r) => EventResponseModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<EventModel> getEventDetails({required String id}) async {
    const String query = r'''
      query GetEventDetails($id: Int!) {
        getEventDetails(id: $id) {
          id
          title
          description
          date
          status
          createdAt
          location {
            id
            name
          }
          createdBy {
            id
            name
          }
          stats {
            going
            maybe
            notGoing
          }
        }
      }
    ''';

    final result = await _graphQLService.performQuery(
      query,
      variables: {'id': int.parse(id)},
    );

    if (result.hasException) {
      throw Exception('Failed to get event details: ${result.exception}');
    }

    final data = result.data?['getEventDetails'] as Map<String, dynamic>?;
    if (data == null) throw Exception('Event details not found');
    return EventModel.fromJson(data);
  }

  @override
  Future<EmergencyModel> createEmergency({
    required String title,
    String? description,
    required String type,
    required int locationId,
    String? contactName,
    String? contactPhone,
    String? expiryDate,
    bool? collectResponse,
  }) async {
    const String mutation = r'''
      mutation CreateEmergency(
        $title: String!
        $description: String
        $type: String!
        $locationId: Int!
        $contactName: String
        $contactPhone: String
        $expiryDate: String
        $collectResponse: Boolean
      ) {
        createEmergencyRequest(
          title: $title
          description: $description
          type: $type
          locationId: $locationId
          contactName: $contactName
          contactPhone: $contactPhone
          expiryDate: $expiryDate
          collectResponse: $collectResponse
        ) {
          id
          title
        }
      }
    ''';

    final result = await _graphQLService.performMutation(
      mutation,
      variables: {
        'title': title,
        'description': description,
        'type': type,
        'locationId': locationId,
        'contactName': contactName,
        'contactPhone': contactPhone,
        'expiryDate': expiryDate,
        'collectResponse': collectResponse ?? true,
      },
    );

    if (result.hasException) throw Exception(result.exception.toString());

    final data = result.data?['createEmergencyRequest'];
    if (data == null) throw Exception('Failed to create emergency request');

    return EmergencyModel(
      id: data['id'].toString(),
      title: data['title'] as String? ?? title,
      description: description ?? '',
      type: type,
      contactName: contactName ?? '',
      contactPhone: contactPhone ?? '',
      expiryDate: expiryDate ?? '',
      collectResponse: collectResponse ?? true,
      locationName: '',
      going: 0,
      maybe: 0,
      notGoing: 0,
    );
  }

  @override
  Future<List<EmergencyModel>> getEmergencyList({int? locationId}) async {
    const String query = r'''
      query GetEmergencyList($locationId: Int) {
        getEmergencyRequestList(locationId: $locationId) {
          id
          title
          description
          type
          contactName
          contactPhone
          expiryDate
          collectResponse
          createdAt
          status
          audience
          location {
            id
            name
            type
          }
          member {
            id
            name
            surname
          }
          createdBy {
            id
            name
            role
          }
          stats {
            going
            maybe
            notGoing
          }
        }
      }
    ''';

    final result = await _graphQLService.performQuery(
      query,
      variables: {if (locationId != null) 'locationId': locationId},
    );

    if (result.hasException) throw Exception(result.exception.toString());

    final data = result.data?['getEmergencyRequestList'] as List?;
    if (data == null) return [];

    return data
        .where((e) => e != null)
        .map((e) => EmergencyModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<EmergencyModel> getEmergencyRequestDetails({
    required String id,
  }) async {
    const String query = r'''
      query GetEmergencyRequestDetails($id: Int!) {
        getEmergencyRequestDetails(id: $id) {
          id
          title
          description
          type
          status
          audience
          contactName
          contactPhone
          expiryDate
          collectResponse
          createdAt
          bloodGroup
          unitsRequired
          hospitalName
          patientCondition
          disasterType
          affectedArea
          requiredSupport
          volunteerType
          location {
            id
            name
            type
          }
          member {
            id
            name
            surname
          }
          createdBy {
            id
            name
            role
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
      }
    ''';

    final result = await _graphQLService.performQuery(
      query,
      variables: {'id': int.parse(id)},
    );

    if (result.hasException) {
      throw Exception(
        'Failed to get emergency request details: ${result.exception}',
      );
    }

    final data =
        result.data?['getEmergencyRequestDetails'] as Map<String, dynamic>?;
    if (data == null) throw Exception('Emergency details not found');
    return EmergencyModel.fromJson(data);
  }

  @override
  Future<String> respondToEmergency({
    required String emergencyRequestId,
    required String status,
    String? note,
  }) async {
    const String mutation = r'''
      mutation RespondToEmergency($emergencyRequestId: Int!, $status: RSVPStatus!, $note: String) {
        respondToEmergency(
          emergencyRequestId: $emergencyRequestId,
          status: $status
          note: $note
        ) {
          status
          note
          member {
            name
            phone
          }
        }
      }
    ''';

    final result = await _graphQLService.performMutation(
      mutation,
      variables: {
        'emergencyRequestId': int.parse(emergencyRequestId),
        'status': status,
        'note': note,
      },
    );

    if (result.hasException) throw Exception(result.exception.toString());

    final data = result.data?['respondToEmergency'];
    if (data == null) throw Exception('Failed to respond');
    return data['status'] ?? status;
  }

  @override
  Future<List<EmergencyResponseModel>> getEmergencyResponses({
    required String emergencyRequestId,
  }) async {
    const String query = r'''
      query GetEmergencyResponses($id: Int!) {
        getEmergencyRequestDetails(id: $id) {
          id
          stats {
            going
            maybe
            notGoing
          }
          responses {
            id
            status
            member {
              id
              name
              phone
            }
          }
        }
      }
    ''';

    final result = await _graphQLService.performQuery(
      query,
      variables: {'id': int.parse(emergencyRequestId)},
    );

    if (result.hasException) throw Exception(result.exception.toString());

    final emergency = result.data?['getEmergencyRequestDetails'] as Map<String, dynamic>?;
    if (emergency == null) return [];
    final responses = emergency['responses'] as List?;
    if (responses == null) return [];

    return responses
        .where((r) => r != null)
        .map((r) => EmergencyResponseModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<bool> recallEvent({required String id}) async {
    const String mutation = r'''
      mutation RecallEvent($id: Int!) {
        recallEvent(id: $id)
      }
    ''';

    final result = await _graphQLService.performMutation(
      mutation,
      variables: {'id': int.parse(id)},
    );

    if (result.hasException) {
      throw Exception('Failed to recall event: ${result.exception.toString()}');
    }

    return result.data?['recallEvent'] as bool? ?? false;
  }

  @override
  Future<bool> deleteEmergencyRequest({required String id}) async {
    const String mutation = r'''
      mutation DeleteEmergencyRequest($id: Int!) {
        deleteEmergencyRequest(id: $id)
      }
    ''';

    final result = await _graphQLService.performMutation(
      mutation,
      variables: {'id': int.parse(id)},
    );

    if (result.hasException) {
      throw Exception('Failed to delete emergency request: ${result.exception.toString()}');
    }

    return result.data?['deleteEmergencyRequest'] as bool? ?? false;
  }
}
