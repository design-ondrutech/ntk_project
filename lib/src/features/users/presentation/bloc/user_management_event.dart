import 'package:equatable/equatable.dart';

abstract class UserManagementEvent extends Equatable {
  const UserManagementEvent();
  @override
  List<Object?> get props => [];
}

class ResetUserManagement extends UserManagementEvent {
  const ResetUserManagement();
}

class LoadUsers extends UserManagementEvent {
  final int? locationId;
  final String type; // 'All', 'Admin', 'Sub Admin', 'Member', 'Pending'
  final String? search;
  final String? bloodGroup;
  final String? profession;
  final int? streetId; // filter by street location id
  final bool isLoadMore;

  const LoadUsers({
    this.locationId,
    required this.type,
    this.search,
    this.bloodGroup,
    this.profession,
    this.streetId,
    this.isLoadMore = false,
  });

  @override
  List<Object?> get props => [
    locationId,
    type,
    search,
    bloodGroup,
    profession,
    streetId,
    isLoadMore,
  ];
}

class LoadStreets extends UserManagementEvent {
  final int parentId; // sub admin's locationId
  const LoadStreets({required this.parentId});
  @override
  List<Object?> get props => [parentId];
}
