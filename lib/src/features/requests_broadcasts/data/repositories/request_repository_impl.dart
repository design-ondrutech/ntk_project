import 'package:ntk_project/src/core/network/graphql_service.dart';
import 'package:ntk_project/src/features/requests_broadcasts/data/models/emergency_request_model.dart';
import 'package:ntk_project/src/features/requests_broadcasts/data/models/broadcast_model.dart';
import 'package:ntk_project/src/features/requests_broadcasts/domain/repositories/request_repository.dart';

class RequestRepositoryImpl implements RequestRepository {
  final GraphQLService _graphQLService;

  RequestRepositoryImpl(this._graphQLService);

  @override
  Future<List<EmergencyRequestModel>> getEmergencyRequestList({
    int? locationId,
    String? status,
  }) async {
    const String query = r'''
      query GetEmergencyRequestList($locationId: Int, $status: RequestStatus) {
        getEmergencyRequestList(locationId: $locationId, status: $status) {
          id
          title
          description
          type
          status
          audience
          createdAt
          location {
            id
            name
          }
          member {
            id
            name
          }
        }
      }
    ''';

    final result = await _graphQLService.performQuery(
      query,
      variables: {'locationId': locationId, 'status': status},
    );

    if (result.hasException) {
      throw Exception('Failed to fetch requests: ${result.exception}');
    }

    final List data = result.data?['getEmergencyRequestList'] as List? ?? [];
    return data
        .map<EmergencyRequestModel>(
          (json) => EmergencyRequestModel.fromJson(json),
        )
        .toList();
  }

