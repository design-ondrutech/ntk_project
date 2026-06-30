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
    on<ResetUserManagement>((event, emit) => emit(const UserManagementState()));
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
    // If it's load more and we already reached the max or are already loading, do nothing
    if (event.isLoadMore && (state.hasReachedMax || state.isLoadingMore)) {
      return;
    }

    final effectiveLocationId = event.streetId ?? event.locationId;
    const int pageSize = 10;

    if (event.isLoadMore) {
      emit(state.copyWith(isLoadingMore: true, error: null));
      try {
        List<MemberModel> newUsers = [];
        bool reachedMax = false;
        final currentOffset = state.users.length;

        String? apiRole;
        String? apiApprovalStatus = 'APPROVED';

        if (event.type == 'Admin') {
          apiRole = 'ADMIN';
        } else if (event.type == 'Sub Admin') {
          apiRole = 'SUB_ADMIN';
        } else if (event.type == 'District Incharge') {
          apiRole = 'DISTRICT_INCHARGE';
        } else if (event.type == 'Member') {
          apiRole = 'MEMBER';
        } else if (event.type == 'Pending') {
          apiApprovalStatus = 'PENDING';
        }

        newUsers = await _memberRepository.getMemberList(
          locationId: effectiveLocationId,
          approvalStatus: apiApprovalStatus,
          role: apiRole,
          bloodGroup: event.bloodGroup,
          professionName: event.profession,
          limit: pageSize,
          offset: currentOffset,
        );
        reachedMax = newUsers.length < pageSize;

        final uniqueUsersMap = <int, MemberModel>{};
        for (var u in [...state.users, ...newUsers]) {
          uniqueUsersMap[u.id] = u;
        }

        final uniqueUsersList = uniqueUsersMap.values.toList();
        uniqueUsersList.sort((a, b) {
          int getRoleWeight(String? role) {
            switch (role?.toUpperCase()) {
              case 'DISTRICT_INCHARGE':
                return 4;
              case 'ADMIN':
                return 3;
              case 'SUB_ADMIN':
                return 2;
              case 'MEMBER':
                return 1;
              default:
                return 0;
            }
          }
          return getRoleWeight(b.role).compareTo(getRoleWeight(a.role));
        });

        emit(state.copyWith(
          isLoadingMore: false,
          users: uniqueUsersList,
          hasReachedMax: reachedMax,
        ));
      } catch (e) {
        emit(state.copyWith(isLoadingMore: false, error: e.toString()));
      }
    } else {
      emit(
        state.copyWith(
          isLoading: true,
          selectedType: event.type,
          error: null,
          hasReachedMax: false,
          users: const [],
        ),
      );
      try {
        List<MemberModel> users = [];
        bool reachedMax = false;

        String? apiRole;
        String? apiApprovalStatus = 'APPROVED';

        if (event.type == 'Admin') {
          apiRole = 'ADMIN';
        } else if (event.type == 'Sub Admin') {
          apiRole = 'SUB_ADMIN';
        } else if (event.type == 'District Incharge') {
          apiRole = 'DISTRICT_INCHARGE';
        } else if (event.type == 'Member') {
          apiRole = 'MEMBER';
        } else if (event.type == 'Pending') {
          apiApprovalStatus = 'PENDING';
        }

        users = await _memberRepository.getMemberList(
          locationId: effectiveLocationId,
          approvalStatus: apiApprovalStatus,
          role: apiRole,
          bloodGroup: event.bloodGroup,
          professionName: event.profession,
          limit: pageSize,
          offset: 0,
        );
        reachedMax = users.length < pageSize;

        final uniqueUsersMap = <int, MemberModel>{};
        for (var u in users) {
          uniqueUsersMap[u.id] = u;
        }

        final uniqueUsersList = uniqueUsersMap.values.toList();
        uniqueUsersList.sort((a, b) {
          int getRoleWeight(String? role) {
            switch (role?.toUpperCase()) {
              case 'DISTRICT_INCHARGE':
                return 4;
              case 'ADMIN':
                return 3;
              case 'SUB_ADMIN':
                return 2;
              case 'MEMBER':
                return 1;
              default:
                return 0;
            }
          }
          return getRoleWeight(b.role).compareTo(getRoleWeight(a.role));
        });

        emit(state.copyWith(
          isLoading: false,
          users: uniqueUsersList,
          hasReachedMax: reachedMax,
        ));
      } catch (e) {
        emit(state.copyWith(isLoading: false, error: e.toString()));
      }
    }
  }
}
