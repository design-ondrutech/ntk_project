import 'package:ntk_project/src/core/network/graphql_service.dart';
import 'package:ntk_project/src/features/members/data/models/member_model.dart';
import 'package:ntk_project/src/features/members/domain/repositories/member_repository.dart';

class MemberRepositoryImpl implements MemberRepository {
  final GraphQLService _graphQLService;

  MemberRepositoryImpl(this._graphQLService);

  @override
  Future<List<MemberModel>> getMembers({
    int? locationId,
    int? professionId,
    String? bloodGroup,
    String? search,
    String? role,
    int? limit,
    int? offset,
  }) async {
    const String query = r'''
      query GetMemberList($locationId: Int, $bloodGroup: String, $search: String, $role: String, $approvalStatus: ApprovalStatus, $limit: Int, $offset: Int) {
        getMemberList(locationId: $locationId, bloodGroup: $bloodGroup, search: $search, role: $role, approvalStatus: $approvalStatus, limit: $limit, offset: $offset) {
          id
          name
          phone
          role
          addedBy
          image
          location {
            id
            name
          }
        }
      }
    ''';

    final result = await _graphQLService.performQuery(
      query,
      variables: {
        'locationId': locationId,
        'bloodGroup': bloodGroup,
        'search': search,
        'role': role,
        'approvalStatus': 'APPROVED',
        'limit': limit,
        'offset': offset,
      },
    );

    if (result.hasException) {
      throw Exception('Failed to fetch members: ${result.exception}');
    }

    final List data = result.data?['getMemberList'] as List? ?? [];
    return _sortByRoleOrder(
      data.map<MemberModel>((json) => MemberModel.fromJson(json)).toList(),
    );
  }

  @override
  Future<List<MemberModel>> getMemberList({
    int? locationId,
    String? approvalStatus,
    String? role,
    String? bloodGroup,
    String? professionName,
    int? limit,
    int? offset,
  }) async {
    const String query = r'''
      query GetMemberList($locationId: Int, $approvalStatus: ApprovalStatus, $role: String, $bloodGroup: String, $professionName: String, $limit: Int, $offset: Int) {
        getMemberList(locationId: $locationId, approvalStatus: $approvalStatus, role: $role, bloodGroup: $bloodGroup, professionName: $professionName, limit: $limit, offset: $offset) {
          id
          name
          phone
          role
          approvalStatus
          isActive
          bloodGroup
          profession
          addedBy
          image
          location {
            id
            name
          }
        }
      }
    ''';

    final result = await _graphQLService.performQuery(
      query,
      variables: {
        'locationId': locationId,
        'approvalStatus': approvalStatus,
        'role': role,
        'bloodGroup': bloodGroup,
        'professionName': professionName,
        'limit': limit,
        'offset': offset,
      },
    );

    if (result.hasException) {
      throw Exception('Failed to fetch member list: ${result.exception}');
    }

    final List data = result.data?['getMemberList'] as List? ?? [];
    return _sortByRoleOrder(
      data.map<MemberModel>((json) => MemberModel.fromJson(json)).toList(),
    );
  }

  @override
  Future<List<MemberModel>> getPendingMembers({int? locationId}) async {
    const String query = r'''
      query GetPendingMembers($locationId: Int, $approvalStatus: ApprovalStatus) {
        getMemberList(locationId: $locationId, approvalStatus: $approvalStatus) {
          id
          name
          phone
          role
          addedBy
          image
          location {
            id
            name
          }
        }
      }
    ''';

    final result = await _graphQLService.performQuery(
      query,
      variables: {'locationId': locationId, 'approvalStatus': 'PENDING'},
    );

    if (result.hasException) {
      throw Exception('Failed to fetch pending members: ${result.exception}');
    }

    final List data = result.data?['getMemberList'] as List? ?? [];
    return _sortByRoleOrder(
      data.map<MemberModel>((json) => MemberModel.fromJson(json)).toList(),
    );
  }

