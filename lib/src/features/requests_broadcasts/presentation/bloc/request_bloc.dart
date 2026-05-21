import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ntk_project/src/features/requests_broadcasts/data/models/emergency_request_model.dart';
import 'package:ntk_project/src/features/requests_broadcasts/domain/repositories/request_repository.dart';

// Events
abstract class RequestEvent extends Equatable {
  const RequestEvent();
  @override
  List<Object?> get props => [];
}

class LoadRequests extends RequestEvent {
  final int? locationId;
  final String? status;
  const LoadRequests({this.locationId, this.status});
  @override
  List<Object?> get props => [locationId, status];
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

// State
class RequestState extends Equatable {
  final bool isLoading;
  final List<EmergencyRequestModel> requests;
  final String? error;
  final bool isSubmitting;
  final bool submitSuccess;

  const RequestState({
    this.isLoading = false,
    this.requests = const [],
    this.error,
    this.isSubmitting = false,
    this.submitSuccess = false,
  });

  RequestState copyWith({
    bool? isLoading,
    List<EmergencyRequestModel>? requests,
    String? error,
    bool? isSubmitting,
    bool? submitSuccess,
  }) {
    return RequestState(
      isLoading: isLoading ?? this.isLoading,
      requests: requests ?? this.requests,
      error: error ?? this.error,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitSuccess: submitSuccess ?? this.submitSuccess,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    requests,
    error,
    isSubmitting,
    submitSuccess,
  ];
}

// Bloc
class RequestBloc extends Bloc<RequestEvent, RequestState> {
  final RequestRepository _repository;

  RequestBloc(this._repository) : super(const RequestState()) {
    on<LoadRequests>(_onLoadRequests);
    on<CreateRequest>(_onCreateRequest);
    on<UpdateRequestStatus>(_onUpdateStatus);
  }

  Future<void> _onLoadRequests(
    LoadRequests event,
    Emitter<RequestState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final requests = await _repository.getEmergencyRequestList(
        locationId: event.locationId,
        status: event.status,
      );
      emit(state.copyWith(isLoading: false, requests: requests));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onCreateRequest(
    CreateRequest event,
    Emitter<RequestState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true, error: null, submitSuccess: false));
    try {
      await _repository.createEmergencyRequest(
        title: event.title,
        description: event.description,
        type: event.type,
        locationId: event.locationId,
        audience: event.audience,
      );
      emit(state.copyWith(isSubmitting: false, submitSuccess: true));
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, error: e.toString()));
    }
  }

  Future<void> _onUpdateStatus(
    UpdateRequestStatus event,
    Emitter<RequestState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true, error: null));
    try {
      final updated = await _repository.updateRequestStatus(
        id: event.id,
        status: event.status,
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
}
