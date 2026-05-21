import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/features/events/domain/repositories/event_repository.dart';
import 'event_event.dart';
import 'event_state.dart';
import 'package:ntk_project/src/features/events/data/models/event_model.dart';

class EventBloc extends Bloc<EventEvent, EventState> {
  final EventRepository _eventRepository;

  EventBloc(this._eventRepository) : super(const EventState()) {
    on<FetchEvents>(_onFetchEvents);
    on<RespondToEvent>(_onRespondToEvent);
    on<CreateEvent>(_onCreateEvent);
  }

  Future<void> _onFetchEvents(
    FetchEvents event,
    Emitter<EventState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final events = await _eventRepository.getRecentEvents(
        locationId: event.locationId,
        limit: event.limit,
      );
      emit(state.copyWith(isLoading: false, events: events));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onRespondToEvent(
    RespondToEvent event,
    Emitter<EventState> emit,
  ) async {
    try {
      await _eventRepository.respondToEvent(
        eventId: event.eventId,
        memberId: event.memberId,
        status: event.status,
      );

      // Update the local list optimistically or refetch
      // For simplicity, we can just refetch all events if locationId is available,
      // but we don't have locationId directly here unless we save it.
      // Alternatively, we can just update the specific event's stats optimistically.

      final updatedEvents = state.events.map((e) {
        if (e.id == event.eventId) {
          int newGoing = e.going;
          int newMaybe = e.maybe;
          int newNotGoing = e.notGoing;

          if (event.status == 'GOING') {
            newGoing++;
          } else if (event.status == 'MAYBE') {
            newMaybe++;
          } else if (event.status == 'NOT_GOING') {
            newNotGoing++;
          }

          return EventModel(
            id: e.id,
            title: e.title,
            description: e.description,
            date: e.date,
            locationName: e.locationName,
            going: newGoing,
            maybe: newMaybe,
            notGoing: newNotGoing,
          );
        }
        return e;
      }).toList();

      emit(
        state.copyWith(
          events: updatedEvents,
          message: 'Successfully responded to event',
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          error: 'Failed to respond: ${e.toString()}',
          clearMessage: true,
        ),
      );
    }
  }

  Future<void> _onCreateEvent(
    CreateEvent event,
    Emitter<EventState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      await _eventRepository.createEvent(
        title: event.title,
        description: event.description,
        date: event.date,
        locationId: event.locationId,
      );

      // Refresh the full list so the new event appears with correct data
      final refreshed = await _eventRepository.getRecentEvents(
        locationId: event.locationId,
        limit: 10,
      );

      emit(
        state.copyWith(
          isLoading: false,
          events: refreshed,
          message: 'Event created successfully',
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: 'Failed to create event: ${e.toString()}',
          clearMessage: true,
        ),
      );
    }
  }
}
