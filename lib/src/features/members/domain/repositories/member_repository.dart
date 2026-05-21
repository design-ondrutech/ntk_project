import 'package:ntk_project/src/features/members/data/models/member_model.dart';

abstract class MemberRepository {
  Future<List<MemberModel>> getMembers({
    int? locationId,
    int? professionId,
    String? bloodGroup,
    String? search,
    int? limit,
    int? offset,
  });

  Future<List<MemberModel>> getMemberList({
    int? locationId,
    String? approvalStatus,
  });

  Future<List<MemberModel>> getUserList({int? locationId, String? role});

  Future<MemberModel> getMemberDetails({required int id});

  Future<MemberModel> updateMember({
    required int id,
    String? name,
    String? phone,
    String? bloodGroup,
    String? role,
    String? professionName,
    int? locationId,
  });

  Future<MemberModel> updateMemberStatus({
    required int id,
    required String status,
  });

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
  });

  Future<List<String>> getProfessions();
}
