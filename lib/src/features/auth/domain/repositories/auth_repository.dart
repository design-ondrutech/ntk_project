import 'package:ntk_project/src/features/auth/data/models/admin_login_model.dart';

abstract class AuthRepository {
  Future<AdminLoginModel> login({
    required String phone,
    required String password,
  });

  Future<AdminLoginModel> getMe();

  Future<void> sendOtp(String phone);
  Future<Map<String, dynamic>> verifyOtp(String phone, String otp);
  Future<void> updateFcmToken(String token);
  Future<void> logout();

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
  });

  Future<AdminLoginModel?> getPersistedSession();
  Future<void> persistSession(AdminLoginModel model);
}
