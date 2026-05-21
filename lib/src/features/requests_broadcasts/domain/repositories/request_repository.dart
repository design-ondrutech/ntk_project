import 'package:ntk_project/src/features/requests_broadcasts/data/models/emergency_request_model.dart';

abstract class RequestRepository {
  Future<List<EmergencyRequestModel>> getEmergencyRequestList({
    int? locationId,
    String? status,
  });

  Future<EmergencyRequestModel> createEmergencyRequest({
    required String title,
    required String description,
    required String type,
    required int locationId,
    String? audience,
  });

  Future<EmergencyRequestModel> updateRequestStatus({
    required int id,
    required String status,
  });
}
