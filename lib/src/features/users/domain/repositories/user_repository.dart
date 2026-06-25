import '../../data/models/user_location_assignment.dart';
import '../../data/models/location_access_request.dart';

abstract class UserRepository {
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
  });

  Future<List<UserLocationAssignment>> getUserAssignedLocations({required int userId});
  Future<List<LocationAccessRequest>> getPendingLocationAccessRequests();
  Future<List<LocationAccessRequest>> getMyLocationAccessRequests();

  Future<bool> requestLocationAccess({
    required String requestedRole,
    required String requestType,
    required List<int> locationIds,
    String? reason,
  });

  Future<bool> reviewLocationAccessRequest({
    required int requestId,
    required String action,
    String? rejectionReason,
  });

  Future<bool> assignUserLocations({
    required int userId,
    required List<int> locationIds,
    int? isPrimary,
  });

  Future<bool> removeUserLocation({
    required int userId,
    required int locationId,
  });
}
