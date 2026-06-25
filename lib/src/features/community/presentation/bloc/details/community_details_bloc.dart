import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/features/community/domain/repositories/community_repository.dart';
import 'community_details_event.dart';
import 'community_details_state.dart';

class CommunityDetailsBloc extends Bloc<CommunityDetailsEvent, CommunityDetailsState> {
  final CommunityRepository _repository;

  CommunityDetailsBloc(this._repository) : super(const CommunityDetailsState()) {
    on<FetchCommunityDetailsEvent>(_onFetchCommunityDetails);
  }

  Future<void> _onFetchCommunityDetails(
    FetchCommunityDetailsEvent event,
    Emitter<CommunityDetailsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final community = await _repository.getCommunityDetails(communityId: event.communityId);
      emit(state.copyWith(isLoading: false, community: community));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: 'Failed to fetch details: $e'));
    }
  }
}
