import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/features/members/domain/repositories/member_repository.dart';
import 'package:ntk_project/src/features/members/presentation/bloc/member_event.dart';
import 'package:ntk_project/src/features/members/presentation/bloc/member_state.dart';

class MemberBloc extends Bloc<MemberEvent, MemberState> {
  final MemberRepository _memberRepository;

  MemberBloc(this._memberRepository) : super(const MemberState()) {
    on<LoadMembers>(_onLoadMembers);
    on<LoadMemberDetails>(_onLoadMemberDetails);
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
}
