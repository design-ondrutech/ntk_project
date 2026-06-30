import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ntk_project/l10n/app_localizations.dart';
import 'package:ntk_project/src/core/theme/app_theme.dart';
import 'package:ntk_project/src/core/widgets/ntk_snackbar.dart';
import 'package:ntk_project/src/core/widgets/async_base64_image.dart';
import 'package:ntk_project/src/core/widgets/image_crop_dialog.dart';
import 'package:ntk_project/src/features/auth/data/models/admin_login_model.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_event.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_state.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/edit_profile_bloc.dart';
import 'package:ntk_project/src/injection_container.dart' as di;

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _surnameController;
  late TextEditingController _phoneController;
  
  String? _selectedBloodGroup;
  String? _selectedProfession;
  String? _selectedDateOfBirth;
  File? _pickedImage;
  bool _imageRemoved = false;
  
  final ImagePicker _imagePicker = ImagePicker();
  
  static const List<String> _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-',
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
    final loginData = context.read<AuthBloc>().state.loginData;
    
    _nameController = TextEditingController(text: loginData?.name ?? '');
    _surnameController = TextEditingController(text: loginData?.surname ?? '');
    _phoneController = TextEditingController(text: loginData?.phone ?? '');
    _selectedDateOfBirth = loginData?.dateOfBirth;
    
    final prof = loginData?.professionName?.trim();
    if (prof != null && prof.isNotEmpty) {
      final match = _professions.firstWhere(
        (p) => p.toLowerCase() == prof.toLowerCase(),
        orElse: () => '',
      );
      if (match.isNotEmpty) {
        _selectedProfession = match;
      } else {
        _selectedProfession = 'Other';
      }
    }
    
    _selectedBloodGroup = _mapBloodGroupToUi(loginData?.bloodGroup);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String? _mapBloodGroupToUi(String? bloodGroup) {
    if (bloodGroup == null) return null;
    final bg = bloodGroup.trim().toUpperCase();
    switch (bg) {
      case 'A_POSITIVE': return 'A+';
      case 'A_NEGATIVE': return 'A-';
      case 'B_POSITIVE': return 'B+';
      case 'B_NEGATIVE': return 'B-';
      case 'AB_POSITIVE': return 'AB+';
      case 'AB_NEGATIVE': return 'AB-';
      case 'O_POSITIVE': return 'O+';
      case 'O_NEGATIVE': return 'O-';
      default:
        if (_bloodGroups.contains(bg)) return bg;
        if (_bloodGroups.contains(bloodGroup)) return bloodGroup;
        return null;
    }
  }

  Future<void> _pickDateOfBirth() async {
    final initialDate = _selectedDateOfBirth != null
        ? (DateTime.tryParse(_selectedDateOfBirth!) ?? DateTime.now())
        : DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: NTKColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDateOfBirth =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Choose Profile Photo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: NTKColors.primary),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                final picked = await _imagePicker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 80,
                );
                if (picked != null && mounted) {
                  final cropped = await Navigator.push<File>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ImageCropDialog(imageFile: File(picked.path)),
                    ),
                  );
                  if (cropped != null && mounted) {
                    setState(() {
                      _pickedImage = cropped;
                      _imageRemoved = false;
                    });
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: NTKColors.primary),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final picked = await _imagePicker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 80,
                );
                if (picked != null && mounted) {
                  final cropped = await Navigator.push<File>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ImageCropDialog(imageFile: File(picked.path)),
                    ),
                  );
                  if (cropped != null && mounted) {
                    setState(() {
                      _pickedImage = cropped;
                      _imageRemoved = false;
                    });
                  }
                }
              },
            ),
            if (_pickedImage != null || (_imageRemoved == false && context.read<AuthBloc>().state.loginData?.image != null && context.read<AuthBloc>().state.loginData!.image!.isNotEmpty))
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _pickedImage = null;
                    _imageRemoved = true;
                  });
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarImage(AdminLoginModel? loginData) {
    final initial = (loginData?.name ?? 'U').trim().isEmpty
        ? 'U'
        : (loginData?.name ?? 'U').trim()[0].toUpperCase();

    if (_pickedImage != null) {
      return Image.file(
        _pickedImage!,
        fit: BoxFit.cover,
      );
    }

    if (_imageRemoved) {
      return _buildInitialAvatar(initial);
    }

    final imagePath = loginData?.image;
    if (imagePath == null || imagePath.isEmpty) {
      return _buildInitialAvatar(initial);
    }

    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildInitialAvatar(initial),
      );
    }

    try {
      final clean = imagePath.contains('base64,')
          ? imagePath.substring(imagePath.indexOf('base64,') + 7)
          : imagePath;
      return AsyncBase64Image(
        base64String: clean,
        fit: BoxFit.cover,
        placeholderBuilder: (_) => _buildInitialAvatar(initial),
        errorBuilder: (_, __, ___) => _buildInitialAvatar(initial),
      );
    } catch (_) {
      return _buildInitialAvatar(initial);
    }
  }

  Widget _buildInitialAvatar(String initial) {
    return Container(
      color: NTKColors.primary,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 36,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loginData = context.watch<AuthBloc>().state.loginData;
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return BlocProvider<EditProfileBloc>(
      create: (_) => di.sl<EditProfileBloc>(),
      child: Scaffold(
        backgroundColor: NTKColors.background,
        appBar: AppBar(
          title: Text(loc?.editProfile ?? 'Edit Profile'),
          backgroundColor: NTKColors.primary,
          foregroundColor: Colors.white,
        ),
        body: BlocConsumer<EditProfileBloc, EditProfileState>(
          listener: (context, state) {
            if (state is EditProfileSuccess) {
              NTKSnackbar.showSuccess(context, message: 'Profile Updated Successfully');
              context.read<AuthBloc>().add(LoadMeRequested());
              Navigator.pop(context);
            } else if (state is EditProfileFailure) {
              NTKSnackbar.showError(context, message: state.errorMessage);
            }
          },
          builder: (context, state) {
            final isLoading = state is EditProfileLoading;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Avatar picking section
                    Center(
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: _buildAvatarImage(loginData),
                            ),
                          ),
                          GestureDetector(
                            onTap: isLoading ? null : _pickImage,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: NTKColors.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  )
                                ],
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Card of inputs
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
                            Text(
                              'Name *',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontSize: 13,
                                color: NTKColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _nameController,
                              enabled: !isLoading,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                hintText: 'Enter name',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Please enter name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            Text(
                              'Surname *',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontSize: 13,
                                color: NTKColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _surnameController,
                              enabled: !isLoading,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                hintText: 'Enter surname',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Please enter surname';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            Text(
                              'Mobile Number *',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontSize: 13,
                                color: NTKColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _phoneController,
                              enabled: !isLoading,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              decoration: const InputDecoration(
                                hintText: 'Enter mobile number',
                                prefixIcon: Icon(Icons.phone_outlined),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Please enter mobile number';
                                }
                                if (val.trim().length < 10) {
                                  return 'Please enter a valid 10-digit mobile number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            Text(
                              'Date of Birth',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontSize: 13,
                                color: NTKColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: isLoading ? null : _pickDateOfBirth,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  hintText: 'Select Date of Birth',
                                  prefixIcon: Icon(Icons.calendar_today_outlined),
                                ),
                                child: Text(
                                  _selectedDateOfBirth ?? 'Select Date of Birth',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _selectedDateOfBirth == null ? Colors.black54 : Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            Text(
                              'Blood Group *',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontSize: 13,
                                color: NTKColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: _selectedBloodGroup,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                hintText: 'Select blood group',
                                prefixIcon: Icon(Icons.bloodtype_outlined),
                              ),
                              items: _bloodGroups.map((bg) => DropdownMenuItem(
                                value: bg,
                                child: Text(bg),
                              )).toList(),
                              onChanged: isLoading
                                  ? null
                                  : (val) {
                                      setState(() {
                                        _selectedBloodGroup = val;
                                      });
                                    },
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Please select blood group';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            Text(
                              'Profession *',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontSize: 13,
                                color: NTKColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: _selectedProfession,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                hintText: 'Select profession',
                                prefixIcon: Icon(Icons.work_outline),
                              ),
                              items: _professions.map((p) => DropdownMenuItem(
                                value: p,
                                child: Text(p),
                              )).toList(),
                              onChanged: isLoading
                                  ? null
                                  : (val) {
                                      setState(() {
                                        _selectedProfession = val;
                                      });
                                    },
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Please select profession';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Save Button
                    ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              if (_formKey.currentState!.validate() && loginData != null) {
                                String? finalImage;
                                if (_pickedImage != null) {
                                  final bytes = await _pickedImage!.readAsBytes();
                                  finalImage = base64Encode(bytes);
                                } else if (_imageRemoved) {
                                  finalImage = "";
                                } else {
                                  finalImage = loginData.image;
                                }

                                if (mounted) {
                                  context.read<EditProfileBloc>().add(
                                    SubmitEditProfile(
                                      id: loginData.id,
                                      name: _nameController.text.trim(),
                                      surname: _surnameController.text.trim().isEmpty ? null : _surnameController.text.trim(),
                                      phone: _phoneController.text.trim(),
                                      bloodGroup: _selectedBloodGroup!,
                                      professionName: _selectedProfession!,
                                      image: finalImage,
                                      dateOfBirth: _selectedDateOfBirth,
                                    ),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: NTKColors.primary,
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                          : const Text(
                              'SAVE CHANGES',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
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
