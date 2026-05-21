import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/features/members/domain/repositories/member_repository.dart';
import 'package:ntk_project/src/features/members/data/models/member_model.dart';
import 'package:ntk_project/src/features/location/domain/repositories/location_repository.dart';
import 'user_management_event.dart';
import 'user_management_state.dart';

class UserManagementBloc
    extends Bloc<UserManagementEvent, UserManagementState> {
  final MemberRepository _memberRepository;
  final LocationRepository _locationRepository;

  UserManagementBloc(this._memberRepository, this._locationRepository)
    : super(const UserManagementState()) {
    on<LoadUsers>(_onLoadUsers);
    on<LoadStreets>(_onLoadStreets);
  }

  Future<void> _onLoadStreets(
    LoadStreets event,
    Emitter<UserManagementState> emit,
  ) async {
    emit(state.copyWith(isLoadingStreets: true));
    try {
      final streets = await _locationRepository.getLocationList(
        parentId: event.parentId,
        type: 'STREET',
      );
      emit(state.copyWith(isLoadingStreets: false, streets: streets));
    } catch (e) {
      emit(state.copyWith(isLoadingStreets: false));
    }
  }

  Future<void> _onLoadUsers(
    LoadUsers event,
    Emitter<UserManagementState> emit,
  ) async {
    emit(
      state.copyWith(isLoading: true, selectedType: event.type, error: null),
    );
    try {
      List<MemberModel> users = [];

      // Use streetId as locationId filter if provided
      final effectiveLocationId = event.streetId ?? event.locationId;

      switch (event.type) {
        case 'Admin':
          users = await _memberRepository.getUserList(
            locationId: event.locationId,
            role: 'ADMIN',
          );
          break;
        case 'Sub Admin':
          users = await _memberRepository.getUserList(
            locationId: event.locationId,
            role: 'SUB_ADMIN',
          );
          break;
        case 'Member':
          users = await _memberRepository.getMemberList(
            locationId: effectiveLocationId,
            approvalStatus: 'APPROVED',
          );
          break;
        case 'Pending':
          users = await _memberRepository.getMemberList(
            locationId: effectiveLocationId,
            approvalStatus: 'PENDING',
          );
          break;
        case 'All':
          final admins = await _memberRepository.getUserList(
            locationId: event.locationId,
            role: 'ADMIN',
          );
          final subAdmins = await _memberRepository.getUserList(
            locationId: event.locationId,
            role: 'SUB_ADMIN',
          );
          final members = await _memberRepository.getMemberList(
            locationId: effectiveLocationId,
            approvalStatus: 'APPROVED',
          );
          users = [...admins, ...subAdmins, ...members];
          break;
      }

      emit(state.copyWith(isLoading: false, users: users));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }
}
