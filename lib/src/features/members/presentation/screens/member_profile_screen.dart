import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ntk_project/src/core/theme/app_theme.dart';
import 'package:ntk_project/src/core/widgets/ntk_app_bar.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_event.dart';
import 'package:ntk_project/src/features/location/data/models/location_model.dart';
import 'package:ntk_project/src/features/location/domain/repositories/location_repository.dart';
import 'package:ntk_project/src/features/members/data/models/member_model.dart';
import 'package:ntk_project/src/features/members/presentation/bloc/member_bloc.dart';
import 'package:ntk_project/src/features/members/presentation/bloc/member_event.dart';
import 'package:ntk_project/src/features/members/presentation/bloc/member_state.dart';
import 'package:ntk_project/src/core/widgets/async_base64_image.dart';
import 'package:ntk_project/src/injection_container.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ntk_project/src/core/utils/validators.dart';
import 'package:ntk_project/src/core/network/graphql_service.dart';
import 'package:ntk_project/src/core/widgets/shimmer_loader.dart';
import 'package:ntk_project/src/core/widgets/image_crop_dialog.dart';

class MemberProfileScreen extends StatefulWidget {
  const MemberProfileScreen({super.key});

  @override
  State<MemberProfileScreen> createState() => _MemberProfileScreenState();
}

class _MemberProfileScreenState extends State<MemberProfileScreen> {
  int? _memberId;
  bool _hasFetched = false;
  String? _resolvedDistrict;
  String? _resolvedConstituency;
  String? _resolvedArea;
  String? _resolvedStreet;
  int? _resolvedForMemberId;
  bool _isResolvingLocation = false;

  // Local profile image picked by user
  File? _pickedImage;
  final ImagePicker _imagePicker = ImagePicker();

