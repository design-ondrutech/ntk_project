import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/features/community/domain/repositories/community_repository.dart';
import 'community_list_event.dart';
import 'community_list_state.dart';

class CommunityListBloc extends Bloc<CommunityListEvent, CommunityListState> {
  final CommunityRepository _repository;

  CommunityListBloc(this._repository) : super(const CommunityListState()) {
    on<FetchCommunitiesList>(_onFetchCommunities);
    on<CreateNewCommunity>(_onCreateNewCommunity);
  }

  Future<void> _onFetchCommunities(
    FetchCommunitiesList event,
    Emitter<CommunityListState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final communities = await _repository.getCommunities();
      emit(state.copyWith(isLoading: false, communities: communities));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onCreateNewCommunity(
    CreateNewCommunity event,
    Emitter<CommunityListState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final newCommunity = await _repository.createCommunity(
        name: event.name,
        description: event.description,
        image: event.image,
        allowMemberMessages: event.allowMemberMessages,
      );

      emit(
        state.copyWith(
          isLoading: false,
          communities: [newCommunity, ...state.communities],
          successMessage: 'Community created successfully',
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: 'Community creation failed: $e',
          clearSuccess: true,
        ),
      );
    }
  }
}
