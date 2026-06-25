import 'package:equatable/equatable.dart';

abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object?> get props => [];
}

class CreateUserRequested extends UserEvent {
  final String name;
  final String? surname;
  final String phone;
  final String password;
  final String role;
  final int? locationId;
  final int? districtId;
  final int? talukId;
  final int? areaId;
  final int? streetId;
  final String? bloodGroup;
  final String? professionName;
  final String? dateOfBirth;
  final String? gender;
  final List<int>? additionalLocationIds;

  const CreateUserRequested({
    required this.name,
    this.surname,
    required this.phone,
    required this.password,
    required this.role,
    this.locationId,
    this.districtId,
    this.talukId,
    this.areaId,
    this.streetId,
    this.bloodGroup,
    this.professionName,
    this.dateOfBirth,
    this.gender,
    this.additionalLocationIds,
  });

  @override
  List<Object?> get props => [
    name,
    surname,
    phone,
    password,
    role,
    locationId,
    districtId,
    talukId,
    areaId,
    streetId,
    bloodGroup,
    professionName,
    dateOfBirth,
    gender,
    additionalLocationIds,
  ];
}

class AddMemberRequested extends UserEvent {
  final String name;
  final String? surname;
  final String phone;
  final String? password;
  final int? streetId;
  final int? areaId;
  final String? bloodGroup;
  final String? professionName;
  final String? dateOfBirth;
  final String? gender;

  const AddMemberRequested({
    required this.name,
    this.surname,
    required this.phone,
    this.password,
    this.streetId,
    this.areaId,
    this.bloodGroup,
    this.professionName,
    this.dateOfBirth,
    this.gender,
  });

  @override
  List<Object?> get props => [
    name,
    surname,
    phone,
    password,
    streetId,
    areaId,
    bloodGroup,
    professionName,
    dateOfBirth,
    gender,
  ];
}
