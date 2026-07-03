import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ntk_project/src/core/theme/app_theme.dart';
import 'package:ntk_project/src/core/widgets/image_crop_dialog.dart';
import 'package:ntk_project/src/core/widgets/ntk_app_bar.dart';
import 'package:ntk_project/src/core/widgets/ntk_snackbar.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/community_bloc.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/community_event.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/community_state.dart';
import 'package:ntk_project/src/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_bloc.dart';

const _primary = Color(0xFF0A3D28);
const _bg = Color(0xFFF6F8F7);

class CreateCommunityGroupScreen extends StatefulWidget {
  const CreateCommunityGroupScreen({super.key});

  @override
  State<CreateCommunityGroupScreen> createState() =>
      _CreateCommunityGroupScreenState();
}

class _CreateCommunityGroupScreenState extends State<CreateCommunityGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  File? _pickedImage;
  final _imagePicker = ImagePicker();

  bool _allowMemberMessages = true;
  String _privacyType = 'PUBLIC';

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  int? get _locationId {
    final globalLoc = context.read<DashboardBloc>().state.globalLocation;
    final auth = context.read<AuthBloc>().state.loginData;
    return globalLoc?.id ?? auth?.locationId;
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
              'Choose Group Photo',
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
                    });
                  }
                }
              },
            ),
            if (_pickedImage != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _pickedImage = null;
                  });
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      String? base64Image;
      if (_pickedImage != null) {
        final bytes = _pickedImage!.readAsBytesSync();
        base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      }

      context.read<CommunityBloc>().add(
            CreateCommunity(
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim(),
              image: base64Image,
              allowMemberMessages: _allowMemberMessages,
              privacyType: _privacyType,
              locationId: _locationId,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CommunityBloc, CommunityState>(
      listenWhen: (prev, curr) =>
          prev.isLoading != curr.isLoading ||
          prev.message != curr.message ||
          prev.error != curr.error,
      listener: (context, state) {
        if (!state.isLoading && state.error == null && state.message == 'Community created successfully') {
          Navigator.pop(context); // Go back to community feed
        }
      },
      child: Scaffold(
        backgroundColor: _bg,
        appBar: NTKAppBar(
          title: AppLocalizations.of(context)!.createCommunityGroup,
          subtitle: AppLocalizations.of(context)!.createNewGroupDesc,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(AppLocalizations.of(context)!.groupDetails),
                const SizedBox(height: 24),
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: NTKColors.slate200,
                          backgroundImage: _pickedImage != null ? FileImage(_pickedImage!) : null,
                          child: _pickedImage == null
                              ? const Icon(Icons.groups, size: 48, color: NTKColors.slate400)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: NTKColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.groupName,
                    hintText: 'e.g. Environmental Activists',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: NTKColors.slate200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: NTKColors.slate200),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a group name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.description,
                    hintText: 'What is this group about?',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: NTKColors.slate200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: NTKColors.slate200),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _buildSectionTitle(AppLocalizations.of(context)!.settings),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: NTKColors.slate200),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: DropdownButtonFormField<String>(
                          value: _privacyType,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.privacyType,
                            border: InputBorder.none,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'PUBLIC',
                              child: Text(AppLocalizations.of(context)!.publicAnyoneJoin),
                            ),
                            DropdownMenuItem(
                              value: 'PRIVATE',
                              child: Text(AppLocalizations.of(context)!.privateInviteOnly),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _privacyType = value;
                              });
                            }
                          },
                        ),
                      ),
                      const Divider(height: 1, color: NTKColors.slate200),
                      SwitchListTile(
                        activeColor: _primary,
                        title: Text(AppLocalizations.of(context)!.allowMemberMessages),
                        subtitle: Text(AppLocalizations.of(context)!.allowMemberMessagesDesc),
                        value: _allowMemberMessages,
                        onChanged: (value) {
                          setState(() {
                            _allowMemberMessages = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: BlocBuilder<CommunityBloc, CommunityState>(
                    builder: (context, state) {
                      return ElevatedButton(
                        onPressed: state.isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: state.isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Create Group',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        color: NTKColors.textPrimary,
      ),
    );
  }
}
