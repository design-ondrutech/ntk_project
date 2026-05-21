import 'package:equatable/equatable.dart';
import 'package:ntk_project/src/features/members/data/models/member_model.dart';

class MemberState extends Equatable {
  final bool isLoading;
  final List<MemberModel> members;
  final String? error;
  final bool isLoadingDetails;
  final MemberModel? selectedMember;
  final String? detailsError;

  const MemberState({
    this.isLoading = false,
    this.members = const [],
    this.error,
    this.isLoadingDetails = false,
    this.selectedMember,
    this.detailsError,
  });

  MemberState copyWith({
    bool? isLoading,
    List<MemberModel>? members,
    String? error,
    bool? isLoadingDetails,
    MemberModel? selectedMember,
    String? detailsError,
  }) {
    return MemberState(
      isLoading: isLoading ?? this.isLoading,
      members: members ?? this.members,
      error: error ?? this.error,
      isLoadingDetails: isLoadingDetails ?? this.isLoadingDetails,
      selectedMember: selectedMember ?? this.selectedMember,
      detailsError: detailsError ?? this.detailsError,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        members,
        error,
        isLoadingDetails,
        selectedMember,
        detailsError,
      ];
}