  @override
  Future<List<MemberModel>> getUserList({int? locationId, String? role}) async {
    const String query = r'''
      query GetMemberList($locationId: Int, $role: String, $approvalStatus: ApprovalStatus) {
        getMemberList(locationId: $locationId, role: $role, approvalStatus: $approvalStatus) {
          id
          name
          phone
          role
          approvalStatus
          isActive
          addedBy
          image
          location {
            id
            name
          }
        }
      }
    ''';

    final variables = <String, dynamic>{'approvalStatus': 'APPROVED'};
    if (locationId != null) variables['locationId'] = locationId;
    if (role != null) variables['role'] = role;

    final result = await _graphQLService.performQuery(
      query,
      variables: variables,
    );

    if (result.hasException) {
      throw Exception('Failed to fetch user list: ${result.exception}');
    }

    final List data = result.data?['getMemberList'] as List? ?? [];
    return _sortByRoleOrder(
      data.map<MemberModel>((json) => MemberModel.fromJson(json)).toList(),
    );
  }

  @override
  Future<MemberModel> getMemberDetails({required int id}) async {
    const String query = r'''
      query GetMemberDetails($id: Int!) {
        getMemberDetails(id: $id) {
          id
          name
          surname
          phone
          role
          approvalStatus
          profession
          bloodGroup
          addedBy
          createdAt
          dateOfBirth
          gender
          image
          location {
            id
            name
            type
            parentId
          }
          district
          constituency
          area
          street
          userLocations {
            isPrimary
            location {
              id
              name
              type
              parentId
            }
          }
        }
      }
    ''';

    final result = await _graphQLService.performQuery(
      query,
      variables: {'id': id},
    );

    if (result.hasException) {
      throw Exception('Failed to fetch member details: ${result.exception}');
    }

    final data = result.data?['getMemberDetails'] as Map<String, dynamic>?;
    if (data == null) throw Exception('Member not found');

    return MemberModel.fromJson(data);
  }

  @override
  Future<MemberModel> updateMember({
    required int id,
    String? name,
    String? surname,
    String? phone,
    String? bloodGroup,
    String? role,
    String? professionName,
    int? locationId,
    String? dateOfBirth,
    String? gender,
    String? image,
  }) async {
    const String mutation = r'''
      mutation UpdateMember($id: Int!, $name: String, $surname: String, $phone: String, $bloodGroup: String, $role: String, $professionName: String, $locationId: Int, $dateOfBirth: String, $gender: String, $image: String) {
        updateMember(id: $id, name: $name, surname: $surname, phone: $phone, bloodGroup: $bloodGroup, role: $role, professionName: $professionName, locationId: $locationId, dateOfBirth: $dateOfBirth, gender: $gender, image: $image) {
          id
          name
          surname
          phone
          role
          approvalStatus
          profession
          bloodGroup
          addedBy
          createdAt
          dateOfBirth
          gender
          image
          location {
            id
            name
            type
            parentId
          }
        }
      }
    ''';

    final result = await _graphQLService.performMutation(
      mutation,
      variables: {
        'id': id,
        'name': name,
        'surname': surname,
        'phone': phone,
        'bloodGroup': bloodGroup,
        'role': role,
        'professionName': professionName,
        'locationId': locationId,
        'dateOfBirth': dateOfBirth,
        'gender': gender,
        'image': image,
      },
    );

    if (result.hasException) {
      throw Exception('Failed to update member: ${result.exception}');
    }

    final raw = result.data?['updateMember'] as Map<String, dynamic>?;
    if (raw == null) throw Exception('Update failed');

    return MemberModel.fromJson(raw);
  }

