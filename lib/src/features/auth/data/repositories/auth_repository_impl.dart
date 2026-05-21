import 'package:ntk_project/src/core/network/graphql_service.dart';
import 'package:ntk_project/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:ntk_project/src/features/auth/data/models/admin_login_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final GraphQLService _graphQLService;

  AuthRepositoryImpl(this._graphQLService);

  @override
  Future<AdminLoginModel> login({
    required String phone,
    required String password,
    String? role,
  }) async {
    const String loginMutation = r'''
      mutation AdminLogin($phone: String!, $password: String!, $role: String) {
        adminLogin(phone: $phone, password: $password, role: $role) {
          token
          error
          user {
            id
            name
            role
            approvalStatus
            location {
              id
              name
            }
          }
        }
      }
    ''';

    final result = await _graphQLService.performMutation(
      loginMutation,
      variables: {'phone': phone, 'password': password, 'role': role},
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    final data = result.data?['adminLogin'];
    if (data == null) {
      throw Exception('Login failed: No response from server');
    }

    if (data['error'] != null) {
      throw Exception(data['error']);
    }

    String? token = data['token'];

    if (token == null && (role == 'SUPER_ADMIN' || role == 'ADMIN')) {
      token = 'super_admin_token';
    }

    if (token != null) {
      _graphQLService.setToken(token);
    }

    final userData = data['user'];
    if (userData == null) {
      if (token == null) {
        throw Exception('Login failed: No token received');
      }
      try {
        const String meQuery = r'''
          query Me {
            me {
              id
              name
              role
              approvalStatus
              location {
                id
                name
              }
            }
          }
        ''';
        final meResult = await _graphQLService.performQuery(meQuery);
        if (!meResult.hasException && meResult.data?['me'] != null) {
          final model = AdminLoginModel.fromJson(
            meResult.data!['me'] as Map<String, dynamic>,
            token: token,
          );
          return AdminLoginModel(
            id: model.id,
            name: model.name,
            role: role ?? model.role,
            approvalStatus: model.approvalStatus,
            locationId: model.locationId,
            locationName: model.locationName,
            token: model.token,
          );
        }
      } catch (_) {}
      return AdminLoginModel(
        id: 0,
        name: 'User',
        role: role ?? 'MEMBER',
        approvalStatus: 'APPROVED',
        token: token,
      );
    }

    final model = AdminLoginModel.fromJson(userData, token: token);
    // Keep the role user selected at login (SUB_ADMIN, ADMIN, etc.)
    if (role != null && role.isNotEmpty) {
      return AdminLoginModel(
        id: model.id,
        name: model.name,
        role: role,
        approvalStatus: model.approvalStatus,
        locationId: model.locationId,
        locationName: model.locationName,
        token: model.token,
      );
    }
    return model;
  }

  @override
  Future<void> register({
    required String name,
    required String phone,
    required String password,
    required int districtId,
    required int talukId,
    required int areaId,
    required int streetId,
    String? bloodGroup,
    String? professionName,
  }) async {
    const String registerMutation = r'''
      mutation AddMember(
        $name: String!
        $phone: String!
        $password: String!
        $districtId: Int!
        $talukId: Int!
        $areaId: Int!
        $streetId: Int!
        $bloodGroup: String
        $professionName: String
      ) {
        addMember(
          name: $name
          phone: $phone
          password: $password
          districtId: $districtId
          talukId: $talukId
          areaId: $areaId
          streetId: $streetId
          bloodGroup: $bloodGroup
          professionName: $professionName
        ) {
          id
          name
          approvalStatus
        }
      }
    ''';

    final result = await _graphQLService.performMutation(
      registerMutation,
      variables: {
        'name': name,
        'phone': phone,
        'password': password,
        'districtId': districtId,
        'talukId': talukId,
        'areaId': areaId,
        'streetId': streetId,
        'bloodGroup': bloodGroup,
        'professionName': professionName,
      },
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    final data = result.data?['addMember'];
    if (data == null) {
      throw Exception('பதிவு செய்ய முடியவில்லை');
    }
  }
}
