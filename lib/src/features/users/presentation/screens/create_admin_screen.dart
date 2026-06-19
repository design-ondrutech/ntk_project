import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/core/theme/app_theme.dart';
import 'package:ntk_project/src/core/widgets/ntk_app_bar.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ntk_project/src/core/widgets/ntk_text_field.dart';
import 'package:ntk_project/src/core/widgets/ntk_dropdown_field.dart';
import 'package:ntk_project/src/features/location/data/models/location_model.dart';
import 'package:ntk_project/src/features/location/data/repositories/location_repository_impl.dart';
import 'package:ntk_project/src/features/users/presentation/bloc/user_bloc.dart';
import 'package:ntk_project/src/features/users/presentation/bloc/user_event.dart';
import 'package:ntk_project/src/features/users/presentation/bloc/user_state.dart';
import 'package:ntk_project/src/core/widgets/ntk_snackbar.dart';
import 'package:ntk_project/src/injection_container.dart';
import 'package:ntk_project/src/core/utils/validators.dart';

class CreateAdminScreen extends StatefulWidget {
  const CreateAdminScreen({super.key});
  @override
  State<CreateAdminScreen> createState() => _CreateAdminScreenState();
}

class _CreateAdminScreenState extends State<CreateAdminScreen> {
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  LocationModel? _selectedDistrict;
  LocationModel? _selectedTaluk;

  List<LocationModel> _districts = [];
  List<LocationModel> _taluks = [];
  bool _loadingDistricts = false;
  bool _loadingTaluks = false;

  String? _selectedBloodGroup;
  String? _selectedProfession;
  bool _obscure = true;
  bool _obscureConfirm = true;
  
  final _dobController = TextEditingController();
  String? _selectedGender;
  String? _phoneErrorText;

  late LocationRepositoryImpl _locationRepo;

