import 'package:ntk_project/src/features/events/data/models/event_model.dart';

abstract class EventRepository {
  Future<List<EventModel>> getRecentEvents({int? locationId, int limit = 10});
  Future<String> respondToEvent({
    required String eventId,
    required int memberId,
    required String status,
  });

  Future<EventModel> createEvent({
    required String title,
    required String description,
    required String date,
    required int locationId,
  });
}
