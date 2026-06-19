import 'package:equatable/equatable.dart';
import 'package:ntk_project/src/features/community/data/models/community_member_model.dart';

class CommunityMemberState extends Equatable {
  final bool isLoading;
  final List<CommunityMemberModel> members;
  final String? error;

  const CommunityMemberState({
    this.isLoading = false,
    this.members = const [],
    this.error,
  });

  CommunityMemberState copyWith({
    bool? isLoading,
    List<CommunityMemberModel>? members,
    String? error,
    bool clearError = false,
  }) {
    return CommunityMemberState(
      isLoading: isLoading ?? this.isLoading,
      members: members ?? this.members,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [isLoading, members, error];
}
