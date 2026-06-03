import 'package:equatable/equatable.dart';
import 'package:ntk_project/src/features/members/data/models/member_model.dart';
import 'package:ntk_project/src/features/location/data/models/location_model.dart';

class UserManagementState extends Equatable {
  final bool isLoading;
  final List<MemberModel> users;
  final String? error;
  final String selectedType;
  final List<LocationModel> streets;
  final bool isLoadingStreets;
  final bool hasReachedMax;
  final bool isLoadingMore;

  const UserManagementState({
    this.isLoading = false,
    this.users = const [],
    this.error,
    this.selectedType = 'Member',
    this.streets = const [],
    this.isLoadingStreets = false,
    this.hasReachedMax = false,
    this.isLoadingMore = false,
  });

  UserManagementState copyWith({
    bool? isLoading,
    List<MemberModel>? users,
    String? error,
    String? selectedType,
    List<LocationModel>? streets,
    bool? isLoadingStreets,
    bool? hasReachedMax,
    bool? isLoadingMore,
  }) {
    return UserManagementState(
      isLoading: isLoading ?? this.isLoading,
      users: users ?? this.users,
      error: error ?? this.error,
      selectedType: selectedType ?? this.selectedType,
      streets: streets ?? this.streets,
      isLoadingStreets: isLoadingStreets ?? this.isLoadingStreets,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    users,
    error,
    selectedType,
    streets,
    isLoadingStreets,
    hasReachedMax,
    isLoadingMore,
  ];
}
