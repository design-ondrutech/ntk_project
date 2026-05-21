abstract class UserRepository {
  Future<Map<String, dynamic>> createUser({
    required String name,
    required String phone,
    required String password,
    required String role,
    int? districtId,
    int? talukId,
    int? areaId,
    int? streetId,
    String? bloodGroup,
    String? professionName,
  });
}