  Future<void> _selectDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF004D2A),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1F2937),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  static const List<String> _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
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

  @override
  void initState() {
    super.initState();
    _locationRepo = LocationRepositoryImpl(sl());
    _loadDistricts();
    _phoneController.addListener(() {
      if (_phoneErrorText != null) {
        setState(() {
          _phoneErrorText = null;
        });
      }
    });
  }

  Future<void> _loadDistricts() async {
    setState(() => _loadingDistricts = true);
    try {
      final list = await _locationRepo.getLocationList(type: 'DISTRICT');
      setState(() {
        _districts = list;
        _loadingDistricts = false;
      });
    } catch (_) {
      setState(() => _loadingDistricts = false);
    }
  }

  Future<void> _onDistrictChanged(LocationModel? district) async {
    setState(() {
      _selectedDistrict = district;
      _selectedTaluk = null;
      _taluks = [];
    });
    if (district == null) return;
    setState(() => _loadingTaluks = true);
    try {
      final list = await _locationRepo.getLocationList(
        type: 'TALUK',
        parentId: district.id,
      );
      setState(() {
        _taluks = list;
        _loadingTaluks = false;
      });
    } catch (_) {
      setState(() => _loadingTaluks = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  void _showSnack(String msg, {bool isError = true}) {
    if (isError) {
      NTKSnackbar.showError(context, message: msg);
    } else {
      NTKSnackbar.showSuccess(context, message: msg);
    }
  }

  void _onCreateAdmin() {
    if (_nameController.text.trim().isEmpty) {
      _showSnack('Please enter full name');
      return;
    }
    if (!Validators.isValidName(_nameController.text)) {
      _showSnack('Full Name can only contain English and Tamil alphabets and spaces');
      return;
    }
    if (_surnameController.text.trim().isNotEmpty && !Validators.isValidName(_surnameController.text)) {
      _showSnack('Surname can only contain English and Tamil alphabets and spaces');
      return;
    }
    if (_phoneController.text.trim().isEmpty) {
      _showSnack('Please enter mobile number');
      return;
    }
    if (_selectedDistrict == null) {
      _showSnack('Please select a District');
      return;
    }
    if (_selectedTaluk == null) {
      _showSnack('Please select a Taluk');
      return;
    }
    if (_selectedBloodGroup == null) {
      _showSnack('Please select Blood Group');
      return;
    }
    if (_selectedProfession == null) {
      _showSnack('Please select Profession');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnack('Passwords do not match');
      return;
    }
    if (_passwordController.text.length < 6) {
      _showSnack('Password must be at least 6 characters');
      return;
    }

    final dob = _dobController.text.trim().isEmpty ? null : _dobController.text.trim();
    final gender = _selectedGender;

    context.read<UserBloc>().add(
      CreateUserRequested(
        name: _nameController.text.trim(),
        surname: _surnameController.text.trim().isEmpty
            ? null
            : _surnameController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        role: 'ADMIN',
        locationId: _selectedTaluk!.id,
        dateOfBirth: dob,
        gender: gender,
        bloodGroup: _selectedBloodGroup,
        professionName: _selectedProfession,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserBloc, UserState>(
      listener: (context, state) {
        if (state is UserCreatedSuccess) {
          _showSnack('Admin created successfully', isError: false);
          Navigator.pop(context);
        } else if (state is UserFailure) {
          final errMsg = state.error;
          if (errMsg.contains('USER_PHONE_ALREADY_EXISTS') ||
              errMsg.contains('This phone number is already registered') ||
              errMsg.contains('already registered')) {
            setState(() {
              _phoneErrorText = 'This mobile number is already registered';
            });
          } else {
            _showSnack(errMsg);
          }
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F4F8),
        appBar: NTKAppBar(
          title: 'Create Admin',
          subtitle: context.read<AuthBloc>().state.loginData?.locationName ?? 'Admin Portal',
          showNotification: false,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Administrator Details',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Assign a new administrator for a specific Taluk.',
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
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

              // ── Mobile Number ────────────────────────────
              NTKTextField(
                label: 'Surname',
                hintText: 'Enter family name',
                controller: _surnameController,
                icon: CupertinoIcons.person_crop_circle,
              ),
              const SizedBox(height: 16),

              NTKTextField(
                label: 'Mobile Number',
                hintText: 'Enter mobile number',
                controller: _phoneController,
                icon: CupertinoIcons.phone,
                keyboardType: TextInputType.phone,
                errorText: _phoneErrorText,
              ),
              const SizedBox(height: 16),

              // ── District ─────────────────────────────────
              _loadingDistricts
                  ? _buildLoadingField('District')
                  : NTKDropdownField<LocationModel>(
                      label: 'District',
                      items: _districts,
                      selectedValue: _selectedDistrict,
                      hintText: 'Select District',
                      onChanged: _onDistrictChanged,
                      itemLabel: (item) => item.name,
                    ),
              const SizedBox(height: 16),

              // ── Taluk ─────────────────────────────────────
              _loadingTaluks
                  ? _buildLoadingField('Taluk')
                  : _selectedDistrict == null
                  ? _buildDisabledField('Taluk', 'Select District first')
                  : NTKDropdownField<LocationModel>(
                      label: 'Taluk',
                      items: _taluks,
                      selectedValue: _selectedTaluk,
                      hintText: 'Select Taluk',
                      onChanged: (val) => setState(() => _selectedTaluk = val),
                      itemLabel: (item) => item.name,
                    ),
              const SizedBox(height: 16),

              // ── Blood Group ──────────────────────────────
              NTKDropdownField<String>(
                label: 'Blood Group',
                items: _bloodGroups,
                selectedValue: _selectedBloodGroup,
                hintText: 'Select Blood Group',
                onChanged: (val) => setState(() => _selectedBloodGroup = val),
                itemLabel: (item) => item,
              ),
              const SizedBox(height: 16),

              // ── Profession ───────────────────────────────
              NTKDropdownField<String>(
                label: 'Profession',
                items: _professions,
                selectedValue: _selectedProfession,
                hintText: 'Select Profession',
                onChanged: (val) => setState(() => _selectedProfession = val),
                itemLabel: (item) => item,
              ),
              const SizedBox(height: 16),

              // ── Date of Birth ────────────────────────────
              GestureDetector(
                onTap: () => _selectDateOfBirth(context),
                child: AbsorbPointer(
                  child: NTKTextField(
                    label: 'Date of Birth',
                    hintText: 'YYYY-MM-DD',
                    controller: _dobController,
                    icon: CupertinoIcons.calendar,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Gender ───────────────────────────────────
              NTKDropdownField<String>(
                label: 'Gender',
                items: const ['Male', 'Female', 'Other'],
                selectedValue: _selectedGender,
                hintText: 'Select Gender',
                onChanged: (val) => setState(() => _selectedGender = val),
                itemLabel: (item) => item,
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
                      onPressed: isLoading ? null : _onCreateAdmin,
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
                              'CREATE ADMINISTRATOR',
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

  Widget _buildDisabledField(String label, String message) {
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
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.lock_outline,
                size: 16,
                color: Color(0xFF9CA3AF),
              ),
              const SizedBox(width: 8),
              Text(
                message,
                style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
