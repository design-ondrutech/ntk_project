import 'package:equatable/equatable.dart';
import 'package:ntk_project/src/features/community/data/models/community_media_model.dart';

class CommunityLinksState extends Equatable {
  final bool isLoading;
  final List<CommunityMediaModel> media;
  final String? error;

  const CommunityLinksState({
    this.isLoading = false,
    this.media = const [],
    this.error,
  });

  CommunityLinksState copyWith({
    bool? isLoading,
    List<CommunityMediaModel>? media,
    String? error,
    bool clearError = false,
  }) {
    return CommunityLinksState(
      isLoading: isLoading ?? this.isLoading,
      media: media ?? this.media,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [isLoading, media, error];
}
