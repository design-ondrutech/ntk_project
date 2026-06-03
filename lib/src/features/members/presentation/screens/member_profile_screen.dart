import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ntk_project/src/core/theme/app_theme.dart';
import 'package:ntk_project/src/core/widgets/ntk_app_bar.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ntk_project/src/features/location/data/models/location_model.dart';
import 'package:ntk_project/src/features/location/domain/repositories/location_repository.dart';
import 'package:ntk_project/src/features/members/data/models/member_model.dart';
import 'package:ntk_project/src/features/members/presentation/bloc/member_bloc.dart';
import 'package:ntk_project/src/features/members/presentation/bloc/member_event.dart';
import 'package:ntk_project/src/features/members/presentation/bloc/member_state.dart';
import 'package:ntk_project/src/injection_container.dart';
import 'package:url_launcher/url_launcher.dart';

class MemberProfileScreen extends StatefulWidget {
  const MemberProfileScreen({super.key});

  @override
  State<MemberProfileScreen> createState() => _MemberProfileScreenState();
}

class _MemberProfileScreenState extends State<MemberProfileScreen> {
  int? _memberId;
  bool _hasFetched = false;

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

  // ── Image picker ──────────────────────────────────────────────────────────
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
              leading: const Icon(Icons.camera_alt_outlined, color: Color(0xFF166534)),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                final picked = await _imagePicker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 80,
                );
                if (picked != null && mounted) {
                  setState(() => _pickedImage = File(picked.path));
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
                  setState(() => _pickedImage = File(picked.path));
                }
              },
            ),
            if (_pickedImage != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _pickedImage = null);
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

  // ── Edit bottom sheet ─────────────────────────────────────────────────────
  void _showEditMemberSheet(MemberModel member) {
    final nameController = TextEditingController(text: member.name);
    final surnameController = TextEditingController(text: member.surname ?? '');
    final phoneController = TextEditingController(text: member.phone ?? '');
    final availableRoles = _availableRolesForCurrentUser();
    final memberRole = member.role?.toUpperCase();
    String? selectedRole = availableRoles.contains(memberRole) ? memberRole : availableRoles.first;
    int? selectedLocationId = member.location?.id;
    String? selectedBloodGroup = _bloodGroups.contains(member.bloodGroup) ? member.bloodGroup : null;
    String? selectedProfession = _professions.contains(member.professionName) ? member.professionName : null;
    final locationsFuture = sl<LocationRepository>().getLocationList(type: 'STREET');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
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
                            _buildSheetField(
                              label: 'Role',
                              child: DropdownButtonFormField<String>(
                                value: selectedRole,
                                isExpanded: true,
                                decoration: _sheetInputDecoration('Select role'),
                                items: availableRoles.map((role) => DropdownMenuItem(value: role, child: Text(role))).toList(),
                                onChanged: (value) => setSheetState(() => selectedRole = value),
                              ),
                            ),
                            const SizedBox(height: 16),
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
                            _buildSheetField(
                              label: 'Location',
                              child: FutureBuilder<List<LocationModel>>(
                                future: locationsFuture,
                                builder: (context, snapshot) {
                                  final locations = snapshot.data ?? [];
                                  final hasSelected = locations.any((loc) => loc.id == selectedLocationId);
                                  return DropdownButtonFormField<int>(
                                    value: hasSelected ? selectedLocationId : null,
                                    isExpanded: true,
                                    decoration: _sheetInputDecoration(
                                      snapshot.connectionState == ConnectionState.waiting ? 'Loading...' : 'Select location',
                                    ),
                                    items: locations.map((loc) => DropdownMenuItem(value: loc.id, child: Text(loc.name, overflow: TextOverflow.ellipsis))).toList(),
                                    onChanged: snapshot.connectionState == ConnectionState.waiting
                                        ? null
                                        : (value) => setSheetState(() => selectedLocationId = value),
                                  );
                                },
                              ),
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
                            const SizedBox(height: 28),
                            SizedBox(
                              width: double.infinity, height: 52,
                              child: ElevatedButton(
                                onPressed: () {
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

  InputDecoration _sheetInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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

    return BlocBuilder<MemberBloc, MemberState>(
      builder: (context, state) {
        if (state.isLoadingDetails && state.selectedMember == null) {
          return Scaffold(
            appBar: const NTKAppBar(title: 'Member Profile', subtitle: 'Loading...', showNotification: false),
            body: const Center(child: CircularProgressIndicator()),
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
              IconButton(
                icon: const Icon(CupertinoIcons.add_circled, color: Colors.white),
                onPressed: () => _showEditMemberSheet(member),
              ),
            ],
          ),
          body: Column(
            children: [
              if (state.isLoadingDetails)
                LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(NTKColors.primary),
                  minHeight: 2,
                ),
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
                              onTap: _pickImage,
                              child: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 40,
                                    backgroundColor: const Color(0xFFF1F5F9),
                                    backgroundImage: _pickedImage != null
                                        ? FileImage(_pickedImage!)
                                        : null,
                                    child: _pickedImage == null
                                        ? Text(
                                            member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: NTKColors.primary),
                                          )
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
                            _buildInfoRow('Date of Birth', '—'),
                            _buildInfoRow('Gender', '—', isLast: true),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // ── Location Details ─────────────────────────────
                        _buildInfoCard(
                          title: 'Location Details',
                          children: [
                            _buildInfoRow('District', member.location?.type == 'DISTRICT' ? member.location!.name : '—'),
                            _buildInfoRow('Constituency', member.location?.type == 'CONSTITUENCY' ? member.location!.name : '—'),
                            _buildInfoRow('Area', member.location?.type == 'AREA' ? member.location!.name : '—'),
                            _buildInfoRow('Street', member.location?.type == 'STREET' ? member.location!.name : (member.location?.name ?? '—'), isLast: true),
                          ],
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

  String _roleLabel(String? role) {
    switch (role?.toUpperCase()) {
      case 'ADMIN':       return 'ADMIN';
      case 'SUB_ADMIN':   return 'SUB ADM';
      case 'SUPER_ADMIN': return 'SUPER';
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
}
