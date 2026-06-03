import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/features/events/domain/repositories/event_repository.dart';
import 'event_event.dart';
import 'event_state.dart';
import 'package:ntk_project/src/features/events/data/models/event_model.dart';
import 'package:ntk_project/src/features/events/data/models/emergency_model.dart';

class EventBloc extends Bloc<EventEvent, EventState> {
  final EventRepository _eventRepository;

  EventBloc(this._eventRepository) : super(const EventState()) {
    on<FetchEvents>(_onFetchEvents);
    on<RespondToEvent>(_onRespondToEvent);
    on<CreateEvent>(_onCreateEvent);
    on<FetchEmergencies>(_onFetchEmergencies);
    on<FetchEventResponses>(_onFetchEventResponses);
    on<FetchEmergencyResponses>(_onFetchEmergencyResponses);
    on<CreateEmergency>(_onCreateEmergency);
    on<RespondToEmergency>(_onRespondToEmergency);
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

  Future<void> _onFetchEmergencies(
    FetchEmergencies event,
    Emitter<EventState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final emergencies = await _eventRepository.getEmergencyList(
        locationId: event.locationId,
      );
      emit(state.copyWith(isLoading: false, emergencies: emergencies));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onFetchEventResponses(
    FetchEventResponses event,
    Emitter<EventState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final responses = await _eventRepository.getEventResponses(
        eventId: event.eventId,
      );
      emit(state.copyWith(isLoading: false, eventResponses: responses));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onFetchEmergencyResponses(
    FetchEmergencyResponses event,
    Emitter<EventState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final responses = await _eventRepository.getEmergencyResponses(
        emergencyRequestId: event.emergencyRequestId,
      );
      emit(state.copyWith(isLoading: false, emergencyResponses: responses));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onCreateEmergency(
    CreateEmergency event,
    Emitter<EventState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      await _eventRepository.createEmergency(
        title: event.title,
        description: event.description,
        type: event.type,
        locationId: event.locationId,
        contactName: event.contactName,
        contactPhone: event.contactPhone,
        expiryDate: event.expiryDate,
        collectResponse: event.collectResponse,
      );

      final refreshed = await _eventRepository.getEmergencyList(
        locationId: event.locationId,
      );

      emit(
        state.copyWith(
          isLoading: false,
          emergencies: refreshed,
          message: 'Emergency Alert created successfully',
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: 'Failed to create alert: ${e.toString()}',
          clearMessage: true,
        ),
      );
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

  Future<void> _onRespondToEmergency(
    RespondToEmergency event,
    Emitter<EventState> emit,
  ) async {
    try {
      await _eventRepository.respondToEmergency(
        emergencyRequestId: event.emergencyRequestId,
        status: event.status,
        note: event.note,
      );

      final updatedEmergencies = state.emergencies.map((e) {
        if (e.id == event.emergencyRequestId) {
          int newGoing = e.going;
          int newMaybe = e.maybe;
          int newNotGoing = e.notGoing;

          if (event.status == 'COMING' || event.status == 'GOING') {
            newGoing++;
          } else if (event.status == 'MAYBE') {
            newMaybe++;
          } else if (event.status == 'UNABLE' || event.status == 'NOT_GOING') {
            newNotGoing++;
          }

          return EmergencyModel(
            id: e.id,
            title: e.title,
            description: e.description,
            type: e.type,
            contactName: e.contactName,
            contactPhone: e.contactPhone,
            expiryDate: e.expiryDate,
            collectResponse: e.collectResponse,
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
          emergencies: updatedEmergencies,
          message: 'Successfully responded to emergency',
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
        professionNames: event.professionNames,
      );

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
