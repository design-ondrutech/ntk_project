import 'package:equatable/equatable.dart';

abstract class EventEvent extends Equatable {
  const EventEvent();

  @override
  List<Object?> get props => [];
}

class FetchEvents extends EventEvent {
  final int? locationId;
  final int limit;

  const FetchEvents({this.locationId, this.limit = 10});

  @override
  List<Object?> get props => [locationId, limit];
}

class RespondToEvent extends EventEvent {
  final String eventId;
  final int memberId;
  final String status;

  const RespondToEvent({
    required this.eventId,
    required this.memberId,
    required this.status,
  });

  @override
  List<Object?> get props => [eventId, memberId, status];
}

class CreateEvent extends EventEvent {
  final String title;
  final String description;
  final String date;
  final int locationId;

  const CreateEvent({
    required this.title,
    required this.description,
    required this.date,
    required this.locationId,
  });

  @override
  List<Object?> get props => [title, description, date, locationId];
}
