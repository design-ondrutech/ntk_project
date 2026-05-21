import 'package:equatable/equatable.dart';
import 'package:ntk_project/src/features/members/data/models/member_model.dart';

class MemberState extends Equatable {
  final bool isLoading;
  final List<MemberModel> members;
  final String? error;

  const MemberState({
    this.isLoading = false,
    this.members = const [],
    this.error,
  });

  MemberState copyWith({
    bool? isLoading,
    List<MemberModel>? members,
    String? error,
  }) {
    return MemberState(
      isLoading: isLoading ?? this.isLoading,
      members: members ?? this.members,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [isLoading, members, error];
}
