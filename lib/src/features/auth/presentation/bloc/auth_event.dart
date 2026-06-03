import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class LoginRequested extends AuthEvent {
  final String phone;
  final String password;

  const LoginRequested({required this.phone, required this.password});

  @override
  List<Object?> get props => [phone, password];
}

class RegisterRequested extends AuthEvent {
  final String name;
  final String? surname;
  final String phone;
  final String password;
  final int districtId;
  final int talukId;
  final int areaId;
  final int streetId;
  final String? bloodGroup;
  final String? professionName;

  const RegisterRequested({
    required this.name,
    this.surname,
    required this.phone,
    required this.password,
    required this.districtId,
    required this.talukId,
    required this.areaId,
    required this.streetId,
    this.bloodGroup,
    this.professionName,
  });

  @override
  List<Object?> get props => [
    name,
    surname,
    phone,
    password,
    districtId,
    talukId,
    areaId,
    streetId,
    bloodGroup,
    professionName,
  ];
}

class LogoutRequested extends AuthEvent {}

class LoadMeRequested extends AuthEvent {}
