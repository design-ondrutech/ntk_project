import 'package:equatable/equatable.dart';
import '../../data/models/admin_login_model.dart';
export '../../data/models/admin_login_model.dart';

class AuthState extends Equatable {
  final bool isLoading;
  final String? error;
  final AdminLoginModel? loginData;
  final bool registrationSuccess;

  const AuthState({
    this.isLoading = false,
    this.error,
    this.loginData,
    this.registrationSuccess = false,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    AdminLoginModel? loginData,
    bool? registrationSuccess,
    bool clearRegistrationSuccess = false,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      loginData: loginData ?? this.loginData,
      registrationSuccess: clearRegistrationSuccess
          ? false
          : (registrationSuccess ?? this.registrationSuccess),
    );
  }

  @override
  List<Object?> get props => [isLoading, error, loginData, registrationSuccess];
}
