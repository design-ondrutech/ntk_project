import 'package:equatable/equatable.dart';

abstract class MemberEvent extends Equatable {
  const MemberEvent();

  @override
  List<Object?> get props => [];
}

class ResetMembers extends MemberEvent {
  const ResetMembers();
}

class LoadMembers extends MemberEvent {
  final int? locationId;
  final String? search;
  final String? bloodGroup;
  final String? role;

  const LoadMembers({
    this.locationId,
    this.search,
    this.bloodGroup,
    this.role,
    this.isRefresh = true,
  });

  final bool isRefresh;

  @override
  List<Object?> get props => [locationId, search, bloodGroup, role, isRefresh];
}

class LoadMoreMembers extends MemberEvent {
  final int? locationId;
  final String? search;
  final String? bloodGroup;
  final String? role;

  const LoadMoreMembers({
    this.locationId,
    this.search,
    this.bloodGroup,
    this.role,
  });

  @override
  List<Object?> get props => [locationId, search, bloodGroup, role];
}

class LoadMemberDetails extends MemberEvent {
  final int id;

  const LoadMemberDetails({required this.id});

  @override
  List<Object?> get props => [id];
}

class UpdateMemberDetails extends MemberEvent {
  final int id;
  final String? name;
  final String? surname;
  final String? phone;
  final String? bloodGroup;
  final String? role;
  final String? professionName;
  final int? locationId;
  final String? dateOfBirth;
  final String? gender;
  final String? image;

  const UpdateMemberDetails({
    required this.id,
    this.name,
    this.surname,
    this.phone,
    this.bloodGroup,
    this.role,
    this.professionName,
    this.locationId,
    this.dateOfBirth,
    this.gender,
    this.image,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    surname,
    phone,
    bloodGroup,
    role,
    professionName,
    locationId,
    dateOfBirth,
    gender,
    image,
  ];
}
