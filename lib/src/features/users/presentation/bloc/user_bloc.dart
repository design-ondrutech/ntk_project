import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/features/users/domain/repositories/user_repository.dart';
import 'package:ntk_project/src/features/members/domain/repositories/member_repository.dart';
import 'package:ntk_project/src/features/users/presentation/bloc/user_event.dart';
import 'package:ntk_project/src/features/users/presentation/bloc/user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final UserRepository _userRepository;
  final MemberRepository _memberRepository;

  UserBloc(this._userRepository, this._memberRepository)
    : super(UserInitial()) {
    on<CreateUserRequested>(_onCreateUserRequested);
    on<AddMemberRequested>(_onAddMemberRequested);
  }

  Future<void> _onCreateUserRequested(
    CreateUserRequested event,
    Emitter<UserState> emit,
  ) async {
    emit(UserLoading());
    try {
      final user = await _userRepository.createUser(
        name: event.name,
        surname: event.surname,
        phone: event.phone,
        password: event.password,
        role: event.role,
        locationId:
            event.locationId ?? event.streetId ?? event.areaId ?? event.talukId,
        dateOfBirth: event.dateOfBirth,
        gender: event.gender,
        bloodGroup: event.bloodGroup,
        professionName: event.professionName,
      );
      
      final userId = user['id'];
      if (userId != null && event.additionalLocationIds != null && event.additionalLocationIds!.isNotEmpty) {
        try {
          final int parsedUserId = userId is int ? userId : int.parse(userId.toString());
          await _userRepository.assignUserLocations(
            userId: parsedUserId,
            locationIds: event.additionalLocationIds!,
            isPrimary: 0,
          );
        } catch (e) {
          debugPrint('Failed to assign secondary locations: $e');
          throw Exception('User created, but failed to assign secondary locations: $e');
        }
      }

      emit(UserCreatedSuccess(user));
    } catch (e) {
      emit(UserFailure(e.toString()));
    }
  }

  Future<void> _onAddMemberRequested(
    AddMemberRequested event,
    Emitter<UserState> emit,
  ) async {
    emit(UserLoading());
    try {
      final member = await _memberRepository.addMember(
        name: event.name,
        surname: event.surname,
        phone: event.phone,
        password: event.password,
        streetId: event.streetId,
        areaId: event.areaId,
        bloodGroup: event.bloodGroup,
        professionName: event.professionName,
        dateOfBirth: event.dateOfBirth,
        gender: event.gender,
      );
      emit(UserCreatedSuccess(member.toJson()));
    } catch (e) {
      emit(UserFailure(e.toString()));
    }
  }
}
