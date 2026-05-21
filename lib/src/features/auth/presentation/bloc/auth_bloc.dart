import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc(this._authRepository) : super(const AuthState()) {
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null, clearRegistrationSuccess: true));
    try {
      await _authRepository.register(
        name: event.name,
        phone: event.phone,
        password: event.password,
        districtId: event.districtId,
        talukId: event.talukId,
        areaId: event.areaId,
        streetId: event.streetId,
        bloodGroup: event.bloodGroup,
        professionName: event.professionName,
      );
      emit(state.copyWith(isLoading: false, registrationSuccess: true));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final loginData = await _authRepository.login(
        phone: event.phone,
        password: event.password,
        role: event.role,
      );
      emit(state.copyWith(isLoading: false, loginData: loginData));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  void _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) {
    emit(const AuthState());
  }

}
