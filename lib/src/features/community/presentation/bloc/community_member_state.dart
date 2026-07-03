import 'package:equatable/equatable.dart';
import 'package:ntk_project/src/features/community/data/models/community_member_model.dart';

class CommunityMemberState extends Equatable {
  final bool isLoading;
  final bool isBanning;
  final List<CommunityMemberModel> members;
  final String? error;
  final String? successMessage;

  const CommunityMemberState({
    this.isLoading = false,
    this.isBanning = false,
    this.members = const [],
    this.error,
    this.successMessage,
  });

  CommunityMemberState copyWith({
    bool? isLoading,
    bool? isBanning,
    List<CommunityMemberModel>? members,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return CommunityMemberState(
      isLoading: isLoading ?? this.isLoading,
      isBanning: isBanning ?? this.isBanning,
      members: members ?? this.members,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [isLoading, isBanning, members, error, successMessage];
}
