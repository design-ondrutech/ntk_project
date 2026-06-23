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
    on<RecallEvent>(_onRecallEvent);
    on<ClearEventMessage>((event, emit) => emit(state.copyWith(clearMessage: true)));
    on<ClearEventError>((event, emit) => emit(state.copyWith(clearError: true)));
    on<ResetEvents>((event, emit) => emit(const EventState()));
  }

  Future<void> _onFetchEvents(
    FetchEvents event,
    Emitter<EventState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true, clearMessage: true));
    try {
      final events = await _eventRepository.getRecentEvents(
        locationId: event.locationId,
        limit: event.limit,
      );
      events.sort((a, b) => (b.date ?? '').compareTo(a.date ?? ''));
      emit(state.copyWith(isLoading: false, events: events));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onFetchEmergencies(
    FetchEmergencies event,
    Emitter<EventState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true, clearMessage: true));
    try {
      final emergencies = await _eventRepository.getEmergencyList(
        locationId: event.locationId,
      );
      emergencies.sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
      emit(state.copyWith(isLoading: false, emergencies: emergencies));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onFetchEventResponses(
    FetchEventResponses event,
    Emitter<EventState> emit,
  ) async {
    // Use isResponsesLoading (not isLoading) so the RSVP UI stays enabled
    // while responses are being fetched and doesn't appear disabled.
    emit(state.copyWith(isResponsesLoading: true, clearError: true));
    try {
      final responses = await _eventRepository.getEventResponses(
        eventId: event.eventId,
      );
      emit(state.copyWith(isResponsesLoading: false, eventResponses: responses));
    } catch (e) {
      emit(state.copyWith(isResponsesLoading: false, error: e.toString()));
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
      refreshed.sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));

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
      // Optimistic update
      final optimisticResponses = List<EventResponseModel>.from(state.eventResponses);
      final existingIndex = optimisticResponses.indexWhere((r) => r.member.id == event.memberId.toString());
      if (existingIndex >= 0) {
        optimisticResponses[existingIndex] = EventResponseModel(
          status: event.status,
          member: optimisticResponses[existingIndex].member,
        );
      } else {
        optimisticResponses.add(EventResponseModel(
          status: event.status,
          member: EventMemberModel(id: event.memberId.toString(), name: 'You', phone: ''),
        ));
      }
      
      final updatedMyResponses = Map<String, String>.from(state.myEventResponses);
      updatedMyResponses[event.eventId] = event.status;

      // Emit optimistic state immediately
      emit(state.copyWith(
        eventResponses: optimisticResponses,
        myEventResponses: updatedMyResponses,
      ));
      await _eventRepository.respondToEvent(
        eventId: event.eventId,
        memberId: event.memberId,
        status: event.status,
      );

      final responses = await _eventRepository.getEventResponses(
        eventId: event.eventId,
      );

      int goingCount = 0;
      int maybeCount = 0;
      int notGoingCount = 0;
      for (final r in responses) {
        if (r.status == 'GOING') {
          goingCount++;
        } else if (r.status == 'MAYBE') {
          maybeCount++;
        } else if (r.status == 'NOT_GOING') {
          notGoingCount++;
        }
      }

      final updatedEvents = state.events.map((e) {
        if (e.id == event.eventId) {
          return EventModel(
            id: e.id,
            title: e.title,
            description: e.description,
            date: e.date,
            locationName: e.locationName,
            going: goingCount,
            maybe: maybeCount,
            notGoing: notGoingCount,
            createdById: e.createdById, // preserve creator info
          );
        }
        return e;
      }).toList();

      emit(
        state.copyWith(
          events: updatedEvents,
          eventResponses: responses.isNotEmpty ? responses : optimisticResponses,
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
    // ── Optimistic update: reflect response immediately in UI ──
    final optimisticUserId = event.userId ?? '__optimistic__';

    // Build a temporary local response so buttons disable instantly
    final tempResponse = EmergencyResponseModel(
      status: event.status,
      member: EmergencyMemberModel(id: optimisticUserId, name: 'You', phone: ''),
    );
    final optimisticList = [...state.emergencyResponses, tempResponse];

    // Update counters optimistically on the emergency card
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
        return e.copyWith(going: newGoing, maybe: newMaybe, notGoing: newNotGoing);
      }
      return e;
    }).toList();

    // Persist response locally in map
    final updatedMyResponses = Map<String, String>.from(state.myEmergencyResponses);
    updatedMyResponses[event.emergencyRequestId] = event.status;

    // Emit optimistic state IMMEDIATELY (button disables, UI updates)
    emit(state.copyWith(
      emergencies: updatedEmergencies,
      emergencyResponses: optimisticList,
      myEmergencyResponses: updatedMyResponses,
      message: 'Successfully responded to emergency',
      clearError: true,
    ));

    try {
      await _eventRepository.respondToEmergency(
        emergencyRequestId: event.emergencyRequestId,
        status: event.status,
        note: event.note,
      );

      // Silently refresh actual responses from server in background
      final responses = await _eventRepository.getEmergencyResponses(
        emergencyRequestId: event.emergencyRequestId,
      );
      emit(state.copyWith(
        emergencyResponses: responses,
        clearError: true,
      ));
    } catch (e) {
      // Rollback optimistic update on failure
      emit(state.copyWith(
        emergencies: state.emergencies,
        emergencyResponses: state.emergencyResponses,
        error: 'Failed to respond: ${e.toString()}',
        clearMessage: true,
      ));
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
      refreshed.sort((a, b) => (b.date ?? '').compareTo(a.date ?? ''));

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

  Future<void> _onRecallEvent(
    RecallEvent event,
    Emitter<EventState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final success = await _eventRepository.recallEvent(id: event.id);
      if (success) {
        final updatedEvents = state.events.where((e) => e.id != event.id).toList();
        emit(
          state.copyWith(
            isLoading: false,
            events: updatedEvents,
            message: 'Event recalled successfully',
            clearError: true,
          ),
        );
      } else {
        throw Exception('Recall action returned failure status');
      }
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: 'Failed to recall event: ${e.toString()}',
          clearMessage: true,
        ),
      );
    }
  }
}
