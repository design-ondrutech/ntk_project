import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ntk_project/src/features/requests_broadcasts/data/models/broadcast_model.dart';
import 'package:ntk_project/src/features/requests_broadcasts/data/models/emergency_request_model.dart';
import 'package:ntk_project/src/features/requests_broadcasts/domain/repositories/request_repository.dart';

// Events
abstract class RequestEvent extends Equatable {
  const RequestEvent();
  @override
  List<Object?> get props => [];
}

class ClearSubmitStatus extends RequestEvent {}

class ResetRequests extends RequestEvent {}

class LoadRequests extends RequestEvent {
  final int? locationId;
  final String? status;
  final String? scope;
  const LoadRequests({this.locationId, this.status, this.scope});
  @override
  List<Object?> get props => [locationId, status, scope];
}

class LoadBroadcastDetails extends RequestEvent {
  final int id;
  const LoadBroadcastDetails(this.id);
  @override
  List<Object?> get props => [id];
}

class CreateBroadcastMessage extends RequestEvent {
  final String title;
  final String message;
  final int locationId;

  const CreateBroadcastMessage({
    required this.title,
    required this.message,
    required this.locationId,
  });

  @override
  List<Object?> get props => [title, message, locationId];
}

class CreateRequest extends RequestEvent {
  final String title;
  final String description;
  final String type;
  final int locationId;
  final String? audience;
  const CreateRequest({
    required this.title,
    required this.description,
    required this.type,
    required this.locationId,
    this.audience,
  });
  @override
  List<Object?> get props => [title, description, type, locationId, audience];
}

class UpdateRequestStatus extends RequestEvent {
  final int id;
  final String status;
  const UpdateRequestStatus({required this.id, required this.status});
  @override
  List<Object?> get props => [id, status];
}

class RecallBroadcast extends RequestEvent {
  final int id;
  final int? locationId;
  const RecallBroadcast({required this.id, this.locationId});
  @override
  List<Object?> get props => [id, locationId];
}

// State
class RequestState extends Equatable {
  final bool isLoading;
  final List<BroadcastModel> broadcasts;
  final List<EmergencyRequestModel> requests;
  final String? error;
  final bool isSubmitting;
  final bool submitSuccess;
  final BroadcastModel? currentBroadcast;

  const RequestState({
    this.isLoading = false,
    this.broadcasts = const [],
    this.requests = const [],
    this.error,
    this.isSubmitting = false,
    this.submitSuccess = false,
    this.currentBroadcast,
  });

  RequestState copyWith({
    bool? isLoading,
    List<BroadcastModel>? broadcasts,
    List<EmergencyRequestModel>? requests,
    String? error,
    bool clearError = false,
    bool? isSubmitting,
    bool? submitSuccess,
    BroadcastModel? currentBroadcast,
  }) {
    return RequestState(
      isLoading: isLoading ?? this.isLoading,
      broadcasts: broadcasts ?? this.broadcasts,
      requests: requests ?? this.requests,
      error: clearError ? null : (error ?? this.error),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitSuccess: submitSuccess ?? this.submitSuccess,
      currentBroadcast: currentBroadcast ?? this.currentBroadcast,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    broadcasts,
    requests,
    error,
    isSubmitting,
    submitSuccess,
    currentBroadcast,
  ];
}

// Bloc
class RequestBloc extends Bloc<RequestEvent, RequestState> {
  final RequestRepository _repository;

  RequestBloc(this._repository) : super(const RequestState()) {
    on<LoadRequests>(_onLoadRequests);
    on<LoadBroadcastDetails>(_onLoadBroadcastDetails);
    on<CreateBroadcastMessage>(_onCreateBroadcastMessage);
    on<CreateRequest>(_onCreateRequest);
    on<UpdateRequestStatus>(_onUpdateStatus);
    on<RecallBroadcast>(_onRecallBroadcast);
    on<ResetRequests>((event, emit) => emit(const RequestState()));
    on<ClearSubmitStatus>(
      (event, emit) => emit(
        state.copyWith(
          submitSuccess: false,
          isSubmitting: false,
          clearError: true,
        ),
      ),
    );
  }

  Future<void> _onLoadRequests(
    LoadRequests event,
    Emitter<RequestState> emit,
  ) async {
    emit(
      state.copyWith(isLoading: true, clearError: true, submitSuccess: false),
    );
    try {
      final broadcasts = await _repository.getBroadcasts(
        locationId: event.locationId,
        scope: event.scope,
      );
      final requests = await _repository.getEmergencyRequestList(
        locationId: event.locationId,
        status: event.status,
      );

      // Sort by latest created date first
      broadcasts.sort(
        (a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''),
      );
      requests.sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));

      emit(
        state.copyWith(
          isLoading: false,
          broadcasts: broadcasts,
          requests: requests,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onLoadBroadcastDetails(
    LoadBroadcastDetails event,
    Emitter<RequestState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final broadcast = await _repository.getBroadcastDetails(id: event.id);
      emit(state.copyWith(isLoading: false, currentBroadcast: broadcast));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onCreateBroadcastMessage(
    CreateBroadcastMessage event,
    Emitter<RequestState> emit,
  ) async {
    emit(
      state.copyWith(
        isSubmitting: true,
        clearError: true,
        submitSuccess: false,
      ),
    );
    try {
      await _repository.createBroadcast(
        title: event.title,
        message: event.message,
        locationId: event.locationId,
      );
      emit(state.copyWith(isSubmitting: false, submitSuccess: true));
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, error: e.toString()));
    }
  }

  Future<void> _onCreateRequest(
    CreateRequest event,
    Emitter<RequestState> emit,
  ) async {
    emit(
      state.copyWith(
        isSubmitting: true,
        clearError: true,
        submitSuccess: false,
      ),
    );
    try {
      await _repository.createEmergencyRequest(
        title: event.title,
        description: event.description,
        type: event.type,
        locationId: event.locationId,
        audience: event.audience,
      );
      final requests = await _repository.getEmergencyRequestList(
        locationId: event.locationId,
      );
      emit(
        state.copyWith(
          isSubmitting: false,
          submitSuccess: true,
          requests: requests,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, error: e.toString()));
    }
  }

  Future<void> _onUpdateStatus(
    UpdateRequestStatus event,
    Emitter<RequestState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));
    try {
      final action = switch (event.status.toUpperCase()) {
        'APPROVED' || 'ACCEPTED' || 'ACCEPT' => 'ACCEPT',
        'REJECTED' || 'REJECT' => 'REJECT',
        'FORWARDED' || 'FORWARD' => 'FORWARD',
        _ => event.status,
      };
      final updated = await _repository.reviewEmergencyRequest(
        id: event.id,
        action: action,
      );
      final updatedList = state.requests
          .map((r) => r.id == updated.id ? updated : r)
          .toList();
      emit(
        state.copyWith(
          isSubmitting: false,
          requests: updatedList,
          submitSuccess: true,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, error: e.toString()));
    }
  }

  Future<void> _onRecallBroadcast(
    RecallBroadcast event,
    Emitter<RequestState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final success = await _repository.recallBroadcast(id: event.id);
      if (success) {
        final updatedBroadcasts = state.broadcasts
            .where((b) => b.id != event.id)
            .toList();
        emit(
          state.copyWith(
            isLoading: false,
            broadcasts: updatedBroadcasts,
            submitSuccess: true,
          ),
        );
      } else {
        throw Exception('Recall action returned failure status');
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }
}
