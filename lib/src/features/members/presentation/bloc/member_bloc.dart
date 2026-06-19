import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/features/members/domain/repositories/member_repository.dart';
import 'package:ntk_project/src/features/members/presentation/bloc/member_event.dart';
import 'package:ntk_project/src/features/members/presentation/bloc/member_state.dart';

class MemberBloc extends Bloc<MemberEvent, MemberState> {
  final MemberRepository _memberRepository;

  MemberBloc(this._memberRepository) : super(const MemberState()) {
    on<LoadMembers>(_onLoadMembers);
    on<LoadMoreMembers>(_onLoadMoreMembers);
    on<LoadMemberDetails>(_onLoadMemberDetails);
    on<UpdateMemberDetails>(_onUpdateMemberDetails);
    on<ResetMembers>((event, emit) => emit(const MemberState()));
  }

  Future<void> _onLoadMembers(
    LoadMembers event,
    Emitter<MemberState> emit,
  ) async {
    if (!event.isRefresh && state.hasReachedMax) return;

    if (event.isRefresh) {
      emit(state.copyWith(isLoading: true, error: null, offset: 0, hasReachedMax: false, members: []));
    } else {
      emit(state.copyWith(isLoading: true, error: null));
    }

    try {
      final members = await _memberRepository.getMembers(
        locationId: event.locationId,
        search: event.search,
        bloodGroup: event.bloodGroup,
        role: event.role ?? 'MEMBER',
        limit: state.limit,
        offset: state.offset,
      );

      final hasReachedMax = members.length < state.limit;
      final newMembers = event.isRefresh ? members : [...state.members, ...members];

      emit(state.copyWith(
        isLoading: false, 
        members: newMembers,
        hasReachedMax: hasReachedMax,
        offset: state.offset + state.limit,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onLoadMoreMembers(
    LoadMoreMembers event,
    Emitter<MemberState> emit,
  ) async {
    if (state.hasReachedMax || state.isLoading) return;

    try {
      emit(state.copyWith(isLoading: true, error: null));
      final members = await _memberRepository.getMembers(
        locationId: event.locationId,
        search: event.search,
        bloodGroup: event.bloodGroup,
        role: event.role ?? 'MEMBER',
        limit: state.limit,
        offset: state.offset,
      );

      final hasReachedMax = members.length < state.limit;

      emit(state.copyWith(
        isLoading: false,
        members: [...state.members, ...members],
        hasReachedMax: hasReachedMax,
        offset: state.offset + state.limit,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onLoadMemberDetails(
    LoadMemberDetails event,
    Emitter<MemberState> emit,
  ) async {
    emit(state.copyWith(isLoadingDetails: true, detailsError: null));
    try {
      final member = await _memberRepository.getMemberDetails(id: event.id);
      emit(state.copyWith(isLoadingDetails: false, selectedMember: member));
    } catch (e) {
      emit(state.copyWith(isLoadingDetails: false, detailsError: e.toString()));
    }
  }

  Future<void> _onUpdateMemberDetails(
    UpdateMemberDetails event,
    Emitter<MemberState> emit,
  ) async {
    emit(state.copyWith(isLoadingDetails: true, detailsError: null));
    try {
      final member = await _memberRepository.updateMember(
        id: event.id,
        name: event.name,
        surname: event.surname,
        phone: event.phone,
        bloodGroup: event.bloodGroup,
        role: event.role,
        professionName: event.professionName,
        locationId: event.locationId,
        dateOfBirth: event.dateOfBirth,
        gender: event.gender,
        image: event.image,
      );
      emit(state.copyWith(isLoadingDetails: false, selectedMember: member));
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      emit(state.copyWith(isLoadingDetails: false, detailsError: msg));
    }
  }
}
