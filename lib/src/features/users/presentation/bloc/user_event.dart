import 'package:equatable/equatable.dart';

abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object?> get props => [];
}

class CreateUserRequested extends UserEvent {
  final String name;
  final String phone;
  final String password;
  final String role;
  final int? districtId;
  final int? talukId;
  final int? areaId;
  final int? streetId;
  final String? bloodGroup;
  final String? professionName;

  const CreateUserRequested({
    required this.name,
    required this.phone,
    required this.password,
    required this.role,
    this.districtId,
    this.talukId,
    this.areaId,
    this.streetId,
    this.bloodGroup,
    this.professionName,
  });

  @override
  List<Object?> get props => [
    name,
    phone,
    password,
    role,
    districtId,
    talukId,
    areaId,
    streetId,
    bloodGroup,
    professionName,
  ];
}
class AddMemberRequested extends UserEvent {
  final String name;
  final String phone;
  final String? password;
  final int? streetId;
  final int? areaId;
  final String? bloodGroup;
  final String? professionName;

  const AddMemberRequested({
    required this.name,
    required this.phone,
    this.password,
    this.streetId,
    this.areaId,
    this.bloodGroup,
    this.professionName,
  });

  @override
  List<Object?> get props => [name, phone, password, streetId, areaId, bloodGroup, professionName];
}
