import 'package:ntk_project/src/core/network/graphql_service.dart';
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
