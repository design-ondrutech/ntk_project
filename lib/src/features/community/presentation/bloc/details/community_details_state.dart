import 'package:equatable/equatable.dart';
import 'package:ntk_project/src/features/community/data/models/community_model.dart';

class CommunityDetailsState extends Equatable {
  final bool isLoading;
  final CommunityModel? community;
  final String? error;

  const CommunityDetailsState({
    this.isLoading = false,
    this.community,
    this.error,
  });

  CommunityDetailsState copyWith({
    bool? isLoading,
    CommunityModel? community,
    String? error,
    bool clearError = false,
  }) {
    return CommunityDetailsState(
      isLoading: isLoading ?? this.isLoading,
      community: community ?? this.community,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [isLoading, community, error];
}
