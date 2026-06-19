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

  const EventState({
    this.isLoading = false,
    this.isResponsesLoading = false,
    this.events = const [],
    this.emergencies = const [],
    this.eventResponses = const [],
    this.emergencyResponses = const [],
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
    error,
    message,
  ];
}
