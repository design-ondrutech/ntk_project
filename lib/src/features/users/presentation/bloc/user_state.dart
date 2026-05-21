import 'package:equatable/equatable.dart';

abstract class UserState extends Equatable {
  const UserState();

  @override
  List<Object?> get props => [];
}

class UserInitial extends UserState {}

class UserLoading extends UserState {}

class UserCreatedSuccess extends UserState {
  final Map<String, dynamic> user;
  const UserCreatedSuccess(this.user);

  @override
  List<Object?> get props => [user];
}

class UserFailure extends UserState {
  final String error;
  const UserFailure(this.error);

  @override
  List<Object?> get props => [error];
}
