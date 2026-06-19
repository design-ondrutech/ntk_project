import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/core/theme/app_theme.dart';
import 'package:ntk_project/src/core/widgets/ntk_dropdown_field.dart';
import 'package:ntk_project/src/core/widgets/ntk_text_field.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_event.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_state.dart';
import 'package:ntk_project/src/features/location/data/models/location_model.dart';
import 'package:ntk_project/src/features/location/data/repositories/location_repository_impl.dart';
import 'package:ntk_project/src/injection_container.dart';
import 'package:ntk_project/src/core/utils/validators.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _phoneErrorText;
  final _dobController = TextEditingController();
  String? _selectedGender;

  LocationModel? _selectedDistrict;
  LocationModel? _selectedThoguthi;
  LocationModel? _selectedArea;
  LocationModel? _selectedStreet;

  List<LocationModel> _districts = [];
  List<LocationModel> _thoguthis = [];
  List<LocationModel> _areas = [];
  List<LocationModel> _streets = [];

  bool _loadingDistricts = false;
  bool _loadingThoguthis = false;
  bool _loadingAreas = false;
  bool _loadingStreets = false;

  String? _selectedBloodGroup;
  String? _selectedProfession;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  late final LocationRepositoryImpl _locationRepo;

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
      _selectedThoguthi = null;
      _selectedArea = null;
      _selectedStreet = null;
      _thoguthis = [];
      _areas = [];
      _streets = [];
    });
    if (district == null) return;
    setState(() => _loadingThoguthis = true);
    try {
      final list = await _locationRepo.getLocationList(
        type: 'TALUK',
        parentId: district.id,
      );
      setState(() {
        _thoguthis = list;
        _loadingThoguthis = false;
      });
    } catch (_) {
      setState(() => _loadingThoguthis = false);
    }
  }

  Future<void> _onThoguthiChanged(LocationModel? thoguthi) async {
    setState(() {
      _selectedThoguthi = thoguthi;
      _selectedArea = null;
      _selectedStreet = null;
      _areas = [];
      _streets = [];
    });
    if (thoguthi == null) return;
    setState(() => _loadingAreas = true);
    try {
      final list = await _locationRepo.getLocationList(
        type: 'AREA',
        parentId: thoguthi.id,
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
      debugPrint('RegisterScreen _onAreaChanged error: $e');
    }
  }

  void _showSnack(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? NTKColors.error : NTKColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

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

  void _onSubmit() {
    if (_nameController.text.trim().isEmpty) {
      _showSnack('முழு பெயரை உள்ளிடவும்');
      return;
    }
    if (!Validators.isValidName(_nameController.text)) {
      _showSnack('முழு பெயர் ஆங்கிலம் மற்றும் தமிழ் எழுத்துக்களை மட்டுமே கொண்டிருக்க வேண்டும்');
      return;
    }
    if (_surnameController.text.trim().isNotEmpty && !Validators.isValidName(_surnameController.text)) {
      _showSnack('குடும்ப பெயர் ஆங்கிலம் மற்றும் தமிழ் எழுத்துக்களை மட்டுமே கொண்டிருக்க வேண்டும்');
      return;
    }
    if (_phoneController.text.trim().length < 10) {
      _showSnack('சரியான மொபைல் எண்ணை உள்ளிடவும்');
      return;
    }
    if (_selectedDistrict == null) {
      _showSnack('மாவட்டத்தைத் தேர்ந்தெடுக்கவும்');
      return;
    }
    if (_selectedThoguthi == null) {
      _showSnack('தொகுதியைத் தேர்ந்தெடுக்கவும்');
      return;
    }
    if (_selectedArea == null) {
      _showSnack('பகுதியைத் தேர்ந்தெடுக்கவும்');
      return;
    }
    if (_selectedStreet == null) {
      _showSnack('தெருவைத் தேர்ந்தெடுக்கவும்');
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
    if (_passwordController.text.length < 6) {
      _showSnack('கடவுச்சொல் குறைந்தது 6 எழுத்துகள் இருக்க வேண்டும்');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnack('கடவுச்சொற்கள் பொருந்தவில்லை');
      return;
    }

    context.read<AuthBloc>().add(
      RegisterRequested(
        name: _nameController.text.trim(),
        surname: _surnameController.text.trim().isEmpty
            ? null
            : _surnameController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        districtId: _selectedDistrict!.id,
        talukId: _selectedThoguthi!.id,
        areaId: _selectedArea!.id,
        streetId: _selectedStreet!.id,
        bloodGroup: _selectedBloodGroup,
        professionName: _selectedProfession,
        dateOfBirth: _dobController.text.trim().isEmpty
            ? null
            : _dobController.text.trim(),
        gender: _selectedGender,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: NTKColors.primary,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state.error != null) {
              final errMsg = state.error!;
              if (errMsg.contains('USER_PHONE_ALREADY_EXISTS') ||
                  errMsg.contains('This phone number is already registered') ||
                  errMsg.contains('already registered')) {
                setState(() {
                  _phoneErrorText = 'This mobile number is already registered';
                });
              } else {
                _showSnack(errMsg);
              }
            } else if (state.registrationSuccess) {
              Navigator.pushReplacementNamed(context, '/verification');
            }
          },
          child: Column(
            children: [
              Container(
                color: NTKColors.primary,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          'Member Registration',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.how_to_reg_outlined,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
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
                      const Text(
                        'Registering new member for Community',
                        style: TextStyle(
                          fontSize: 13,
                          color: NTKColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 24),

                      NTKTextField(
                        label: 'Full Name',
                        hintText: 'Enter full name',
                        controller: _nameController,
                        icon: CupertinoIcons.person,
                      ),
                      const SizedBox(height: 16),

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

                      _loadingDistricts
                          ? _buildLoadingField('District (மாவட்டம்)')
                          : NTKDropdownField<LocationModel>(
                              label: 'District (மாவட்டம்)',
                              items: _districts,
                              selectedValue: _selectedDistrict,
                              hintText: 'Select District',
                              onChanged: _onDistrictChanged,
                              itemLabel: (item) => item.name,
                            ),
                      const SizedBox(height: 16),

                      _loadingThoguthis
                          ? _buildLoadingField('Thoguthi (தொகுதி)')
                          : _selectedDistrict == null
                          ? _buildDisabledField(
                              'Thoguthi (தொகுதி)',
                              'முதலில் மாவட்டம் தேர்ந்தெடுக்கவும்',
                            )
                          : NTKDropdownField<LocationModel>(
                              label: 'Thoguthi (தொகுதி)',
                              items: _thoguthis,
                              selectedValue: _selectedThoguthi,
                              hintText: 'Select Thoguthi',
                              onChanged: _onThoguthiChanged,
                              itemLabel: (item) => item.name,
                            ),
                      const SizedBox(height: 16),

                      _loadingAreas
                          ? _buildLoadingField('Area (பகுதி)')
                          : _selectedThoguthi == null
                          ? _buildDisabledField(
                              'Area (பகுதி)',
                              'முதலில் தொகுதி தேர்ந்தெடுக்கவும்',
                            )
                          : NTKDropdownField<LocationModel>(
                              label: 'Area (பகுதி)',
                              items: _areas,
                              selectedValue: _selectedArea,
                              hintText: 'Select Area',
                              onChanged: _onAreaChanged,
                              itemLabel: (item) => item.name,
                            ),
                      const SizedBox(height: 16),

                      _loadingStreets
                          ? _buildLoadingField('Street (தெரு)')
                          : _selectedArea == null
                          ? _buildDisabledField(
                              'Street (தெரு)',
                              'முதலில் பகுதி தேர்ந்தெடுக்கவும்',
                            )
                          : NTKDropdownField<LocationModel>(
                              label: 'Street (தெரு)',
                              items: _streets,
                              selectedValue: _selectedStreet,
                              hintText: 'Select Street name',
                              onChanged: (val) =>
                                  setState(() => _selectedStreet = val),
                              itemLabel: (item) => item.name,
                            ),
                      const SizedBox(height: 16),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: NTKDropdownField<String>(
                              label: 'Blood Group',
                              items: _bloodGroups,
                              selectedValue: _selectedBloodGroup,
                              hintText: 'Select',
                              onChanged: (val) =>
                                  setState(() => _selectedBloodGroup = val),
                              itemLabel: (item) => item,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: NTKDropdownField<String>(
                              label: 'Profession',
                              items: _professions,
                              selectedValue: _selectedProfession,
                              hintText: 'Select',
                              onChanged: (val) =>
                                  setState(() => _selectedProfession = val),
                              itemLabel: (item) => item,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: GestureDetector(
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
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: NTKDropdownField<String>(
                              label: 'Gender',
                              items: const ['Male', 'Female', 'Other'],
                              selectedValue: _selectedGender,
                              hintText: 'Select Gender',
                              onChanged: (val) => setState(() => _selectedGender = val),
                              itemLabel: (item) => item,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      NTKTextField(
                        label: 'Password',
                        hintText: '••••••••',
                        controller: _passwordController,
                        icon: CupertinoIcons.lock,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? CupertinoIcons.eye_slash
                                : CupertinoIcons.eye,
                            size: 20,
                            color: NTKColors.textTertiary,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

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
                          onPressed: () => setState(
                            () => _obscureConfirm = !_obscureConfirm,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          return SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: state.isLoading ? null : _onSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: NTKColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: state.isLoading
                                  ? const CupertinoActivityIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      'SUBMIT REGISTRATION',
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
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
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
              Text('Loading...', style: TextStyle(color: Color(0xFF9CA3AF))),
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
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