  static const List<String> _roles = ['MEMBER', 'ADMIN', 'SUB_ADMIN'];
  static const List<String> _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-',
  ];
  static const List<String> _professions = [
    'Farmer', 'Teacher', 'Doctor', 'Engineer', 'Lawyer',
    'Business', 'Government Employee', 'Private Employee', 'Student', 'Other',
  ];

  void _resolveParentLocations(MemberModel member) async {
    if (_resolvedForMemberId == member.id || _isResolvingLocation) return;
    _resolvedForMemberId = member.id;
    
    final loc = member.location;
    if (loc == null) return;
    
    // Set immediate street name first and placeholders for parent fields
    setState(() {
      _resolvedStreet = loc.name;
      _resolvedArea = '—';
      _resolvedConstituency = '—';
      _resolvedDistrict = '—';
      _isResolvingLocation = true;
    });

    try {
      final graphQLService = sl<GraphQLService>();
      
      // We will resolve sequentially upwards based on type
      int? currentParentId = loc.parentId;
      String currentType = loc.type ?? 'STREET';
      
      if (currentType == 'STREET') {
        if (currentParentId != null) {
          // 1. Fetch Area details
          final areaData = await _fetchSingleLocationDetails(graphQLService, currentParentId);
          if (areaData != null && mounted) {
            setState(() {
              _resolvedArea = areaData['name'];
            });
            currentParentId = areaData['parentId'] != null ? int.tryParse(areaData['parentId'].toString()) : null;
            
            if (currentParentId != null) {
              // 2. Fetch Taluk details
              final talukData = await _fetchSingleLocationDetails(graphQLService, currentParentId);
              if (talukData != null && mounted) {
                setState(() {
                  _resolvedConstituency = talukData['name'];
                });
                currentParentId = talukData['parentId'] != null ? int.tryParse(talukData['parentId'].toString()) : null;
                
                if (currentParentId != null) {
                  // 3. Fetch District details
                  final districtData = await _fetchSingleLocationDetails(graphQLService, currentParentId);
                  if (districtData != null && mounted) {
                    setState(() {
                      _resolvedDistrict = districtData['name'];
                    });
                  }
                }
              }
            }
          }
        }
      } else if (currentType == 'AREA') {
        setState(() {
          _resolvedArea = loc.name;
          _resolvedStreet = '—';
        });
        if (currentParentId != null) {
          // Fetch Taluk details
          final talukData = await _fetchSingleLocationDetails(graphQLService, currentParentId);
          if (talukData != null && mounted) {
            setState(() {
              _resolvedConstituency = talukData['name'];
            });
            currentParentId = talukData['parentId'] != null ? int.tryParse(talukData['parentId'].toString()) : null;
            
            if (currentParentId != null) {
              // Fetch District details
              final districtData = await _fetchSingleLocationDetails(graphQLService, currentParentId);
              if (districtData != null && mounted) {
                setState(() {
                  _resolvedDistrict = districtData['name'];
                });
              }
            }
          }
        }
      } else if (currentType == 'TALUK' || currentType == 'CONSTITUENCY') {
        setState(() {
          _resolvedConstituency = loc.name;
          _resolvedArea = '—';
          _resolvedStreet = '—';
        });
        if (currentParentId != null) {
          // Fetch District details
          final districtData = await _fetchSingleLocationDetails(graphQLService, currentParentId);
          if (districtData != null && mounted) {
            setState(() {
              _resolvedDistrict = districtData['name'];
            });
          }
        }
      } else if (currentType == 'DISTRICT') {
        setState(() {
          _resolvedDistrict = loc.name;
          _resolvedConstituency = '—';
          _resolvedArea = '—';
          _resolvedStreet = '—';
        });
      }
    } catch (e) {
      debugPrint('Error resolving parent locations: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isResolvingLocation = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>?> _fetchSingleLocationDetails(GraphQLService service, int id) async {
    const String query = r'''
      query GetLocationDetails($id: Int!) {
        getLocationDetails(id: $id) {
          id
          name
          type
          parentId
        }
      }
    ''';
    final result = await service.performQuery(query, variables: {'id': id});
    if (result.hasException) return null;
    return result.data?['getLocationDetails'] as Map<String, dynamic>?;
  }

  // ── Image picker ──────────────────────────────────────────────────────────
  Future<void> _pickImage(MemberModel member) async {
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
              leading: const Icon(Icons.camera_alt_outlined, color: Color(0xFF166534)),
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
                    setState(() => _pickedImage = cropped);
                    final bytes = await cropped.readAsBytes();
                    final base64Image = base64Encode(bytes);
                    if (mounted) {
                      context.read<MemberBloc>().add(
                        UpdateMemberDetails(
                          id: member.id,
                          name: member.name,
                          surname: member.surname,
                          phone: member.phone,
                          role: member.role,
                          bloodGroup: member.bloodGroup,
                          professionName: member.professionName,
                          locationId: member.location?.id,
                          dateOfBirth: member.dateOfBirth,
                          gender: member.gender,
                          image: base64Image,
                        ),
                      );
                    }
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: Color(0xFF166534)),
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
                    setState(() => _pickedImage = cropped);
                    final bytes = await cropped.readAsBytes();
                    final base64Image = base64Encode(bytes);
                    if (mounted) {
                      context.read<MemberBloc>().add(
                        UpdateMemberDetails(
                          id: member.id,
                          name: member.name,
                          surname: member.surname,
                          phone: member.phone,
                          role: member.role,
                          bloodGroup: member.bloodGroup,
                          professionName: member.professionName,
                          locationId: member.location?.id,
                          dateOfBirth: member.dateOfBirth,
                          gender: member.gender,
                          image: base64Image,
                        ),
                      );
                    }
                  }
                }
              },
            ),
            if (_pickedImage != null || (member.image != null && member.image!.isNotEmpty))
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _pickedImage = null);
                  if (mounted) {
                    context.read<MemberBloc>().add(
                      UpdateMemberDetails(
                        id: member.id,
                        name: member.name,
                        surname: member.surname,
                        phone: member.phone,
                        role: member.role,
                        bloodGroup: member.bloodGroup,
                        professionName: member.professionName,
                        locationId: member.location?.id,
                        dateOfBirth: member.dateOfBirth,
                        gender: member.gender,
                        image: "",
                      ),
                    );
                  }
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Phone / WhatsApp actions ───────────────────────────────────────────────
  Future<void> _launchPhoneAction(String? phone, String scheme) async {
    final cleanPhone = phone?.replaceAll(RegExp(r'\s+'), '');
    if (cleanPhone == null || cleanPhone.isEmpty) {
      _showSnack('Phone number not available');
      return;
    }
    final uri = Uri(scheme: scheme, path: cleanPhone);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showSnack(scheme == 'tel' ? 'Unable to open phone dialer' : 'Unable to open message app');
    }
  }

  Future<void> _launchWhatsApp(String? phone) async {
    if (phone == null || phone.isEmpty) {
      _showSnack('Phone number not available');
      return;
    }
    final cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final number = cleaned.startsWith('91') ? cleaned : '91$cleaned';
    final uri = Uri.parse('https://wa.me/$number');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showSnack('Unable to open WhatsApp');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  List<String> _availableRolesForCurrentUser() {
    final currentRole = context.read<AuthBloc>().state.loginData?.role.toUpperCase();
    if (currentRole == 'SUB_ADMIN') return const ['MEMBER', 'SUB_ADMIN'];
    if (currentRole == 'ADMIN' || currentRole == 'SUPER_ADMIN') return _roles;
    return const ['MEMBER'];
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

  // ── Edit bottom sheet ─────────────────────────────────────────────────────
  void _showEditMemberSheet(MemberModel member) {
    final nameController = TextEditingController(text: member.name);
    final surnameController = TextEditingController(text: member.surname ?? '');
    final phoneController = TextEditingController(text: member.phone ?? '');
    final dobController = TextEditingController(text: member.dateOfBirth ?? '');
    String? selectedGender;
    if (member.gender != null) {
      if (member.gender!.toLowerCase() == 'male') {
        selectedGender = 'Male';
      } else if (member.gender!.toLowerCase() == 'female') {
        selectedGender = 'Female';
      } else if (member.gender!.toLowerCase() == 'other') {
        selectedGender = 'Other';
      }
    }
    final memberRole = member.role?.toUpperCase();
    final isSuperAdmin = memberRole == 'SUPER_ADMIN' || memberRole == 'SUPER';
    final availableRoles = _availableRolesForCurrentUser();
    String? selectedRole;
    if (isSuperAdmin) {
      selectedRole = member.role;
    } else {
      selectedRole = availableRoles.contains(memberRole) ? memberRole : availableRoles.first;
    }
    int? selectedLocationId = member.location?.id;
    String? selectedBloodGroup = _mapBloodGroupToUi(member.bloodGroup);
    String? selectedProfession = _professions.contains(member.professionName) ? member.professionName : null;
    Future<List<LocationModel>>? locationsFuture;
    String? lastLoadedRole;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> selectDOB(BuildContext context) async {
              DateTime initialDate = DateTime(2000, 1, 1);
              if (dobController.text.isNotEmpty) {
                final parts = dobController.text.split('-');
                if (parts.length == 3) {
                  final y = int.tryParse(parts[0]);
                  final m = int.tryParse(parts[1]);
                  final d = int.tryParse(parts[2]);
                  if (y != null && m != null && d != null) {
                    initialDate = DateTime(y, m, d);
                  }
                }
              }
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: initialDate,
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
                setSheetState(() {
                  dobController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                });
              }
            }

            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (_, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        width: 40, height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Edit Profile',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(CupertinoIcons.xmark_circle_fill, color: Color(0xFF94A3B8)),
                              onPressed: () => Navigator.pop(sheetContext),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: EdgeInsets.only(
                            left: 20, right: 20, top: 20,
                            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
                          ),
                          children: [
                            _buildSheetField(label: 'Name', child: TextField(controller: nameController, decoration: _sheetInputDecoration('Enter name'))),
                            const SizedBox(height: 16),
                            _buildSheetField(label: 'Surname', child: TextField(controller: surnameController, decoration: _sheetInputDecoration('Enter surname'))),
                            const SizedBox(height: 16),
                            _buildSheetField(label: 'Phone', child: TextField(controller: phoneController, keyboardType: TextInputType.phone, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)], decoration: _sheetInputDecoration('Enter phone number'))),
                            const SizedBox(height: 16),
                            if (!isSuperAdmin) ...[
                              _buildSheetField(
                                label: 'Role',
                                child: DropdownButtonFormField<String>(
                                  value: selectedRole,
                                  isExpanded: true,
                                  decoration: _sheetInputDecoration('Select role'),
                                  items: availableRoles.map((role) => DropdownMenuItem(value: role, child: Text(role))).toList(),
                                  onChanged: (value) {
                                    if (value != selectedRole) {
                                      setSheetState(() {
                                        selectedRole = value;
                                        selectedLocationId = null;
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            _buildSheetField(
                              label: 'Blood Group',
                              child: DropdownButtonFormField<String>(
                                value: selectedBloodGroup,
                                isExpanded: true,
                                decoration: _sheetInputDecoration('Select blood group'),
                                items: _bloodGroups.map((group) => DropdownMenuItem(value: group, child: Text(group))).toList(),
                                onChanged: (value) => setSheetState(() => selectedBloodGroup = value),
                              ),
                            ),
                            const SizedBox(height: 16),
                            StatefulBuilder(
                              builder: (context, setFieldState) {
                                if (locationsFuture == null || lastLoadedRole != selectedRole) {
                                  lastLoadedRole = selectedRole;
                                  String targetType = 'STREET';
                                  if (selectedRole == 'ADMIN') {
                                    targetType = 'TALUK';
                                  } else if (selectedRole == 'SUB_ADMIN') {
                                    targetType = 'AREA';
                                  }
                                  locationsFuture = sl<LocationRepository>().getLocationList(type: targetType);
                                }
                                return _buildSheetField(
                                  label: selectedRole == 'ADMIN'
                                      ? 'Constituency'
                                      : (selectedRole == 'SUB_ADMIN' ? 'Area' : 'Street'),
                                  child: FutureBuilder<List<LocationModel>>(
                                    future: locationsFuture,
                                    builder: (context, snapshot) {
                                      final locations = snapshot.data ?? [];
                                      final hasSelected = locations.any((loc) => loc.id == selectedLocationId);
                                      return DropdownButtonFormField<int>(
                                        value: hasSelected ? selectedLocationId : null,
                                        isExpanded: true,
                                        decoration: _sheetInputDecoration(
                                          snapshot.connectionState == ConnectionState.waiting
                                              ? 'Loading...'
                                              : (selectedRole == 'ADMIN'
                                                  ? 'Select constituency'
                                                  : (selectedRole == 'SUB_ADMIN' ? 'Select area' : 'Select street')),
                                        ),
                                        items: locations.map((loc) => DropdownMenuItem(value: loc.id, child: Text(loc.name, overflow: TextOverflow.ellipsis))).toList(),
                                        onChanged: snapshot.connectionState == ConnectionState.waiting
                                            ? null
                                            : (value) {
                                                setSheetState(() => selectedLocationId = value);
                                                setFieldState(() {});
                                              },
                                      );
                                    },
                                  ),
                                );
                              }
                            ),
                            const SizedBox(height: 16),
                            _buildSheetField(
                              label: 'Profession',
                              child: DropdownButtonFormField<String>(
                                value: selectedProfession,
                                isExpanded: true,
                                decoration: _sheetInputDecoration('Select profession'),
                                items: _professions.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                                onChanged: (value) => setSheetState(() => selectedProfession = value),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildSheetField(
                              label: 'Date of Birth',
                              child: TextField(
                                controller: dobController,
                                readOnly: true,
                                onTap: () => selectDOB(context),
                                decoration: _sheetInputDecoration(
                                  'Select date of birth',
                                  suffixIcon: const Icon(CupertinoIcons.calendar, color: Color(0xFF94A3B8)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildSheetField(
                              label: 'Gender',
                              child: DropdownButtonFormField<String>(
                                value: selectedGender,
                                isExpanded: true,
                                decoration: _sheetInputDecoration('Select gender'),
                                items: const ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                                onChanged: (value) => setSheetState(() => selectedGender = value),
                              ),
                            ),
                            const SizedBox(height: 28),
                            SizedBox(
                              width: double.infinity, height: 52,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (nameController.text.trim().isEmpty) {
                                    _showSnack('Please enter name');
                                    return;
                                  }
                                  if (!Validators.isValidName(nameController.text)) {
                                    _showSnack('Name can only contain English and Tamil alphabets and spaces');
                                    return;
                                  }
                                  if (surnameController.text.trim().isNotEmpty && !Validators.isValidName(surnameController.text)) {
                                    _showSnack('Surname can only contain English and Tamil alphabets and spaces');
                                    return;
                                  }
                                  if (phoneController.text.trim().isEmpty) {
                                    _showSnack('Please enter phone number');
                                    return;
                                  }
                                  if (phoneController.text.trim().length < 10) {
                                    _showSnack('Please enter a valid 10-digit phone number');
                                    return;
                                  }
                                  context.read<MemberBloc>().add(
                                    UpdateMemberDetails(
                                      id: member.id,
                                      name: nameController.text.trim(),
                                      surname: surnameController.text.trim().isEmpty ? null : surnameController.text.trim(),
                                      phone: phoneController.text.trim(),
                                      role: selectedRole,
                                      bloodGroup: selectedBloodGroup,
                                      professionName: selectedProfession,
                                      locationId: selectedLocationId,
                                      dateOfBirth: dobController.text.trim().isEmpty ? null : dobController.text.trim(),
                                      gender: selectedGender,
                                      image: member.image,
                                    ),
                                  );
                                  Navigator.pop(sheetContext);
                                  _showSnack('Profile update submitted');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: NTKColors.primary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('SAVE CHANGES', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSheetField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B), letterSpacing: 0.3)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  InputDecoration _sheetInputDecoration(String hint, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: NTKColors.primary, width: 1.5)),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasFetched) {
      final args = ModalRoute.of(context)?.settings.arguments;
      final memberId = args is int ? args : int.tryParse(args?.toString() ?? '');
      if (memberId != null) {
        _memberId = memberId;
        context.read<MemberBloc>().add(LoadMemberDetails(id: _memberId!));
      }
      _hasFetched = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<MemberBloc, MemberState>(
      listener: (context, state) {
        if (state.selectedMember != null) {
          _resolveParentLocations(state.selectedMember!);
          final authBloc = context.read<AuthBloc>();
          final currentUserId = authBloc.state.loginData?.id;
          if (currentUserId == state.selectedMember!.id) {
            authBloc.add(LoadMeRequested());
          }
        }
      },
      builder: (context, state) {
        if (state.isLoadingDetails || _isResolvingLocation) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: const NTKAppBar(title: 'Member Profile', subtitle: 'Loading...', showNotification: false),
            body: _buildShimmerSkeleton(),
          );
        }

        if (state.detailsError != null && state.selectedMember == null) {
          return Scaffold(
            appBar: const NTKAppBar(title: 'Member Profile', subtitle: 'Error', showNotification: false),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.exclamationmark_triangle, color: theme.colorScheme.error, size: 48),
                    const SizedBox(height: 16),
                    Text('Failed to load member', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(state.detailsError!, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        if (_memberId != null) context.read<MemberBloc>().add(LoadMemberDetails(id: _memberId!));
                      },
                      style: ElevatedButton.styleFrom(minimumSize: const Size(120, 45)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final member = state.selectedMember;
        if (member == null) {
          return Scaffold(
            appBar: const NTKAppBar(title: 'Member Profile', subtitle: 'Not Found', showNotification: false),
            body: const Center(child: Text('No member data found')),
          );
        }

        final fullName = member.surname?.trim().isNotEmpty == true
            ? '${member.name} ${member.surname}'
            : member.name;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: NTKAppBar(
            title: 'Member Profile',
            subtitle: member.location?.name ?? 'Details',
            showNotification: false,
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(CupertinoIcons.settings, color: Colors.white),
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditMemberSheet(member);
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.pencil, color: Colors.black87, size: 20),
                        SizedBox(width: 8),
                        Text('Edit Profile'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // ── Top Profile Section ──────────────────────────
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Profile Avatar with camera tap
                            GestureDetector(
                              onTap: () => _pickImage(member),
                              child: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 40,
                                    backgroundColor: const Color(0xFFF1F5F9),
                                    backgroundImage: _pickedImage != null
                                        ? FileImage(_pickedImage!)
                                        : null,
                                    child: (_pickedImage == null)
                                        ? ClipOval(child: _buildProfileImage(member.image, member.name))
                                        : null,
                                  ),
                                  // Camera badge
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: NTKColors.primary,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                      child: const Icon(Icons.camera_alt, size: 12, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Name + role + phone — all overflow-safe
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Name row — overflow fixed with Flexible
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          fullName,
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1E293B),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFDBEAFE),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          _roleLabel(member.role),
                                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Phone row only — message icon & email row removed
                                  Row(
                                    children: [
                                      const Icon(Icons.phone, size: 15, color: Color(0xFF166534)),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          member.phone ?? 'N/A',
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // ── Basic Information (Member ID hidden) ─────────
                        _buildInfoCard(
                          title: 'Basic Information',
                          children: [
                            _buildInfoRow('Blood Group', member.bloodGroup ?? '—'),
                            _buildInfoRow('Profession', member.professionName ?? '—'),
                            _buildInfoRow('Date of Birth', member.dateOfBirth ?? '—'),
                            _buildInfoRow('Gender', member.gender ?? '—', isLast: true),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // ── Location Details ─────────────────────────────
                        Builder(
                          builder: (context) {
                            final street = _resolvedStreet ?? member.location?.name ?? '—';
                            final area = _resolvedArea ?? '—';
                            final constituency = _resolvedConstituency ?? '—';
                            final district = _resolvedDistrict ?? '—';

                            final role = member.role?.toUpperCase();
                            final showArea = role != 'ADMIN';
                            final showStreet = role != 'ADMIN' && role != 'SUB_ADMIN';

                            return _buildInfoCard(
                              title: 'Location Details',
                              children: [
                                _buildInfoRow('District', district),
                                _buildInfoRow('Constituency', constituency, isLast: !showArea && !showStreet),
                                if (showArea)
                                  _buildInfoRow('Area', area, isLast: showArea && !showStreet),
                                if (showStreet)
                                  _buildInfoRow('Street', street, isLast: true),
                              ],
                            );
                          }
                        ),
                        const SizedBox(height: 16),

                        // ── Added By ─────────────────────────────────────
                        _buildInfoCard(
                          title: 'Added By',
                          children: [
                            _buildInfoRow('Added By', member.addedBy ?? 'Self'),
                            _buildInfoRow(
                              'Added On',
                              member.createdAt != null
                                  ? '${member.createdAt!.day.toString().padLeft(2, '0')} ${_monthName(member.createdAt!.month)} ${member.createdAt!.year}'
                                  : '—',
                              isLast: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // ── Actions ──────────────────────────────────────
                        _buildInfoCard(
                          title: 'Actions',
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _launchPhoneAction(member.phone, 'tel'),
                                      icon: const Icon(Icons.phone, size: 18, color: Colors.white),
                                      label: const Text('Call', style: TextStyle(color: Colors.white)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF064E3B),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _launchWhatsApp(member.phone),
                                      icon: const Icon(Icons.wechat_rounded, size: 18, color: Colors.white),
                                      label: const Text('WhatsApp', style: TextStyle(color: Colors.white)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF25D366),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _buildInitials(String? name) {
    return Container(
      color: const Color(0xFFF1F5F9),
      alignment: Alignment.center,
      child: Text(
        name != null && name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: NTKColors.primary),
      ),
    );
  }

  Widget? _buildProfileImage(String? imagePath, String name) {
    if (imagePath == null || imagePath.isEmpty) return _buildInitials(name);
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildInitials(name),
      );
    }
    try {
      final clean = imagePath.contains('base64,')
          ? imagePath.substring(imagePath.indexOf('base64,') + 7)
          : imagePath;
      return AsyncBase64Image(
        base64String: clean,
        fit: BoxFit.cover,
        placeholderBuilder: (_) => _buildInitials(name),
        errorBuilder: (_, __, ___) => _buildInitials(name),
      );
    } catch (_) {
      return _buildInitials(name);
    }
  }

  String _roleLabel(String? role) {
    switch (role?.toUpperCase()) {
      case 'ADMIN':       return 'ADMIN';
      case 'SUB_ADMIN':   return 'SUB ADM';
      case 'SUPER_ADMIN':
      case 'SUPER':       return 'SUPER';
      default:            return 'MEMBER';
    }
  }

  String _monthName(int month) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[(month - 1).clamp(0, 11)];
  }

  Widget _buildInfoCard({required String title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF0FDF4),
              borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String key, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: isLast ? 12 : 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              key,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerSkeleton() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                const ShimmerLoader(width: 80, height: 80, borderRadius: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      ShimmerLoader(width: 180, height: 20),
                      SizedBox(height: 12),
                      ShimmerLoader(width: 120, height: 16),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildShimmerCard(4),
            const SizedBox(height: 16),
            _buildShimmerCard(4),
            const SizedBox(height: 16),
            _buildShimmerCard(2),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerCard(int rows) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF0FDF4),
              borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: const ShimmerLoader(width: 120, height: 18),
            alignment: Alignment.centerLeft,
          ),
          for (int i = 0; i < rows; i++)
            Padding(
              padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: (i == rows - 1) ? 12 : 0),
              child: const Row(
                children: [
                  Expanded(flex: 2, child: ShimmerLoader(width: double.infinity, height: 14)),
                  SizedBox(width: 16),
                  Expanded(flex: 3, child: ShimmerLoader(width: double.infinity, height: 14)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
