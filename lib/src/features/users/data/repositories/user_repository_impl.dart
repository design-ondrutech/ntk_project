import 'package:ntk_project/src/core/network/graphql_service.dart';
import 'package:ntk_project/src/features/users/data/models/user_location_assignment.dart';
import 'package:ntk_project/src/features/users/data/models/location_access_request.dart';
import 'package:ntk_project/src/features/users/domain/repositories/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  final GraphQLService _graphQLService;

  UserRepositoryImpl(this._graphQLService);

  @override
  Future<Map<String, dynamic>> createUser({
    required String name,
    String? surname,
    required String phone,
    required String password,
    required String role,
    int? locationId,
    String? dateOfBirth,
    String? gender,
    String? bloodGroup,
    String? professionName,
  }) async {
    const String mutation = r'''
      mutation CreateUser(
        $name: String!
        $surname: String
        $phone: String!
        $password: String!
        $role: Role!
        $locationId: Int
        $dateOfBirth: String
        $gender: String
        $bloodGroup: String
        $professionName: String
      ) {
        createUser(
          name: $name
          surname: $surname
          phone: $phone
          password: $password
          role: $role
          locationId: $locationId
          dateOfBirth: $dateOfBirth
          gender: $gender
          bloodGroup: $bloodGroup
          professionName: $professionName
        ) {
          id
          name
          surname
          phone
          role
          dateOfBirth
          gender
        }
      }
    ''';

    final variables = <String, dynamic>{
      'name': name,
      'surname': surname,
      'phone': phone,
      'password': password,
      'role': role,
      if (locationId != null) 'locationId': locationId,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
      if (gender != null) 'gender': gender,
      if (bloodGroup != null) 'bloodGroup': bloodGroup,
      if (professionName != null) 'professionName': professionName,
    };

    final result = await _graphQLService.performMutation(
      mutation,
      variables: variables,
    );

    if (result.hasException) {
      throw Exception('Failed to create user: ${result.exception.toString()}');
    }

    final data = result.data?['createUser'];
    if (data == null) {
      throw Exception('No user data received after creation');
    }

    return data;
  }

  @override
  Future<List<UserLocationAssignment>> getUserAssignedLocations({required int userId}) async {
    const String query = r'''
      query GetUserAssignedLocations($userId: Int!) {
        getUserAssignedLocations(userId: $userId) {
          id
          userId
          locationId
          isPrimary
          location {
            id
            name
            type
          }
        }
      }
    ''';
    final result = await _graphQLService.performQuery(query, variables: {'userId': userId});
    if (result.hasException) throw Exception('Failed to get locations: ${result.exception}');
    final List data = result.data?['getUserAssignedLocations'] as List? ?? [];
    return data.map((json) => UserLocationAssignment.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<LocationAccessRequest>> getPendingLocationAccessRequests() async {
    const String query = r'''
      query GetPendingLocationAccessRequests {
        getPendingLocationAccessRequests {
          id
          userId
          currentRole
          requestedRole
          requestType
          status
          reason
          createdAt
          user {
            id
            name
            phone
            location {
              id
              name
            }
          }
          requestedLocations {
            id
            location {
              id
              name
              type
            }
          }
        }
      }
    ''';
    final result = await _graphQLService.performQuery(query);
    if (result.hasException) throw Exception('Failed to get pending requests: ${result.exception}');
    final List data = result.data?['getPendingLocationAccessRequests'] as List? ?? [];
    return data.map((json) => LocationAccessRequest.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<LocationAccessRequest>> getMyLocationAccessRequests() async {
    const String query = r'''
      query GetMyLocationAccessRequests {
        getMyLocationAccessRequests {
          id
          requestedRole
          requestType
          status
          reason
          rejectionReason
          createdAt
          requestedLocations {
            location {
              id
              name
              type
            }
          }
        }
      }
    ''';
    final result = await _graphQLService.performQuery(query);
    if (result.hasException) throw Exception('Failed to get my requests: ${result.exception}');
    final List data = result.data?['getMyLocationAccessRequests'] as List? ?? [];
    return data.map((json) => LocationAccessRequest.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<bool> requestLocationAccess({
    required String requestedRole,
    required String requestType,
    required List<int> locationIds,
    String? reason,
  }) async {
    const String mutation = r'''
      mutation RequestLocationAccess($requestedRole: Role!, $requestType: String!, $locationIds: [Int!]!, $reason: String) {
        requestLocationAccess(requestedRole: $requestedRole, requestType: $requestType, locationIds: $locationIds, reason: $reason) {
          id
          status
        }
      }
    ''';
    final result = await _graphQLService.performMutation(mutation, variables: {
      'requestedRole': requestedRole,
      'requestType': requestType,
      'locationIds': locationIds,
      'reason': reason,
    });
    if (result.hasException) throw Exception('Failed to request access: ${result.exception}');
    return result.data?['requestLocationAccess'] != null;
  }

  @override
  Future<bool> reviewLocationAccessRequest({
    required int requestId,
    required String action,
    String? rejectionReason,
  }) async {
    const String mutation = r'''
      mutation ReviewLocationAccessRequest($requestId: Int!, $action: String!, $rejectionReason: String) {
        reviewLocationAccessRequest(requestId: $requestId, action: $action, rejectionReason: $rejectionReason) {
          id
          status
          rejectionReason
        }
      }
    ''';
    final result = await _graphQLService.performMutation(mutation, variables: {
      'requestId': requestId,
      'action': action,
      'rejectionReason': rejectionReason,
    });
    if (result.hasException) throw Exception('Failed to review request: ${result.exception}');
    return result.data?['reviewLocationAccessRequest'] != null;
  }

  @override
  Future<bool> assignUserLocations({
    required int userId,
    required List<int> locationIds,
    int? isPrimary,
  }) async {
    const String mutation = r'''
      mutation AssignUserLocations($userId: Int!, $locationIds: [Int!]!, $isPrimary: Int) {
        assignUserLocations(userId: $userId, locationIds: $locationIds, isPrimary: $isPrimary) {
          id
          role
          location {
            id
            name
          }
        }
      }
    ''';
    final result = await _graphQLService.performMutation(mutation, variables: {
      'userId': userId,
      'locationIds': locationIds,
      'isPrimary': isPrimary,
    });
    if (result.hasException) throw Exception('Failed to assign locations: ${result.exception}');
    return result.data?['assignUserLocations'] != null;
  }

  @override
  Future<bool> removeUserLocation({
    required int userId,
    required int locationId,
  }) async {
    const String mutation = r'''
      mutation RemoveUserLocation($userId: Int!, $locationId: Int!) {
        removeUserLocation(userId: $userId, locationId: $locationId)
      }
    ''';
    final result = await _graphQLService.performMutation(mutation, variables: {
      'userId': userId,
      'locationId': locationId,
    });
    if (result.hasException) throw Exception('Failed to remove location: ${result.exception}');
    return result.data?['removeUserLocation'] == true;
  }
}
