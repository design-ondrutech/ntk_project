import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ntk_project/src/core/network/graphql_service.dart';
import 'package:ntk_project/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:ntk_project/src/features/auth/data/models/admin_login_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final GraphQLService _graphQLService;

  AuthRepositoryImpl(this._graphQLService);

  static const String _meQuery = r'''
    query Me {
      me {
        id
        name
        surname
        phone
        role
        approvalStatus
        addedBy
        image
        bloodGroup
        dateOfBirth
        profession
        location {
          id
          name
          type
        }
      }
    }
  ''';

  @override
  Future<AdminLoginModel> login({
    required String phone,
    required String password,
  }) async {
    const String loginMutation = r'''
      mutation AdminLogin($phone: String!, $password: String!) {
        adminLogin(phone: $phone, password: $password) {
          token
          user {
            id
            name
            surname
            phone
            role
            approvalStatus
            addedBy
            image
            location {
              id
              name
              type
            }
          }
        }
      }
    ''';

    final result = await _graphQLService.performMutation(
      loginMutation,
      variables: {'phone': phone, 'password': password},
    );

    if (result.hasException) {
      // Extract friendly message from GraphQL errors
      final graphqlErrors = result.exception?.graphqlErrors;
      if (graphqlErrors != null && graphqlErrors.isNotEmpty) {
        final rawMsg = graphqlErrors.first.message.toLowerCase();
        if (rawMsg.contains('invalid password') ||
            rawMsg.contains('wrong password') ||
            rawMsg.contains('incorrect password')) {
          throw Exception('Invalid password');
        } else if (rawMsg.contains('user not found') ||
            rawMsg.contains('phone not found') ||
            rawMsg.contains('not found') ||
            rawMsg.contains('no user')) {
          throw Exception('User not found');
        } else if (rawMsg.contains('not approved') ||
            rawMsg.contains('pending')) {
          throw Exception('Your account is pending approval');
        } else if (rawMsg.contains('inactive') || rawMsg.contains('disabled')) {
          throw Exception('Your account has been deactivated');
        }
        throw Exception(graphqlErrors.first.message);
      }
      throw Exception('Login failed. Please try again.');
    }

    final data = result.data?['adminLogin'];
    if (data == null) {
      throw Exception('Login failed: No response from server');
    }

    if (data['error'] != null) {
      throw Exception(data['error']);
    }

    String? token = data['token'];

    if (token != null) {
      _graphQLService.setToken(token);
    }

    final userData = data['user'];
    if (userData == null) {
      if (token == null) {
        throw Exception('Login failed: No token received');
      }
      try {
        final meResult = await _graphQLService.performQuery(_meQuery);
        if (!meResult.hasException && meResult.data?['me'] != null) {
          final model = AdminLoginModel.fromJson(
            meResult.data!['me'] as Map<String, dynamic>,
            token: token,
          );
          return model;
        }
      } catch (_) {}
      return AdminLoginModel(
        id: 0,
        name: 'User',
        role: 'MEMBER',
        approvalStatus: 'APPROVED',
        token: token,
      );
    }

    var model = AdminLoginModel.fromJson(userData, token: token);

    final needsMeQuery =
        token != null &&
        (!userData.containsKey('approvalStatus') ||
            userData['approvalStatus'] == null ||
            model.locationName == null ||
            model.locationName!.isEmpty ||
            (model.role == 'SUB_ADMIN' && model.locationName == 'Tamil Nadu'));

    if (needsMeQuery) {
      try {
        final meResult = await _graphQLService.performQuery(_meQuery);
        if (!meResult.hasException && meResult.data?['me'] != null) {
          final meModel = AdminLoginModel.fromJson(
            meResult.data!['me'] as Map<String, dynamic>,
            token: token,
          );
          model = AdminLoginModel(
            id: model.id,
            name: model.name,
            surname: meModel.surname ?? model.surname,
            phone: meModel.phone ?? model.phone,
            role: model.role,
            approvalStatus: meModel.approvalStatus,
            locationId: meModel.locationId ?? model.locationId,
            locationName: meModel.locationName ?? model.locationName,
            locationType: meModel.locationType ?? model.locationType,
            isActive: meModel.isActive ?? model.isActive,
            addedBy: meModel.addedBy ?? model.addedBy,
            image: meModel.image ?? model.image,
            token: model.token,
            bloodGroup: meModel.bloodGroup ?? model.bloodGroup,
            professionName: meModel.professionName ?? model.professionName,
          );
        }
      } catch (_) {}
    }

    if (model.role == 'SUB_ADMIN' &&
        model.locationId != null &&
        (model.locationName == null ||
            model.locationName!.isEmpty ||
            model.locationName == 'Tamil Nadu')) {
      try {
        const String locationQuery = r'''
          query GetLocationDetails($id: Int!) {
            getLocationDetails(id: $id) {
              id
              name
            }
          }
        ''';
        final locationResult = await _graphQLService.performQuery(
          locationQuery,
          variables: {'id': model.locationId},
        );
        final locationData = locationResult.data?['getLocationDetails'];
        if (!locationResult.hasException && locationData != null) {
          model = AdminLoginModel(
            id: model.id,
            name: model.name,
            surname: model.surname,
            phone: model.phone,
            role: model.role,
            approvalStatus: model.approvalStatus,
            locationId: locationData['id'] as int? ?? model.locationId,
            locationName: locationData['name'] as String? ?? model.locationName,
            isActive: model.isActive,
            addedBy: model.addedBy,
            image: model.image,
            token: model.token,
          );
        }
      } catch (_) {}
    }

    await persistSession(model);
    return model;
  }

  @override
  Future<AdminLoginModel> getMe() async {
    final result = await _graphQLService.performQuery(_meQuery);

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    final data = result.data?['me'];
    if (data == null) {
      throw Exception('Profile data not found');
    }

    return AdminLoginModel.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<void> register({
    required String name,
    String? surname,
    required String phone,
    required String password,
    required int districtId,
    required int talukId,
    required int areaId,
    required int streetId,
    String? bloodGroup,
    String? professionName,
    String? dateOfBirth,
    String? gender,
  }) async {
    const String registerMutation = r'''
      mutation AddMember(
        $name: String!
        $surname: String
        $phone: String!
        $password: String!
        $streetId: Int
        $bloodGroup: String
        $professionName: String
        $dateOfBirth: String
        $gender: String
      ) {
        addMember(
          name: $name
          surname: $surname
          phone: $phone
          password: $password
          streetId: $streetId
          bloodGroup: $bloodGroup
          professionName: $professionName
          dateOfBirth: $dateOfBirth
          gender: $gender
        ) {
          id
          name
          surname
          phone
          profession
        }
      }
    ''';

    final result = await _graphQLService.performMutation(
      registerMutation,
      variables: {
        'name': name,
        'surname': surname,
        'phone': phone,
        'password': password,
        'streetId': streetId,
        'bloodGroup': bloodGroup,
        'professionName': professionName,
        'dateOfBirth': dateOfBirth,
        'gender': gender,
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

  @override
  Future<void> updateFcmToken(String token) async {
    const String mutation = r'''
      mutation UpdateFcmToken($token: String!) {
        updateFcmToken(token: $token)
      }
    ''';
    final result = await _graphQLService.performMutation(
      mutation,
      variables: {'token': token},
    );
    if (result.hasException) {
      throw Exception(result.exception.toString());
    }
  }

  @override
  Future<void> logout() async {
    const String logoutMutation = r'''
      mutation LogoutUser {
        logout
      }
    ''';
    try {
      final result = await _graphQLService.performMutation(logoutMutation);
      if (result.hasException) {
        print('Logout mutation exception: ${result.exception.toString()}');
      }
    } catch (e) {
      print('Logout mutation error: $e');
    } finally {
      _graphQLService.setToken(null);
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('user_session');
      } catch (_) {}
    }
  }

  @override
  Future<void> sendOtp(String phone) async {
    // TODO: implement sendOtp
  }

  @override
  Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    // TODO: implement verifyOtp
    return {};
  }

  @override
  Future<void> persistSession(AdminLoginModel model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_session', jsonEncode(model.toJson()));
  }

  @override
  Future<AdminLoginModel?> getPersistedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionStr = prefs.getString('user_session');
      if (sessionStr != null) {
        final Map<String, dynamic> sessionJson = jsonDecode(sessionStr);
        final model = AdminLoginModel.fromJson(sessionJson);
        if (model.token != null) {
          _graphQLService.setToken(model.token);
        }
        return model;
      }
    } catch (e) {
      print('Error reading persisted session: $e');
    }
    return null;
  }
}
