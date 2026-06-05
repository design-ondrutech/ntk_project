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

class CreateMemberScreen extends StatefulWidget {
  const CreateMemberScreen({super.key});
  @override
  State<CreateMemberScreen> createState() => _CreateMemberScreenState();
}

class _CreateMemberScreenState extends State<CreateMemberScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  LocationModel? _selectedDistrict;
  LocationModel? _selectedTaluk;
  LocationModel? _selectedArea;
  LocationModel? _selectedStreet;

  List<LocationModel> _districts = [];
  List<LocationModel> _taluks = [];
  List<LocationModel> _areas = [];
  List<LocationModel> _streets = [];

  bool _loadingDistricts = false;
  bool _loadingTaluks = false;
  bool _loadingAreas = false;
  bool _loadingStreets = false;

  String? _selectedBloodGroup;
  String? _selectedProfession;
  bool _obscure = true;
  bool _obscureConfirm = true;

  final _dobController = TextEditingController();
  String? _selectedGender;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initLocationForRole();
    });
  }

  Future<void> _initLocationForRole() async {
    final authState = context.read<AuthBloc>().state;
    final role = authState.loginData?.role;
    final locationId = authState.loginData?.locationId;

    if (role == 'SUB_ADMIN' && locationId != null) {
      final assignedArea = LocationModel(
        id: locationId,
        name: authState.loginData?.locationName ?? 'Assigned Area',
      );
      setState(() {
        _selectedArea = assignedArea;
        _areas = [assignedArea];
      });
      await _onAreaChanged(assignedArea);

      // Fetch parent district/taluk in background for form submission
      try {
        final districts = await _locationRepo.getLocationList(type: 'DISTRICT');
        bool found = false;
        for (final district in districts) {
          final taluks = await _locationRepo.getLocationList(
            parentId: district.id,
            type: 'TALUK',
          );
          for (final taluk in taluks) {
            final areas = await _locationRepo.getLocationList(
              parentId: taluk.id,
              type: 'AREA',
            );
            if (areas.any((a) => a.id == locationId)) {
              if (mounted) {
                setState(() {
                  _selectedDistrict = district;
                  _districts = [district];
                  _selectedTaluk = taluk;
                  _taluks = [taluk];
                });
              }
              found = true;
              break;
            }
          }
          if (found) break;
        }
      } catch (e) {
        debugPrint('Error finding parent district/taluk: $e');
      }
    } else {
      _loadDistricts();
    }
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
      _selectedArea = null;
      _selectedStreet = null;
      _taluks = [];
      _areas = [];
      _streets = [];
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

  Future<void> _onTalukChanged(LocationModel? taluk) async {
    setState(() {
      _selectedTaluk = taluk;
      _selectedArea = null;
      _selectedStreet = null;
      _areas = [];
      _streets = [];
    });
    if (taluk == null) return;
    setState(() => _loadingAreas = true);
    try {
      final list = await _locationRepo.getLocationList(
        type: 'AREA',
        parentId: taluk.id,
      );
      setState(() {
        _areas = list;
        _loadingAreas = false;
      });
    } catch (_) {
      setState(() => _loadingAreas = false);
    }
  }

  Future<void> _onAreaChanged(LocationModel? area) async {
    setState(() {
      _selectedArea = area;
      _selectedStreet = null;
      _streets = [];
    });
    if (area == null) return;
    setState(() => _loadingStreets = true);
    try {
      final list = await _locationRepo.getLocationList(
        type: 'STREET',
        parentId: area.id,
      );
      setState(() {
        _streets = list;
        _loadingStreets = false;
      });
    } catch (e) {
      setState(() => _loadingStreets = false);
      _showSnack('Unable to load streets. Please try again.');
      debugPrint('CreateMemberScreen _onAreaChanged error: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
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

  void _onCreateMember() {
    if (_nameController.text.trim().isEmpty) {
      _showSnack('Please enter full name');
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
    if (_selectedArea == null) {
      _showSnack('Please select an Area');
      return;
    }
    if (_selectedStreet == null) {
      _showSnack('Please select a Street');
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
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        role: 'MEMBER',
        districtId: _selectedDistrict!.id,
        talukId: _selectedTaluk!.id,
        areaId: _selectedArea!.id,
        streetId: _selectedStreet!.id,
        bloodGroup: _selectedBloodGroup,
        professionName: _selectedProfession,
        dateOfBirth: dob,
        gender: gender,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userRole = context.watch<AuthBloc>().state.loginData?.role;
    final isSubAdmin = userRole == 'SUB_ADMIN';

    return BlocListener<UserBloc, UserState>(
      listener: (context, state) {
        if (state is UserCreatedSuccess) {
          _showSnack('Member registered successfully', isError: false);
          Navigator.pop(context);
        } else if (state is UserFailure) {
          _showSnack(state.error);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F4F8),
        appBar: NTKAppBar(
          title: 'Create Member',
          subtitle: context.read<AuthBloc>().state.loginData?.locationName ?? 'Admin Portal',
          showNotification: false,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'New Member Registration',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Register a new member to the community.',
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
                label: 'Mobile Number',
                hintText: 'Enter mobile number',
                controller: _phoneController,
                icon: CupertinoIcons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              // ── District ─────────────────────────────────
              if (!isSubAdmin) ...[
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
                        onChanged: _onTalukChanged,
                        itemLabel: (item) => item.name,
                      ),
                const SizedBox(height: 16),

                // ── Area ──────────────────────────────────────
                _loadingAreas
                    ? _buildLoadingField('Area')
                    : _selectedTaluk == null
                    ? _buildDisabledField('Area', 'Select Taluk first')
                    : NTKDropdownField<LocationModel>(
                        label: 'Area',
                        items: _areas,
                        selectedValue: _selectedArea,
                        hintText: 'Select Area',
                        onChanged: _onAreaChanged,
                        itemLabel: (item) => item.name,
                      ),
                const SizedBox(height: 16),
              ],

              // ── Street ────────────────────────────────────
              _loadingStreets
                  ? _buildLoadingField('Street')
                  : _selectedArea == null
                  ? _buildDisabledField('Street', 'Select Area first')
                  : NTKDropdownField<LocationModel>(
                      label: 'Street',
                      items: _streets,
                      selectedValue: _selectedStreet,
                      hintText: 'Select Street',
                      onChanged: (val) => setState(() => _selectedStreet = val),
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
                      onPressed: isLoading ? null : _onCreateMember,
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
                              'REGISTER MEMBER',
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
