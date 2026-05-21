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
class PendingRequestsBloc extends Bloc<PendingRequestsEvent, PendingRequestsState> {
  final GraphQLService _graphQLService;

  PendingRequestsBloc(this._graphQLService) : super(const PendingRequestsState()) {
    on<LoadPendingRequests>(_onLoadRequests);
    on<ApproveRequest>(_onApproveRequest);
    on<RejectRequest>(_onRejectRequest);
  }

  Future<void> _onLoadRequests(
    LoadPendingRequests event,
    Emitter<PendingRequestsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      const String query = r'''
        query GetPendingRequests($locationId: Int, $role: String) {
          pendingRequests(locationId: $locationId, role: $role) {
            id
            name
            phone
            role
            type
            createdAt
            location {
              id
              name
            }
          }
        }
      ''';

      final result = await _graphQLService.performQuery(
        query,
        variables: {
          'locationId': event.locationId,
          'role': event.role == 'All' ? null : event.role,
        },
      );

      if (result.hasException) {
        throw Exception(result.exception.toString());
      }

      final List data = result.data?['pendingRequests'] as List? ?? [];
      final requests = data.map((json) => PendingRequestModel.fromJson(json)).toList();
      
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
      // For standard members, we use updateMemberStatus
      // For Users (Admins/Sub Admins), we might need another mutation
      // However, for simplicity, let's assume updateMemberStatus handles Member table
      // and we add updateAdminStatus for User table.
      
      const String mutation = r'''
        mutation UpdateStatus($id: Int!, $status: ApprovalStatus!, $type: String!) {
          updateApprovalStatus(id: $id, status: $status, type: $type) {
            id
            approvalStatus
          }
        }
      ''';

      final result = await _graphQLService.performMutation(
        mutation,
        variables: {
          'id': event.id,
          'status': 'APPROVED',
          'type': event.type,
        },
      );

      if (result.hasException) throw Exception(result.exception.toString());
      
      emit(state.copyWith(message: 'Request approved successfully'));
      add(LoadPendingRequests(locationId: state.requests.firstOrNull?.location?.id));
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
        mutation UpdateStatus($id: Int!, $status: ApprovalStatus!, $type: String!) {
          updateApprovalStatus(id: $id, status: $status, type: $type) {
            id
            approvalStatus
          }
        }
      ''';

      final result = await _graphQLService.performMutation(
        mutation,
        variables: {
          'id': event.id,
          'status': 'REJECTED',
          'type': event.type,
        },
      );

      if (result.hasException) throw Exception(result.exception.toString());
      
      emit(state.copyWith(message: 'Request rejected'));
      add(LoadPendingRequests(locationId: state.requests.firstOrNull?.location?.id));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}
