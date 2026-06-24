import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ntk_project/src/features/members/domain/repositories/member_repository.dart';
import 'package:ntk_project/src/features/members/data/models/member_model.dart';

// Events
abstract class EditProfileEvent extends Equatable {
  const EditProfileEvent();

  @override
  List<Object?> get props => [];
}

class SubmitEditProfile extends EditProfileEvent {
  final int id;
  final String name;
  final String? surname;
  final String phone;
  final String bloodGroup;
  final String professionName;
  final String? image;

  const SubmitEditProfile({
    required this.id,
    required this.name,
    this.surname,
    required this.phone,
    required this.bloodGroup,
    required this.professionName,
    this.image,
  });

  @override
  List<Object?> get props => [id, name, surname, phone, bloodGroup, professionName, image];
}

// States
abstract class EditProfileState extends Equatable {
  const EditProfileState();

  @override
  List<Object?> get props => [];
}

class EditProfileInitial extends EditProfileState {}

class EditProfileLoading extends EditProfileState {}

class EditProfileSuccess extends EditProfileState {
  final MemberModel updatedMember;

  const EditProfileSuccess(this.updatedMember);

  @override
  List<Object?> get props => [updatedMember];
}

class EditProfileFailure extends EditProfileState {
  final String errorMessage;

  const EditProfileFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}

// Bloc
class EditProfileBloc extends Bloc<EditProfileEvent, EditProfileState> {
  final MemberRepository _memberRepository;

  EditProfileBloc(this._memberRepository) : super(EditProfileInitial()) {
    on<SubmitEditProfile>(_onSubmitEditProfile);
  }

  Future<void> _onSubmitEditProfile(
    SubmitEditProfile event,
    Emitter<EditProfileState> emit,
  ) async {
    emit(EditProfileLoading());
    try {
      final member = await _memberRepository.updateMember(
        id: event.id,
        name: event.name,
        surname: event.surname,
        phone: event.phone,
        bloodGroup: event.bloodGroup,
        professionName: event.professionName,
        image: event.image,
      );
      emit(EditProfileSuccess(member));
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      emit(EditProfileFailure(msg));
    }
  }
}
