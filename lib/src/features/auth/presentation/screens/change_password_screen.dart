import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/core/theme/app_theme.dart';
import 'package:ntk_project/src/core/widgets/ntk_snackbar.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/change_password_bloc.dart';
import 'package:ntk_project/src/injection_container.dart' as di;

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _currentPasswordVisible = false;
  bool _newPasswordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _clearFields() {
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
  }

  void _onSubmit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    final loginData = context.read<AuthBloc>().state.loginData;
    if (loginData == null) {
      NTKSnackbar.showError(context, message: 'Session expired. Please log in again.');
      return;
    }

    context.read<ChangePasswordBloc>().add(
          SubmitChangePassword(
            id: loginData.id,
            newPassword: _newPasswordController.text,
          ),
        );
  }

  // ─── Validators ────────────────────────────────────────────────────────────

  String? _validateCurrentPassword(String? val) {
    if (val == null || val.isEmpty) {
      return 'Please enter current password';
    }
    return null;
  }

  String? _validateNewPassword(String? val) {
    if (val == null || val.isEmpty) {
      return 'Please enter new password';
    }
    if (val.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? val) {
    if (val == null || val.isEmpty) {
      return 'Please confirm your password';
    }
    if (val != _newPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  // ─── UI Helpers ────────────────────────────────────────────────────────────

  Widget _buildPasswordField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
    required String? Function(String?) validator,
    required IconData prefixIcon,
    bool isLoading = false,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 13,
            color: NTKColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: !isVisible,
          enabled: !isLoading,
          textInputAction: textInputAction,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(prefixIcon),
            suffixIcon: IconButton(
              icon: Icon(
                isVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: NTKColors.textSecondary,
                size: 20,
              ),
              onPressed: isLoading ? null : onToggleVisibility,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  // ─── Password strength indicator ───────────────────────────────────────────

  Widget _buildStrengthIndicator() {
    final val = _newPasswordController.text;
    int score = 0;
    if (val.length >= 6) score++;
    if (val.contains(RegExp(r'[A-Z]'))) score++;
    if (val.contains(RegExp(r'[a-z]'))) score++;
    if (val.contains(RegExp(r'[0-9]'))) score++;
    if (val.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) score++;

    if (val.isEmpty) return const SizedBox.shrink();

    Color barColor;
    String label;
    if (val.length < 6) {
      barColor = const Color(0xFFDC2626);
      label = 'Too short';
    } else if (score <= 2) {
      barColor = const Color(0xFFDC2626);
      label = 'Weak';
    } else if (score == 3) {
      barColor = const Color(0xFFF59E0B);
      label = 'Fair';
    } else if (score == 4) {
      barColor = const Color(0xFF2563EB);
      label = 'Good';
    } else {
      barColor = NTKColors.primary;
      label = 'Strong';
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ...List.generate(5, (i) {
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 4),
                    height: 4,
                    decoration: BoxDecoration(
                      color: i < score ? barColor : NTKColors.slate100,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Password strength: $label',
            style: TextStyle(fontSize: 11, color: barColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ChangePasswordBloc>(
      create: (_) => di.sl<ChangePasswordBloc>(),
      child: Scaffold(
        backgroundColor: NTKColors.background,
        appBar: AppBar(
          title: const Text('Change Password'),
          backgroundColor: NTKColors.primary,
          foregroundColor: Colors.white,
        ),
        body: BlocConsumer<ChangePasswordBloc, ChangePasswordState>(
          listener: (context, state) {
            if (state is ChangePasswordSuccess) {
              _clearFields();
              NTKSnackbar.showSuccess(
                context,
                message: 'Password updated successfully',
              );
              Navigator.pop(context);
            } else if (state is ChangePasswordFailure) {
              NTKSnackbar.showError(context, message: state.errorMessage);
            }
          },
          builder: (context, state) {
            final isLoading = state is ChangePasswordLoading;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Security illustration header ──────────────────────
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.lock_reset_rounded,
                          size: 40,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Center(
                      child: Text(
                        'Update your password',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: NTKColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Center(
                      child: Text(
                        'Choose a strong password that you don\'t use elsewhere.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: NTKColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Password fields card ──────────────────────────────
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Current Password
                            _buildPasswordField(
                              label: 'Current Password *',
                              hint: 'Enter current password',
                              controller: _currentPasswordController,
                              isVisible: _currentPasswordVisible,
                              isLoading: isLoading,
                              onToggleVisibility: () => setState(
                                () => _currentPasswordVisible = !_currentPasswordVisible,
                              ),
                              prefixIcon: Icons.lock_outline_rounded,
                              validator: _validateCurrentPassword,
                            ),
                            const SizedBox(height: 20),

                            // New Password
                            StatefulBuilder(
                              builder: (_, setInnerState) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildPasswordField(
                                      label: 'New Password *',
                                      hint: 'Enter new password',
                                      controller: _newPasswordController,
                                      isVisible: _newPasswordVisible,
                                      isLoading: isLoading,
                                      onToggleVisibility: () {
                                        setState(() => _newPasswordVisible = !_newPasswordVisible);
                                      },
                                      prefixIcon: Icons.lock_open_rounded,
                                      validator: _validateNewPassword,
                                    ),
                                    // Strength indicator reacts to typing
                                    ValueListenableBuilder<TextEditingValue>(
                                      valueListenable: _newPasswordController,
                                      builder: (context, v, w) => _buildStrengthIndicator(),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 20),

                            // Confirm Password
                            _buildPasswordField(
                              label: 'Confirm New Password *',
                              hint: 'Re-enter new password',
                              controller: _confirmPasswordController,
                              isVisible: _confirmPasswordVisible,
                              isLoading: isLoading,
                              onToggleVisibility: () => setState(
                                () => _confirmPasswordVisible = !_confirmPasswordVisible,
                              ),
                              prefixIcon: Icons.lock_rounded,
                              validator: _validateConfirmPassword,
                              textInputAction: TextInputAction.done,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const SizedBox(height: 32),

                    // ── Submit button ─────────────────────────────────────
                    ElevatedButton(
                      onPressed: isLoading ? null : () => _onSubmit(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.lock_reset_rounded,
                                    color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'CHANGE PASSWORD',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
