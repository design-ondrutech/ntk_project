import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/features/community/domain/repositories/community_repository.dart';
import 'package:ntk_project/src/features/community/data/models/poll_model.dart';
import 'community_polls_event.dart';
import 'community_polls_state.dart';

class CommunityPollsBloc
    extends Bloc<CommunityPollsEvent, CommunityPollsState> {
  final CommunityRepository _repository;

  CommunityPollsBloc(this._repository) : super(const CommunityPollsState()) {
    on<FetchPollsEvent>(_onFetchPolls);
    on<CreatePollEvent>(_onCreatePoll);
    on<VoteInPollEvent>(_onVoteInPoll);
    on<ClearPollsMessage>(
      (event, emit) => emit(state.copyWith(clearSuccess: true)),
    );
    on<ClearPollsError>(
      (event, emit) => emit(state.copyWith(clearError: true)),
    );
  }

  Future<void> _onFetchPolls(
    FetchPollsEvent event,
    Emitter<CommunityPollsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final polls = await _repository.getPollList(
        communityId: event.communityId,
        locationId: event.locationId,
      );
      emit(state.copyWith(isLoading: false, polls: polls));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onCreatePoll(
    CreatePollEvent event,
    Emitter<CommunityPollsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final newPoll = await _repository.createPoll(
        question: event.question,
        options: event.options,
        durationDays: event.durationDays,
        locationId: event.locationId,
        communityId: event.communityId,
      );

      emit(
        state.copyWith(
          isLoading: false,
          polls: [newPoll, ...state.polls],
          successMessage: 'Poll created successfully',
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: 'Failed to create poll: $e',
          clearSuccess: true,
        ),
      );
    }
  }

  Future<void> _onVoteInPoll(
    VoteInPollEvent event,
    Emitter<CommunityPollsState> emit,
  ) async {
    emit(state.copyWith(isVoting: true, clearError: true));
    try {
      await _repository.voteInPoll(
        pollId: event.pollId,
        optionId: event.optionId,
      );

      final updatedPollsList = state.polls.map((p) {
        if (p.id == event.pollId) {
          final updatedOptions = p.options.map((o) {
            if (o.id == event.optionId) {
              return PollOptionModel(
                id: o.id,
                pollId: o.pollId,
                text: o.text,
                votesCount: o.votesCount + 1,
              );
            }
            return o;
          }).toList();
          return PollModel(
            id: p.id,
            question: p.question,
            locationId: p.locationId,
            location: p.location,
            communityId: p.communityId,
            expiresAt: p.expiresAt,
            createdAt: p.createdAt,
            options: updatedOptions,
            votesCount: p.votesCount + 1,
            userVoteOptionId: event.optionId,
            createdBy: p.createdBy,
            member: p.member,
          );
        }
        return p;
      }).toList();

      emit(
        state.copyWith(
          isVoting: false,
          polls: updatedPollsList,
          successMessage: 'Vote cast successfully',
          clearError: true,
        ),
      );
    } catch (e) {
      final cleanMessage = e.toString().replaceAll('Exception: ', '');
      emit(
        state.copyWith(
          isVoting: false,
          error: cleanMessage,
          clearSuccess: true,
        ),
      );
    }
  }
}
