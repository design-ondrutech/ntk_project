import 'package:ntk_project/src/core/network/graphql_service.dart';
import 'package:ntk_project/src/features/users/domain/repositories/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  final GraphQLService _graphQLService;

  UserRepositoryImpl(this._graphQLService);

  @override
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
  }) async {
    const String mutation = r'''
      mutation CreateUser(
        $name: String!
        $phone: String!
        $password: String!
        $role: UserRole!
        $districtId: Int
        $talukId: Int
        $areaId: Int
        $streetId: Int
        $bloodGroup: String
        $professionName: String
      ) {
        createUser(
          name: $name
          phone: $phone
          password: $password
          role: $role
          districtId: $districtId
          talukId: $talukId
          areaId: $areaId
          streetId: $streetId
          bloodGroup: $bloodGroup
          professionName: $professionName
        ) {
          id
          name
          phone
          role
          isActive
          approvalStatus
        }
      }
    ''';

    final variables = <String, dynamic>{
      'name': name,
      'phone': phone,
      'password': password,
      'role': role,
      if (districtId != null) 'districtId': districtId,
      if (talukId != null) 'talukId': talukId,
      if (areaId != null) 'areaId': areaId,
      if (streetId != null) 'streetId': streetId,
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
}
