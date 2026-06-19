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
}
