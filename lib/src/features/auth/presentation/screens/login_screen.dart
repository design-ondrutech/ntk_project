import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_event.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_state.dart';
import 'package:ntk_project/src/features/location/presentation/bloc/location_bloc.dart';
import 'package:ntk_project/src/features/location/presentation/bloc/location_event.dart';
import 'package:ntk_project/src/features/location/presentation/bloc/location_state.dart';
import 'package:ntk_project/src/core/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String selectedRole = 'ADMIN';
  final List<Map<String, dynamic>> roles = [
    {'label': 'Super Admin', 'value': 'SUPER_ADMIN', 'icon': Icons.security},
    {'label': 'Admin', 'value': 'ADMIN', 'icon': Icons.person_add_alt_1},
    {
      'label': 'Sub Admin',
      'value': 'SUB_ADMIN',
      'icon': Icons.supervised_user_circle,
    },
    {'label': 'Member', 'value': 'MEMBER', 'icon': Icons.person},
  ];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    context.read<LocationBloc>().add(const FetchDistricts());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _selectedRoleLabel = 'Admin';

  String get _selectedRoleValue {
    return roles.firstWhere(
          (r) => r['label'] == _selectedRoleLabel,
          orElse: () => roles[1],
        )['value']
        as String;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: NTKColors.background,
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, authState) {
            if (authState.loginData != null) {
              final role = authState.loginData!.role;
              final status = authState.loginData!.approvalStatus.toUpperCase();
              if (role == 'MEMBER' && status != 'APPROVED') {
                Navigator.pushReplacementNamed(context, '/verification');
              } else {
                Navigator.pushReplacementNamed(context, '/dashboard');
              }
            } else if (authState.error != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(authState.error!),
                  backgroundColor: theme.colorScheme.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          builder: (context, authState) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 24.0,
              ),
              child: BlocBuilder<LocationBloc, LocationState>(
                builder: (context, locState) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // ─── Header Section ───────────────────────────────
                      // ─── Header Section ───────────────────────────────
                      const SizedBox(height: 60),
                      const SizedBox(height: 8),
                      Text('Welcome Back!', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(
                        'Please login to continue',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 40),

                      // ─── Role Selection Grid ──────────────────────────
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Select Your Role',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 2.2,
                            ),
                        itemCount: roles.length,
                        itemBuilder: (context, index) {
                          final role = roles[index];
                          final isSelected =
                              _selectedRoleLabel == role['label'];
                          return GestureDetector(
                            onTap: () => setState(
                              () =>
                                  _selectedRoleLabel = role['label'] as String,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? NTKColors.emerald50
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? NTKColors.primary
                                      : NTKColors.border,
                                  width: 1.5,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: NTKColors.primary.withOpacity(
                                            0.1,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    role['icon'],
                                    color: isSelected
                                        ? NTKColors.primary
                                        : NTKColors.textSecondary,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    role['label'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? NTKColors.primaryDark
                                          : NTKColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 32),

                      // ─── Input Fields ─────────────────────────────────
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Phone Number',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          hintText: 'Enter phone number',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Password',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                      ),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: Text(
                            'Forgot Password?',
                            style: theme.textTheme.labelLarge,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ─── Login Button ─────────────────────────────────
                      ElevatedButton(
                        onPressed: authState.isLoading
                            ? null
                            : () {
                                context.read<AuthBloc>().add(
                                  LoginRequested(
                                    phone: _nameController.text,
                                    role: _selectedRoleValue,
                                    password: _passwordController.text,
                                  ),
                                );
                              },
                        child: authState.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Text(
                                    'LOGIN',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.login, color: Colors.white),
                                ],
                              ),
                      ),

                      // ─── Register Button (Only for Member) ─────────────
                      if (_selectedRoleLabel == 'Member') ...[
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/register'),
                          child: const Text('REGISTER'),
                        ),
                      ],
                      const SizedBox(height: 32),

                      // ─── Footer Section ───────────────────────────────
                      Column(
                        children: [
                          const Text(
                            'Managed by NTK Headquarters',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.verified_user_outlined,
                                size: 14,
                                color: Colors.grey,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Secure Login with JWT',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