  @override
  Future<MemberModel> updateMemberStatus({
    required int id,
    required String status,
  }) async {
    const String mutation = r'''
      mutation UpdateMemberStatus($id: Int!, $status: ApprovalStatus!) {
        updateMemberStatus(id: $id, status: $status) {
          id
          name
          phone
          role
          approvalStatus
          isActive
          location {
            id
            name
            type
            parentId
          }
        }
      }
    ''';

    final result = await _graphQLService.performMutation(
      mutation,
      variables: {'id': id, 'status': status},
    );

    if (result.hasException) {
      throw Exception('Failed to update member status: ${result.exception}');
    }

    final data = result.data?['updateMemberStatus'];
    if (data == null) throw Exception('Status update failed');
    return MemberModel.fromJson(data);
  }

  @override
  Future<MemberModel> addMember({
    required String name,
    String? surname,
    required String phone,
    String? password,
    String? bloodGroup,
    String? professionName,
    int? streetId,
    int? areaId,
    int? talukId,
    int? districtId,
    String? dateOfBirth,
    String? gender,
  }) async {
    const String mutation = r'''
      mutation AddMember(
        $name: String!
        $surname: String
        $phone: String!
        $password: String!
        $bloodGroup: String
        $professionName: String
        $streetId: Int
        $dateOfBirth: String
        $gender: String
      ) {
        addMember(
          name: $name
          surname: $surname
          phone: $phone
          password: $password
          bloodGroup: $bloodGroup
          professionName: $professionName
          streetId: $streetId
          dateOfBirth: $dateOfBirth
          gender: $gender
        ) {
          id
          name
          surname
          phone
          dateOfBirth
          gender
        }
      }
    ''';

    final result = await _graphQLService.performMutation(
      mutation,
      variables: {
        'name': name,
        'surname': surname,
        'phone': phone,
        'password': password,
        'bloodGroup': bloodGroup,
        'professionName': professionName,
        'streetId': streetId,
        'dateOfBirth': dateOfBirth,
        'gender': gender,
      },
    );

    if (result.hasException) {
      throw Exception('Failed to add member: ${result.exception}');
    }

    final data = result.data?['addMember'];
    if (data == null) throw Exception('Member creation failed');
    return MemberModel.fromJson(data);
  }

  @override
  Future<List<String>> getProfessions() async {
    const String query = r'''
      query Professions {
        professions {
          id
          name
        }
      }
    ''';

    final result = await _graphQLService.performQuery(query);

    if (result.hasException) {
      throw Exception('Failed to fetch professions: ${result.exception}');
    }

    final List data = result.data?['professions'] as List? ?? [];
    return data.map<String>((p) => p['name'] as String).toList();
  }

  List<MemberModel> _sortByRoleOrder(List<MemberModel> members) {
    final sortedMembers = List<MemberModel>.from(members);
    sortedMembers.sort((a, b) {
      final roleCompare = _roleRank(a.role).compareTo(_roleRank(b.role));
      if (roleCompare != 0) return roleCompare;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return sortedMembers;
  }

  int _roleRank(String? role) {
    switch (role?.trim().toUpperCase()) {
      case 'SUPER_ADMIN':
        return 0;
      case 'ADMIN':
        return 1;
      case 'SUB_ADMIN':
        return 2;
      case 'MEMBER':
        return 3;
      default:
        return 4;
    }
  }

  @override
  Future<void> changePassword({
    required int id,
    required String password,
  }) async {
    const String mutation = r'''
      mutation ChangePassword($id: Int!, $password: String!) {
        updateMember(id: $id, password: $password) {
          id
        }
      }
    ''';

    final result = await _graphQLService.performMutation(
      mutation,
      variables: {
        'id': id,
        'password': password,
      },
    );

    if (result.hasException) {
      final errors = result.exception?.graphqlErrors;
      if (errors != null && errors.isNotEmpty) {
        throw Exception(errors.first.message);
      }
      throw Exception('Failed to change password. Please try again.');
    }

    final data = result.data?['updateMember'];
    if (data == null) {
      throw Exception('Password update failed. Please try again.');
    }
  }
}