  @override
  Future<EmergencyRequestModel> createEmergencyRequest({
    required String title,
    required String description,
    required String type,
    required int locationId,
    String? audience,
  }) async {
    const String mutation = r'''
      mutation CreateEmergencyRequest($title: String!, $description: String!, $type: RequestType!, $locationId: Int!, $audience: String) {
        createEmergencyRequest(
          title: $title
          description: $description
          type: $type
          locationId: $locationId
          audience: $audience
        ) {
          id
          title
          description
          type
          status
          audience
          createdAt
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
        'type': type,
        'locationId': locationId,
        'audience': audience,
      },
    );

    if (result.hasException) {
      throw Exception('Failed to create request: ${result.exception}');
    }

    final data = result.data?['createEmergencyRequest'];
    if (data == null) throw Exception('Create request failed');
    return EmergencyRequestModel.fromJson(data);
  }

  @override
  Future<EmergencyRequestModel> updateRequestStatus({
    required int id,
    required String status,
  }) async {
    if (status.toUpperCase() == 'CLOSED' || status.toUpperCase() == 'COMPLETED') {
      const String mutation = r'''
        mutation CompleteEmergencyRequest($id: Int!) {
          completeEmergencyRequest(id: $id)
        }
      ''';

      final result = await _graphQLService.performMutation(
        mutation,
        variables: {'id': id},
      );

      if (result.hasException) {
        throw Exception('Failed to complete emergency request: ${result.exception}');
      }

      final success = result.data?['completeEmergencyRequest'] as bool? ?? false;
      if (!success) {
        throw Exception('Failed to complete emergency request');
      }

      return EmergencyRequestModel(
        id: id,
        title: '',
        description: '',
        type: '',
        status: 'CLOSED',
        audience: '',
        createdAt: '',
      );
    }

    const String mutation = r'''
      mutation UpdateRequestStatus($id: Int!, $status: RequestStatus!) {
        updateRequestStatus(id: $id, status: $status) {
          id
          title
          type
          status
          createdAt
          location {
            id
            name
          }
        }
      }
    ''';

    final result = await _graphQLService.performMutation(
      mutation,
      variables: {'id': id, 'status': status},
    );

    if (result.hasException) {
      throw Exception('Failed to update request status: ${result.exception}');
    }

    final data = result.data?['updateRequestStatus'];
    if (data == null) throw Exception('Update failed');
    return EmergencyRequestModel.fromJson(data);
  }

  @override
  Future<List<BroadcastModel>> getBroadcasts({int? locationId, String? scope}) async {
    const String query = r'''
      query GetBroadcastList($locationId: Int, $scope: BroadcastScope, $isActive: Boolean) {
        getBroadcastList(locationId: $locationId, scope: $scope, isActive: $isActive) {
          id
          title
          message
          image
          scope
          isActive
          recipientCount
          createdAt
          updatedAt
          location {
            id
            name
            type
          }
          createdBy {
            id
            name
            role
            phone
          }
        }
      }
    ''';

    final result = await _graphQLService.performQuery(
      query,
      variables: {
        'locationId': locationId,
        if (scope != null) 'scope': scope,
        'isActive': true,
      },
    );

    if (result.hasException) {
      throw Exception('Failed to fetch broadcasts: ${result.exception}');
    }

    final List data = result.data?['getBroadcastList'] as List? ?? [];
    return data.map<BroadcastModel>((json) => BroadcastModel.fromJson(json)).toList();
  }

  @override
  Future<BroadcastModel> getBroadcastDetails({required int id}) async {
    const String query = r'''
      query GetBroadcastDetails($id: Int!) {
        getBroadcastDetails(id: $id) {
          id
          title
          message
          image
          scope
          updatedAt
          isActive
          createdAt
          recipientCount
          location {
            id
            name
            type
          }
          createdBy {
            id
            name
            role
            phone
          }
        }
      }
    ''';

    final result = await _graphQLService.performQuery(query, variables: {'id': id});

    if (result.hasException) {
      throw Exception('Failed to fetch broadcast details: ${result.exception}');
    }

    final data = result.data?['getBroadcastDetails'];
    if (data == null) throw Exception('Broadcast not found');
    return BroadcastModel.fromJson(data);
  }

  @override
  Future<BroadcastModel> createBroadcast({
    required String title,
    required String message,
    String? image,
    required int locationId,
  }) async {
    const String mutation = r'''
      mutation CreateBroadcast($title: String!, $message: String!, $image: String, $locationId: Int!) {
        createBroadcast(title: $title, message: $message, image: $image, locationId: $locationId) {
          id
          title
          message
          createdAt
        }
      }
    ''';

    final result = await _graphQLService.performMutation(
      mutation,
      variables: {
        'title': title,
        'message': message,
        'image': image,
        'locationId': locationId,
      },
    );

    if (result.hasException) {
      throw Exception('Failed to create broadcast: ${result.exception}');
    }

    final data = result.data?['createBroadcast'];
    if (data == null) throw Exception('Create broadcast failed');
    return BroadcastModel.fromJson(data);
  }

  @override
  Future<EmergencyRequestModel> reviewEmergencyRequest({
    required int id,
    required String action,
    String? rejectReason,
  }) async {
    const String mutation = r'''
      mutation ReviewEmergencyRequest($id: Int!, $action: String!, $rejectReason: String) {
        reviewEmergencyRequest(id: $id, action: $action, rejectReason: $rejectReason) {
          id
          status
        }
      }
    ''';

    final result = await _graphQLService.performMutation(
      mutation,
      variables: {
        'id': id,
        'action': action,
        'rejectReason': rejectReason,
      },
    );

    if (result.hasException) {
      throw Exception('Failed to review request: ${result.exception}');
    }

    final data = result.data?['reviewEmergencyRequest'];
    if (data == null) throw Exception('Review failed');
    return EmergencyRequestModel.fromJson(data);
  }

  @override
  Future<bool> recallBroadcast({required int id}) async {
    const String mutation = r'''
      mutation RecallBroadcast($id: Int!) {
        recallBroadcast(id: $id)
      }
    ''';

    final result = await _graphQLService.performMutation(
      mutation,
      variables: {'id': id},
    );

    if (result.hasException) {
      throw Exception('Failed to recall broadcast: ${result.exception.toString()}');
    }

    return result.data?['recallBroadcast'] as bool? ?? false;
  }
}
