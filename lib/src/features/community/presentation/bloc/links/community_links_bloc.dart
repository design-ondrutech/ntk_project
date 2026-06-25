import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/features/community/domain/repositories/community_repository.dart';
import 'community_links_event.dart';
import 'community_links_state.dart';

class CommunityLinksBloc extends Bloc<CommunityLinksEvent, CommunityLinksState> {
  final CommunityRepository _repository;

  CommunityLinksBloc(this._repository) : super(const CommunityLinksState()) {
    on<FetchCommunityLinksEvent>(_onFetchCommunityLinks);
    on<UploadCommunityLinkEvent>(_onUploadCommunityLink);
    on<DeleteCommunityLinkEvent>(_onDeleteCommunityLink);
  }

  Future<void> _onFetchCommunityLinks(
    FetchCommunityLinksEvent event,
    Emitter<CommunityLinksState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final links = await _repository.getCommunityLinksAndDocs(communityId: event.communityId);
      emit(state.copyWith(isLoading: false, links: links));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: 'Failed to fetch links: $e'));
    }
  }

  Future<void> _onUploadCommunityLink(
    UploadCommunityLinkEvent event,
    Emitter<CommunityLinksState> emit,
  ) async {
    emit(state.copyWith(isUploading: true, clearError: true, clearSuccess: true));
    try {
      final newLink = await _repository.uploadCommunityLinkOrDoc(
        communityId: event.communityId,
        title: event.title,
        url: event.url,
        type: event.type,
      );
      emit(state.copyWith(
        isUploading: false,
        links: [newLink, ...state.links],
        successMessage: 'Link added successfully',
      ));
    } catch (e) {
      emit(state.copyWith(isUploading: false, error: 'Failed to upload link: $e'));
    }
  }

  Future<void> _onDeleteCommunityLink(
    DeleteCommunityLinkEvent event,
    Emitter<CommunityLinksState> emit,
  ) async {
    emit(state.copyWith(clearError: true, clearSuccess: true));
    try {
      await _repository.deleteCommunityLinkOrDoc(linkOrDocId: event.linkId);
      final updatedLinks = state.links.where((l) => l.id != event.linkId).toList();
      emit(state.copyWith(
        links: updatedLinks,
        successMessage: 'Link deleted successfully',
      ));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to delete link: $e'));
    }
  }
}
