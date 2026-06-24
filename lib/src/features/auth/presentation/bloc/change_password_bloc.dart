import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/features/members/domain/repositories/member_repository.dart';

// ─── Events ───────────────────────────────────────────────────────────────────

abstract class ChangePasswordEvent extends Equatable {
  const ChangePasswordEvent();

  @override
  List<Object?> get props => [];
}

class SubmitChangePassword extends ChangePasswordEvent {
  final int id;
  final String newPassword;

  const SubmitChangePassword({
    required this.id,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [id]; // intentionally exclude newPassword from props for security
}

// ─── States ───────────────────────────────────────────────────────────────────

abstract class ChangePasswordState extends Equatable {
  const ChangePasswordState();

  @override
  List<Object?> get props => [];
}

class ChangePasswordInitial extends ChangePasswordState {
  const ChangePasswordInitial();
}

class ChangePasswordLoading extends ChangePasswordState {
  const ChangePasswordLoading();
}

class ChangePasswordSuccess extends ChangePasswordState {
  const ChangePasswordSuccess();
}

class ChangePasswordFailure extends ChangePasswordState {
  final String errorMessage;

  const ChangePasswordFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}

// ─── Bloc ─────────────────────────────────────────────────────────────────────

class ChangePasswordBloc
    extends Bloc<ChangePasswordEvent, ChangePasswordState> {
  final MemberRepository _memberRepository;

  ChangePasswordBloc(this._memberRepository)
      : super(const ChangePasswordInitial()) {
    on<SubmitChangePassword>(_onSubmitChangePassword);
  }

  Future<void> _onSubmitChangePassword(
    SubmitChangePassword event,
    Emitter<ChangePasswordState> emit,
  ) async {
    emit(const ChangePasswordLoading());
    try {
      await _memberRepository.changePassword(
        id: event.id,
        password: event.newPassword,
      );
      emit(const ChangePasswordSuccess());
    } catch (e) {
      final raw = e.toString().replaceFirst('Exception: ', '');
      // Parse common GraphQL error patterns into user-friendly messages
      final msg = _parseError(raw);
      emit(ChangePasswordFailure(msg));
    }
  }

  String _parseError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('network') || lower.contains('socket') || lower.contains('connection')) {
      return 'Network error. Please check your connection.';
    }
    if (lower.contains('invalid') && lower.contains('password')) {
      return 'Current password is incorrect.';
    }
    if (lower.contains('weak') || lower.contains('too short')) {
      return 'New password is too weak.';
    }
    if (lower.contains('unauthorized') || lower.contains('unauthenticated')) {
      return 'Session expired. Please log in again.';
    }
    return raw.isNotEmpty ? raw : 'Failed to update password. Please try again.';
  }
}
