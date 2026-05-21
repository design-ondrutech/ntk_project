import 'package:ntk_project/src/core/network/graphql_service.dart';
import 'package:ntk_project/src/features/requests_broadcasts/data/models/emergency_request_model.dart';
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
}
