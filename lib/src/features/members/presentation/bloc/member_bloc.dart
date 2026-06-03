import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/features/members/domain/repositories/member_repository.dart';
import 'package:ntk_project/src/features/members/presentation/bloc/member_event.dart';
import 'package:ntk_project/src/features/members/presentation/bloc/member_state.dart';

class MemberBloc extends Bloc<MemberEvent, MemberState> {
  final MemberRepository _memberRepository;

  MemberBloc(this._memberRepository) : super(const MemberState()) {
    on<LoadMembers>(_onLoadMembers);
    on<LoadMemberDetails>(_onLoadMemberDetails);
    on<UpdateMemberDetails>(_onUpdateMemberDetails);
  }

  Future<void> _onLoadMembers(
    LoadMembers event,
    Emitter<MemberState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final members = await _memberRepository.getMembers(
        locationId: event.locationId,
        search: event.search,
        bloodGroup: event.bloodGroup,
        role: event.role ?? 'MEMBER',
      );
      emit(state.copyWith(isLoading: false, members: members));
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
      );
      emit(state.copyWith(isLoadingDetails: false, selectedMember: member));
    } catch (e) {
      emit(state.copyWith(isLoadingDetails: false, detailsError: e.toString()));
    }
  }
}
