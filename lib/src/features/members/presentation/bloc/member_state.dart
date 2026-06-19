import 'package:equatable/equatable.dart';
import 'package:ntk_project/src/features/members/data/models/member_model.dart';

class MemberState extends Equatable {
  final bool isLoading;
  final List<MemberModel> members;
  final String? error;
  final bool isLoadingDetails;
  final MemberModel? selectedMember;
  final String? detailsError;
  final int offset;
  final int limit;
  final bool hasReachedMax;

  const MemberState({
    this.isLoading = false,
    this.members = const [],
    this.error,
    this.isLoadingDetails = false,
    this.selectedMember,
    this.detailsError,
    this.offset = 0,
    this.limit = 20,
    this.hasReachedMax = false,
  });

  MemberState copyWith({
    bool? isLoading,
    List<MemberModel>? members,
    String? error,
    bool? isLoadingDetails,
    MemberModel? selectedMember,
    String? detailsError,
    int? offset,
    int? limit,
    bool? hasReachedMax,
  }) {
    return MemberState(
      isLoading: isLoading ?? this.isLoading,
      members: members ?? this.members,
      error: error ?? this.error,
      isLoadingDetails: isLoadingDetails ?? this.isLoadingDetails,
      selectedMember: selectedMember ?? this.selectedMember,
      detailsError: detailsError ?? this.detailsError,
      offset: offset ?? this.offset,
      limit: limit ?? this.limit,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
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
        offset,
        limit,
        hasReachedMax,
      ];
}
