import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/admin_login_model.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import 'package:ntk_project/src/injection_container.dart';
import 'package:ntk_project/src/core/services/fcm_service.dart';

export 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc(
    this._authRepository, {
    AdminLoginModel? initialSession,
  }) : super(AuthState(loginData: initialSession)) {
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<LoadMeRequested>(_onLoadMeRequested);
  }

  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        isLoading: true,
        clearError: true,
        clearRegistrationSuccess: true,
      ),
    );
    try {
      await _authRepository.register(
        name: event.name,
        surname: event.surname,
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
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final loginData = await _authRepository.login(
        phone: event.phone,
        password: event.password,
      );
      // Debug print for loginData
      print(
        'DEBUG: loginData after login: role=${loginData.role}, name=${loginData.name}, id=${loginData.id}',
      );
      emit(state.copyWith(isLoading: false, loginData: loginData));
      sl<FCMService>().saveTokenToBackend();
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      emit(state.copyWith(isLoading: false, error: msg));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      await _authRepository.logout();
      emit(const AuthState());
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onLoadMeRequested(
    LoadMeRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final me = await _authRepository.getMe();
      final updatedModel = AdminLoginModel(
        id: me.id,
        name: me.name,
        surname: me.surname,
        phone: me.phone,
        role: me.role,
        approvalStatus: me.approvalStatus,
        locationId: me.locationId ?? state.loginData?.locationId,
        locationName: me.locationName ?? state.loginData?.locationName,
        isActive: me.isActive,
        addedBy: me.addedBy,
        image: me.image,
        token: state.loginData?.token,
      );
      await _authRepository.persistSession(updatedModel);
      emit(
        state.copyWith(
          isLoading: false,
          clearError: true,
          loginData: updatedModel,
        ),
      );
      sl<FCMService>().saveTokenToBackend();
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }
}
