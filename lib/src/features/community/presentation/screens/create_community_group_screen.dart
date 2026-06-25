import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/core/theme/app_theme.dart';
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

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<CommunityBloc>().add(
            CreateCommunity(
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim(),
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
        appBar: const NTKAppBar(
          title: 'Create Community Group',
          subtitle: 'Create a new group for your location',
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Group Details'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Group Name',
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
                    labelText: 'Description',
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
                _buildSectionTitle('Settings'),
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
                          decoration: const InputDecoration(
                            labelText: 'Privacy Type',
                            border: InputBorder.none,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'PUBLIC',
                              child: Text('Public (Anyone can join)'),
                            ),
                            DropdownMenuItem(
                              value: 'PRIVATE',
                              child: Text('Private (Invite Only)'),
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
                        title: const Text('Allow Member Messages'),
                        subtitle: const Text('Members can send messages in the group'),
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
