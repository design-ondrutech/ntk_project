import 'package:ntk_project/src/features/members/data/models/member_model.dart';

abstract class MemberRepository {
  Future<List<MemberModel>> getMembers({
    int? locationId,
    int? professionId,
    String? bloodGroup,
    String? search,
    String? role,
    int? limit,
    int? offset,
  });

  Future<List<MemberModel>> getMemberList({
    int? locationId,
    String? approvalStatus,
    String? role,
    String? bloodGroup,
    String? professionName,
    int? limit,
    int? offset,
  });

  Future<List<MemberModel>> getPendingMembers({int? locationId});

  Future<List<MemberModel>> getUserList({int? locationId, String? role});

  Future<MemberModel> getMemberDetails({required int id});

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
  });

  Future<MemberModel> updateMemberStatus({
    required int id,
    required String status,
  });

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
  });

  Future<List<String>> getProfessions();
}
