import 'package:ntk_project/src/features/requests_broadcasts/data/models/emergency_request_model.dart';
import 'package:ntk_project/src/features/requests_broadcasts/data/models/broadcast_model.dart';

abstract class RequestRepository {
  Future<List<BroadcastModel>> getBroadcasts({int? locationId, String? scope});
  Future<BroadcastModel> getBroadcastDetails({required int id});

  Future<BroadcastModel> createBroadcast({
    required String title,
    required String message,
    String? image,
    required int locationId,
    int? streetId,
  });

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

  Future<EmergencyRequestModel> reviewEmergencyRequest({
    required int id,
    required String action,
    String? rejectReason,
  });
}
