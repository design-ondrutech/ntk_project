import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/core/theme/app_theme.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_event.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_state.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _scrollController = ScrollController();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto-scroll to bottom when a field gains focus so keyboard doesn't cover it
    _phoneFocus.addListener(_onFocusChange);
    _passwordFocus.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_phoneFocus.hasFocus || _passwordFocus.hasFocus) {
      Future.delayed(const Duration(milliseconds: 350), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _scrollController.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _checkStatus() {
    if (_phoneController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('மொபைல் எண் மற்றும் கடவுச்சொல்லை உள்ளிடவும்'),
        ),
      );
      return;
    }
    context.read<AuthBloc>().add(
      LoginRequested(
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: NTKColors.background,
      // resizeToAvoidBottomInset: true shrinks the body when keyboard appears
      // so SingleChildScrollView can scroll fields into view
      resizeToAvoidBottomInset: true,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.loginData != null) {
            final status = state.loginData!.approvalStatus;
            if (status == 'APPROVED') {
              Navigator.pushReplacementNamed(context, '/dashboard');
            } else if (state.error == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'இன்னும் Admin/Sub-admin அனுமதி கொடுக்கவில்லை. காத்திருக்கவும்.',
                  ),
                  backgroundColor: NTKColors.primary,
                ),
              );
            }
          } else if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          }
        },
        child: SafeArea(
          child: GestureDetector(
            // Tap outside text fields → dismiss keyboard
            onTap: () => FocusScope.of(context).unfocus(),
            behavior: HitTestBehavior.opaque,
            child: SingleChildScrollView(
              controller: _scrollController,
              // Drag down on the list → dismiss keyboard
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  // ── Illustration ──────────────────────────────────────
                  Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: NTKColors.slate900.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.watch_later_outlined,
                        size: 60,
                        color: NTKColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // ── Heading ───────────────────────────────────────────
                  Text(
                    'Your details are under verification',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: NTKColors.primaryDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Please wait while we verify your details. Our administrative team is currently reviewing your membership application.',
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'உங்கள் பகுதியின் Admin அல்லது Sub-admin அனுமதி செய்த பிறகே Member Dashboard திறக்கும்.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: NTKColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // ── Dots indicator ────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      4,
                      (index) => Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              index == 0 ? NTKColors.primary : NTKColors.border,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                  // ── Mobile Number ─────────────────────────────────────
                  TextField(
                    controller: _phoneController,
                    focusNode: _phoneFocus,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    onSubmitted: (_) =>
                        FocusScope.of(context).requestFocus(_passwordFocus),
                    decoration: const InputDecoration(
                      labelText: 'Mobile Number',
                      hintText: 'பதிவு செய்த எண்',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // ── Password ──────────────────────────────────────────
                  TextField(
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _checkStatus(),
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      hintText: 'கடவுச்சொல்',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // ── Check status button ───────────────────────────────
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: state.isLoading ? null : _checkStatus,
                          child: state.isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('அனுமதி நிலையை சரிபார்'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () {
                      context.read<AuthBloc>().add(LogoutRequested());
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    child: const Text('LOGIN க்கு திரும்பு'),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
