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
    int? limit,
    int? offset,
  }) async {
    const String query = r'''
      query GetMemberList($locationId: Int, $bloodGroup: String, $search: String, $limit: Int, $offset: Int, $approvalStatus: ApprovalStatus) {
        getMemberList(locationId: $locationId, bloodGroup: $bloodGroup, search: $search, limit: $limit, offset: $offset, approvalStatus: $approvalStatus) {
          id
          name
          phone
          role
          approvalStatus
          isActive
          bloodGroup
          profession
          location {
            id
            name
          }
          createdAt
        }
      }
    ''';

    final result = await _graphQLService.performQuery(
      query,
      variables: {
        'locationId': locationId,
        'bloodGroup': bloodGroup,
        'search': search,
        'limit': limit,
        'offset': offset,
      },
    );

    if (result.hasException) {
      throw Exception('Failed to fetch members: ${result.exception}');
    }

    final List data = result.data?['getMemberList'] as List? ?? [];
    return data.map<MemberModel>((json) => MemberModel.fromJson(json)).toList();
  }

  @override
  Future<List<MemberModel>> getMemberList({
    int? locationId,
    String? approvalStatus,
  }) async {
    const String query = r'''
      query GetMemberList($locationId: Int, $approvalStatus: ApprovalStatus) {
        getMemberList(locationId: $locationId, approvalStatus: $approvalStatus) {
          id
          name
          phone
          role
          approvalStatus
          isActive
          bloodGroup
          profession
          location {
            id
            name
          }
          createdAt
        }
      }
    ''';

    final result = await _graphQLService.performQuery(
      query,
      variables: {'locationId': locationId, 'approvalStatus': approvalStatus},
    );

    if (result.hasException) {
      throw Exception('Failed to fetch member list: ${result.exception}');
    }

    final List data = result.data?['getMemberList'] as List? ?? [];
    return data.map<MemberModel>((json) => MemberModel.fromJson(json)).toList();
  }

  @override
  Future<List<MemberModel>> getUserList({int? locationId, String? role}) async {
    const String query = r'''
      query GetUserList($locationId: Int, $role: UserRole) {
        getUserList(locationId: $locationId, role: $role) {
          id
          name
          phone
          role
          approvalStatus
          isActive
          location {
            id
            name
          }
        }
      }
    ''';

    final result = await _graphQLService.performQuery(
      query,
      variables: {'locationId': locationId, 'role': role},
    );

    if (result.hasException) {
      throw Exception('Failed to fetch user list: ${result.exception}');
    }

    final List data = result.data?['getUserList'] as List? ?? [];
    return data.map<MemberModel>((json) => MemberModel.fromJson(json)).toList();
  }

  @override
  Future<MemberModel> getMemberDetails({required int id}) async {
    const String query = r'''
      query GetMemberDetails($id: Int!) {
        getMemberDetails(id: $id) {
          id
          name
          phone
          role
          approvalStatus
          isActive
          bloodGroup
          profession
          location {
            id
            name
          }
          createdAt
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

    final data = result.data?['getMemberDetails'];
    if (data == null) throw Exception('Member not found');
    return MemberModel.fromJson(data);
  }

  @override
  Future<MemberModel> updateMember({
    required int id,
    String? name,
    String? phone,
    String? bloodGroup,
    String? role,
    String? professionName,
    int? locationId,
  }) async {
    const String mutation = r'''
      mutation UpdateMember($id: Int!, $name: String, $phone: String, $bloodGroup: String, $role: String, $professionName: String, $locationId: Int) {
        updateMember(id: $id, name: $name, phone: $phone, bloodGroup: $bloodGroup, role: $role, professionName: $professionName, locationId: $locationId) {
          id
          name
          phone
          role
          approvalStatus
          isActive
          bloodGroup
          profession
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
        'id': id,
        'name': name,
        'phone': phone,
        'bloodGroup': bloodGroup,
        'role': role,
        'professionName': professionName,
        'locationId': locationId,
      },
    );

    if (result.hasException) {
      throw Exception('Failed to update member: ${result.exception}');
    }

    final data = result.data?['updateMember'];
    if (data == null) throw Exception('Update failed');
    return MemberModel.fromJson(data);
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
    required String phone,
    String? password,
    String? bloodGroup,
    String? professionName,
    int? streetId,
    int? areaId,
    int? talukId,
    int? districtId,
  }) async {
    const String mutation = r'''
      mutation AddMember($name: String!, $phone: String!, $password: String, $bloodGroup: String, $professionName: String, $streetId: Int, $areaId: Int, $talukId: Int, $districtId: Int) {
        addMember(name: $name, phone: $phone, password: $password, bloodGroup: $bloodGroup, professionName: $professionName, streetId: $streetId, areaId: $areaId, talukId: $talukId, districtId: $districtId) {
          id
          name
          phone
          role
          approvalStatus
          isActive
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
        'name': name,
        'phone': phone,
        'password': password,
        'bloodGroup': bloodGroup,
        'professionName': professionName,
        'streetId': streetId,
        'areaId': areaId,
        'talukId': talukId,
        'districtId': districtId,
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
}
