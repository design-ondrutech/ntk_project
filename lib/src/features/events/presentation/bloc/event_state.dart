import 'package:equatable/equatable.dart';
import 'package:ntk_project/src/features/events/data/models/event_model.dart';

class EventState extends Equatable {
  final bool isLoading;
  final List<EventModel> events;
  final String? error;
  final String? message;

  const EventState({
    this.isLoading = false,
    this.events = const [],
    this.error,
    this.message,
  });

  EventState copyWith({
    bool? isLoading,
    List<EventModel>? events,
    String? error,
    String? message,
    bool clearError = false,
    bool clearMessage = false,
  }) {
    return EventState(
      isLoading: isLoading ?? this.isLoading,
      events: events ?? this.events,
      error: clearError ? null : (error ?? this.error),
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [isLoading, events, error, message];
}
