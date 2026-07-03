import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/features/community/domain/repositories/community_repository.dart';
import 'community_links_event.dart';
import 'community_links_state.dart';

class CommunityLinksBloc extends Bloc<CommunityLinksEvent, CommunityLinksState> {
  final CommunityRepository _repository;

  CommunityLinksBloc(this._repository) : super(const CommunityLinksState()) {
    on<FetchCommunityMediaGalleryEvent>(_onFetchCommunityMediaGallery);
  }

  Future<void> _onFetchCommunityMediaGallery(
    FetchCommunityMediaGalleryEvent event,
    Emitter<CommunityLinksState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final media = await _repository.getCommunityMediaGallery(
        communityId: event.communityId,
        mediaType: event.mediaType,
      );
      emit(state.copyWith(isLoading: false, media: media));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: 'Failed to fetch media gallery: $e'));
    }
  }
}
