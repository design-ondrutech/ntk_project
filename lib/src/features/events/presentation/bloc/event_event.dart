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
  final List<String>? professionNames;

  const CreateEvent({
    required this.title,
    required this.description,
    required this.date,
    required this.locationId,
    this.professionNames,
  });

  @override
  List<Object?> get props => [
    title,
    description,
    date,
    locationId,
    professionNames,
  ];
}

class FetchEmergencies extends EventEvent {
  final int? locationId;

  const FetchEmergencies({this.locationId});

  @override
  List<Object?> get props => [locationId];
}

class FetchEventResponses extends EventEvent {
  final String eventId;

  const FetchEventResponses({required this.eventId});

  @override
  List<Object?> get props => [eventId];
}

class FetchEmergencyResponses extends EventEvent {
  final String emergencyRequestId;

  const FetchEmergencyResponses({required this.emergencyRequestId});

  @override
  List<Object?> get props => [emergencyRequestId];
}

class CreateEmergency extends EventEvent {
  final String title;
  final String? description;
  final String type;
  final int locationId;
  final String? contactName;
  final String? contactPhone;
  final String? expiryDate;
  final bool? collectResponse;

  const CreateEmergency({
    required this.title,
    this.description,
    required this.type,
    required this.locationId,
    this.contactName,
    this.contactPhone,
    this.expiryDate,
    this.collectResponse,
  });

  @override
  List<Object?> get props => [
    title,
    description,
    type,
    locationId,
    contactName,
    contactPhone,
    expiryDate,
    collectResponse,
  ];
}

class RespondToEmergency extends EventEvent {
  final String emergencyRequestId;
  final String status;
  final String? note;

  const RespondToEmergency({
    required this.emergencyRequestId,
    required this.status,
    this.note,
  });

  @override
  List<Object?> get props => [emergencyRequestId, status, note];
}

class RecallEvent extends EventEvent {
  final String id;

  const RecallEvent({required this.id});

  @override
  List<Object?> get props => [id];
}
