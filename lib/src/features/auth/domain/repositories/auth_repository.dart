import 'package:ntk_project/src/features/auth/data/models/admin_login_model.dart';

abstract class AuthRepository {
  Future<AdminLoginModel> login({
    required String phone,
    required String password,
    String? role,
  });

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
  });
}
