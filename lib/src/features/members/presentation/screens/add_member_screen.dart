import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/core/theme/app_theme.dart';
import 'package:ntk_project/src/core/widgets/ntk_app_bar.dart';
import 'package:ntk_project/src/core/widgets/ntk_text_field.dart';
import 'package:ntk_project/src/core/widgets/ntk_dropdown_field.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_state.dart';
import 'package:ntk_project/src/features/location/data/models/location_model.dart';
import 'package:ntk_project/src/features/location/domain/repositories/location_repository.dart';
import 'package:ntk_project/src/injection_container.dart';
import 'package:ntk_project/src/features/users/presentation/bloc/user_bloc.dart';
import 'package:ntk_project/src/features/users/presentation/bloc/user_event.dart';
import 'package:ntk_project/src/features/users/presentation/bloc/user_state.dart';
import 'package:ntk_project/src/core/widgets/ntk_snackbar.dart';

class AddMemberScreen extends StatefulWidget {
  const AddMemberScreen({super.key});

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _professionController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? selectedBloodGroup;
  LocationModel? selectedStreet;
  bool _obscure = true;
  bool _obscureConfirm = true;

  final List<String> bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'O+',
    'O-',
    'AB+',
    'AB-',
  ];
  static const List<String> _professions = [
    'Farmer',
    'Teacher',
    'Doctor',
    'Engineer',
    'Lawyer',
    'Business',
    'Government Employee',
    'Private Employee',
    'Student',
    'Other',
  ];

  List<LocationModel> streets = [];
  bool isLoadingStreets = false;

  @override
  void initState() {
    super.initState();
    _loadStreets();
  }

  Future<void> _loadStreets() async {
    final authState = context.read<AuthBloc>().state;
    final areaId = authState.loginData?.locationId;
    if (areaId == null) return;

    setState(() => isLoadingStreets = true);
    try {
      final repo = sl<LocationRepository>();
      final list = await repo.getLocationList(parentId: areaId, type: 'STREET');
      setState(() {
        streets = list;
        isLoadingStreets = false;
      });
    } catch (e) {
      setState(() => isLoadingStreets = false);
      _showSnack('Unable to load streets. Please try again.');
      debugPrint('AddMemberScreen _loadStreets error: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _phoneController.dispose();
    _professionController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showSnack(String msg, {bool isError = true}) {
    if (isError) {
      NTKSnackbar.showError(context, message: msg);
    } else {
      NTKSnackbar.showSuccess(context, message: msg);
    }
  }

  void _onAddMember() {
    if (_nameController.text.trim().isEmpty) {
      _showSnack('Please enter full name');
      return;
    }
    if (_phoneController.text.trim().isEmpty) {
      _showSnack('Please enter mobile number');
      return;
    }
    if (_passwordController.text.isEmpty) {
      _showSnack('Please enter password');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnack('Passwords do not match');
      return;
    }
    if (selectedStreet == null) {
      _showSnack('Please select a street');
      return;
    }

    final authState = context.read<AuthBloc>().state;

    context.read<UserBloc>().add(
      AddMemberRequested(
        name: _nameController.text.trim(),
        surname: _surnameController.text.trim().isEmpty
            ? null
            : _surnameController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        streetId: selectedStreet!.id,
        areaId: authState.loginData?.locationId,
        bloodGroup: selectedBloodGroup,
        professionName: _professionController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserBloc, UserState>(
      listener: (context, state) {
        if (state is UserCreatedSuccess) {
          _showSnack('Member added successfully', isError: false);
          Navigator.pop(context);
        } else if (state is UserFailure) {
          _showSnack(state.error);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F4F8),
        appBar: NTKAppBar(
          title: 'Add Member',
          subtitle: context.read<AuthBloc>().state.loginData?.locationName ?? 'Admin Portal',
          showNotification: false,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, authState) {
                  final areaName =
                      authState.loginData?.locationName ?? 'Community';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Member Details',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Registering new member for $areaName',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF059669),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),

              // ── Full Name ────────────────────────────────
              NTKTextField(
                label: 'Full Name',
                hintText: 'Enter full name',
                controller: _nameController,
                icon: CupertinoIcons.person,
              ),
              const SizedBox(height: 16),
              NTKTextField(
                label: 'Surname',
                hintText: 'Enter surname',
                controller: _surnameController,
                icon: CupertinoIcons.person,
              ),
              const SizedBox(height: 16),

              // ── Mobile Number ────────────────────────────
              NTKTextField(
                label: 'Mobile Number',
                hintText: 'Enter mobile number',
                controller: _phoneController,
                icon: CupertinoIcons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              // ── Street ───────────────────────────────────
              isLoadingStreets
                  ? _buildLoadingField('Street')
                  : NTKDropdownField<LocationModel>(
                      label: 'Street',
                      items: streets,
                      selectedValue: selectedStreet,
                      hintText: 'Select Street name',
                      onChanged: (val) => setState(() => selectedStreet = val),
                      itemLabel: (item) => item.name,
                    ),
              const SizedBox(height: 16),

              // ── Blood Group & Profession Row ─────────────
              Row(
                children: [
                  Expanded(
                    child: NTKDropdownField<String>(
                      label: 'Blood Group',
                      items: bloodGroups,
                      selectedValue: selectedBloodGroup,
                      hintText: 'Select',
                      onChanged: (val) =>
                          setState(() => selectedBloodGroup = val),
                      itemLabel: (item) => item,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: NTKDropdownField<String>(
                      label: 'Profession',
                      items: _professions,
                      selectedValue: _professionController.text.isEmpty
                          ? null
                          : _professionController.text,
                      hintText: 'Select',
                      onChanged: (val) => setState(
                        () => _professionController.text = val ?? '',
                      ),
                      itemLabel: (item) => item,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Password ─────────────────────────────────
              NTKTextField(
                label: 'Password',
                hintText: '••••••••',
                controller: _passwordController,
                icon: CupertinoIcons.lock,
                obscureText: _obscure,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                    size: 20,
                    color: NTKColors.textTertiary,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              const SizedBox(height: 16),

              // ── Confirm Password ─────────────────────────
              NTKTextField(
                label: 'Confirm Password',
                hintText: '••••••••',
                controller: _confirmPasswordController,
                icon: CupertinoIcons.lock,
                obscureText: _obscureConfirm,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? CupertinoIcons.eye_slash
                        : CupertinoIcons.eye,
                    size: 20,
                    color: NTKColors.textTertiary,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              const SizedBox(height: 36),

              // ── Submit ───────────────────────────────────
              BlocBuilder<UserBloc, UserState>(
                builder: (context, state) {
                  final isLoading = state is UserLoading;
                  return SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _onAddMember,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: NTKColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: isLoading
                          ? const CupertinoActivityIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                              'ADD MEMBER',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingField(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: const Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text(
                'Loading...',
                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
