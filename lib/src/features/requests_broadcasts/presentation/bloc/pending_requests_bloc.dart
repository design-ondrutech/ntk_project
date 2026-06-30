import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ntk_project/src/core/network/graphql_service.dart';
import 'package:ntk_project/src/features/requests_broadcasts/data/models/pending_request_model.dart';

// Events
abstract class PendingRequestsEvent extends Equatable {
  const PendingRequestsEvent();
  @override
  List<Object?> get props => [];
}

class ResetPendingRequests extends PendingRequestsEvent {
  const ResetPendingRequests();
}

class LoadPendingRequests extends PendingRequestsEvent {
  final int? locationId;
  final String? role;
  const LoadPendingRequests({this.locationId, this.role});
  @override
  List<Object?> get props => [locationId, role];
}

class ApproveRequest extends PendingRequestsEvent {
  final int id;
  final String type; // 'USER' or 'MEMBER'
  const ApproveRequest({required this.id, required this.type});
  @override
  List<Object?> get props => [id, type];
}

class RejectRequest extends PendingRequestsEvent {
  final int id;
  final String type; // 'USER' or 'MEMBER'
  const RejectRequest({required this.id, required this.type});
  @override
  List<Object?> get props => [id, type];
}

// State
class PendingRequestsState extends Equatable {
  final bool isLoading;
  final List<PendingRequestModel> requests;
  final String? error;
  final String? message;

  const PendingRequestsState({
    this.isLoading = false,
    this.requests = const [],
    this.error,
    this.message,
  });

  PendingRequestsState copyWith({
    bool? isLoading,
    List<PendingRequestModel>? requests,
    String? error,
    String? message,
  }) {
    return PendingRequestsState(
      isLoading: isLoading ?? this.isLoading,
      requests: requests ?? this.requests,
      error: error ?? this.error,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [isLoading, requests, error, message];
}

// Bloc
class PendingRequestsBloc
    extends Bloc<PendingRequestsEvent, PendingRequestsState> {
  final GraphQLService _graphQLService;
  int? _currentLocationId;
  String? _currentRole;

  PendingRequestsBloc(this._graphQLService)
    : super(const PendingRequestsState()) {
    on<LoadPendingRequests>(_onLoadRequests);
    on<ApproveRequest>(_onApproveRequest);
    on<RejectRequest>(_onRejectRequest);
    on<ResetPendingRequests>((event, emit) => emit(const PendingRequestsState()));
  }

  Future<void> _onLoadRequests(
    LoadPendingRequests event,
    Emitter<PendingRequestsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      const String query = r'''
        query GetMemberList($locationId: Int, $approvalStatus: ApprovalStatus) {
          getMemberList(locationId: $locationId, approvalStatus: $approvalStatus) {
            id
            name
            phone
            role
            approvalStatus
            createdAt
            image
            location {
              id
              name
            }
          }
        }
      ''';

      _currentLocationId = event.locationId;
      _currentRole = event.role;

      final variables = <String, dynamic>{'approvalStatus': 'PENDING'};
      if (event.locationId != null) {
        variables['locationId'] = event.locationId;
      }

      final result = await _graphQLService.performQuery(
        query,
        variables: variables,
      );

      if (result.hasException) {
        throw Exception(result.exception.toString());
      }

      final List data = result.data?['getMemberList'] as List? ?? [];
      final requests = data
          .map((json) => PendingRequestModel.fromJson(json))
          .toList();

      emit(state.copyWith(isLoading: false, requests: requests));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onApproveRequest(
    ApproveRequest event,
    Emitter<PendingRequestsState> emit,
  ) async {
    try {
      const String mutation = r'''
        mutation UpdateMemberStatus($id: Int!, $status: ApprovalStatus!) {
          updateMemberStatus(id: $id, status: $status) {
            id
            name
            phone
          }
        }
      ''';

      final result = await _graphQLService.performMutation(
        mutation,
        variables: {'id': event.id, 'status': 'APPROVED'},
      );

      if (result.hasException) throw Exception(result.exception.toString());

      emit(state.copyWith(message: 'Request approved successfully'));
      add(
        LoadPendingRequests(locationId: _currentLocationId, role: _currentRole),
      );
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onRejectRequest(
    RejectRequest event,
    Emitter<PendingRequestsState> emit,
  ) async {
    try {
      const String mutation = r'''
        mutation UpdateMemberStatus($id: Int!, $status: ApprovalStatus!) {
          updateMemberStatus(id: $id, status: $status) {
            id
            name
            phone
          }
        }
      ''';

      final result = await _graphQLService.performMutation(
        mutation,
        variables: {'id': event.id, 'status': 'REJECTED'},
      );

      if (result.hasException) throw Exception(result.exception.toString());

      emit(state.copyWith(message: 'Request rejected'));
      add(
        LoadPendingRequests(locationId: _currentLocationId, role: _currentRole),
      );
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}
