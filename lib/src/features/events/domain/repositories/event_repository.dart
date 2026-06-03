import 'package:ntk_project/src/features/events/data/models/event_model.dart';
import 'package:ntk_project/src/features/events/data/models/emergency_model.dart';

abstract class EventRepository {
  Future<List<EventModel>> getRecentEvents({int? locationId, int limit = 10});
  Future<String> respondToEvent({
    required String eventId,
    required int memberId,
    required String status,
  });

  Future<List<EventResponseModel>> getEventResponses({required String eventId});
  Future<EventModel> getEventDetails({required String id});

  Future<EventModel> createEvent({
    required String title,
    required String description,
    required String date,
    required int locationId,
    List<String>? professionNames,
  });

  Future<EmergencyModel> createEmergency({
    required String title,
    String? description,
    required String type,
    required int locationId,
    String? contactName,
    String? contactPhone,
    String? expiryDate,
    bool? collectResponse,
  });

  Future<List<EmergencyModel>> getEmergencyList({int? locationId});
  Future<EmergencyModel> getEmergencyRequestDetails({required String id});

  Future<String> respondToEmergency({
    required String emergencyRequestId,
    required String status,
    String? note,
  });

  Future<List<EmergencyResponseModel>> getEmergencyResponses({
    required String emergencyRequestId,
  });
}
