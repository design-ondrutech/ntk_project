import 'package:equatable/equatable.dart';
import 'package:ntk_project/src/features/events/data/models/event_model.dart';
import 'package:ntk_project/src/features/events/data/models/emergency_model.dart';

class EventState extends Equatable {
  final bool isLoading;

  /// Separate loading flag for fetching RSVP responses only.
  /// Avoids disabling the RSVP UI when other event data is loading.
  final bool isResponsesLoading;

  final List<EventModel> events;
  final List<EmergencyModel> emergencies;
  final List<EventResponseModel> eventResponses;
  final List<EmergencyResponseModel> emergencyResponses;
  final String? error;
  final String? message;

  /// Locally tracks which emergencies the current user has responded to.
  /// Key: emergencyRequestId, Value: response status (e.g. 'COMING', 'UNABLE')
  /// Persists across back/forward navigation for the current app session.
  final Map<String, String> myEmergencyResponses;

  /// Locally tracks which events the current user has responded to.
  /// Key: eventId, Value: response status (e.g. 'GOING', 'MAYBE', 'NOT_GOING')
  final Map<String, String> myEventResponses;

  const EventState({
    this.isLoading = false,
    this.isResponsesLoading = false,
    this.events = const [],
    this.emergencies = const [],
    this.eventResponses = const [],
    this.emergencyResponses = const [],
    this.myEmergencyResponses = const {},
    this.myEventResponses = const {},
    this.error,
    this.message,
  });

  EventState copyWith({
    bool? isLoading,
    bool? isResponsesLoading,
    List<EventModel>? events,
    List<EmergencyModel>? emergencies,
    List<EventResponseModel>? eventResponses,
    List<EmergencyResponseModel>? emergencyResponses,
    Map<String, String>? myEmergencyResponses,
    Map<String, String>? myEventResponses,
    String? error,
    String? message,
    bool clearError = false,
    bool clearMessage = false,
  }) {
    return EventState(
      isLoading: isLoading ?? this.isLoading,
      isResponsesLoading: isResponsesLoading ?? this.isResponsesLoading,
      events: events ?? this.events,
      emergencies: emergencies ?? this.emergencies,
      eventResponses: eventResponses ?? this.eventResponses,
      emergencyResponses: emergencyResponses ?? this.emergencyResponses,
      myEmergencyResponses: myEmergencyResponses ?? this.myEmergencyResponses,
      myEventResponses: myEventResponses ?? this.myEventResponses,
      error: clearError ? null : (error ?? this.error),
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isResponsesLoading,
    events,
    emergencies,
    eventResponses,
    emergencyResponses,
    myEmergencyResponses,
    myEventResponses,
    error,
    message,
  ];
}
