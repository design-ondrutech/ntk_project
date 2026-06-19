import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/features/community/domain/repositories/community_repository.dart';
import 'community_member_event.dart';
import 'community_member_state.dart';

class CommunityMemberBloc extends Bloc<CommunityMemberEvent, CommunityMemberState> {
  final CommunityRepository _repository;

  CommunityMemberBloc(this._repository) : super(const CommunityMemberState()) {
    on<FetchCommunityMembers>(_onFetchCommunityMembers);
  }

  Future<void> _onFetchCommunityMembers(
    FetchCommunityMembers event,
    Emitter<CommunityMemberState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final members = await _repository.getCommunityMembers(
        communityId: event.communityId,
      );
      emit(state.copyWith(isLoading: false, members: members));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }
}
