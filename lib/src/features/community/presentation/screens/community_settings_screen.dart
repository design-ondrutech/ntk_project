import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/core/widgets/ntk_app_bar.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/settings/community_settings_bloc.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/settings/community_settings_event.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/settings/community_settings_state.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/admin/community_admin_bloc.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/admin/community_admin_event.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/admin/community_admin_state.dart';

class CommunitySettingsScreen extends StatefulWidget {
  final int communityId;

  const CommunitySettingsScreen({Key? key, required this.communityId}) : super(key: key);

  @override
  State<CommunitySettingsScreen> createState() => _CommunitySettingsScreenState();
}

class _CommunitySettingsScreenState extends State<CommunitySettingsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CommunitySettingsBloc>().add(FetchCommunitySettingsEvent(widget.communityId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      appBar: const NTKAppBar(
        title: 'Community Settings',
        subtitle: 'Manage group preferences',
      ),
      body: BlocListener<CommunityAdminBloc, CommunityAdminState>(
        listener: (context, adminState) {
          if (adminState.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(adminState.error!)));
          }
          if (adminState.isArchivedSuccessfully || adminState.isDeletedSuccessfully) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Community deleted successfully')));
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        },
        child: BlocConsumer<CommunitySettingsBloc, CommunitySettingsState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error!)),
            );
          }
          if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.successMessage!)),
            );
          }
        },
        builder: (context, state) {
          if (state.isLoading && state.settings == null) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF0A3D28)));
          }
          
          final settings = state.settings;
          if (settings == null) {
            return const Center(child: Text('Settings not found.'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSwitchTile(
                title: 'Enable Notifications',
                subtitle: 'Receive alerts for new messages',
                value: settings.notificationsEnabled,
                onChanged: (val) {
                  context.read<CommunitySettingsBloc>().add(UpdateCommunitySettingsEvent(
                    widget.communityId,
                    settings.copyWith(notificationsEnabled: val),
                  ));
                },
              ),
              _buildSwitchTile(
                title: 'Auto-download Media',
                subtitle: 'Automatically download images and videos',
                value: settings.mediaAutoDownload,
                onChanged: (val) {
                  context.read<CommunitySettingsBloc>().add(UpdateCommunitySettingsEvent(
                    widget.communityId,
                    settings.copyWith(mediaAutoDownload: val),
                  ));
                },
              ),
              _buildSwitchTile(
                title: 'Enable Links & Docs',
                subtitle: 'Allow sharing links and documents in chat',
                value: settings.linksAndDocsEnabled,
                onChanged: (val) {
                  context.read<CommunitySettingsBloc>().add(UpdateCommunitySettingsEvent(
                    widget.communityId,
                    settings.copyWith(linksAndDocsEnabled: val),
                  ));
                },
              ),
              _buildSwitchTile(
                title: 'Enable Starred Messages',
                subtitle: 'Allow users to star important messages',
                value: settings.starredMessagesEnabled,
                onChanged: (val) {
                  context.read<CommunitySettingsBloc>().add(UpdateCommunitySettingsEvent(
                    widget.communityId,
                    settings.copyWith(starredMessagesEnabled: val),
                  ));
                },
              ),
              _buildSwitchTile(
                title: 'Mute Group',
                subtitle: 'Mute all notifications from this group',
                value: settings.muted,
                onChanged: (val) {
                  context.read<CommunitySettingsBloc>().add(UpdateCommunitySettingsEvent(
                    widget.communityId,
                    settings.copyWith(muted: val),
                  ));
                },
              ),
              const SizedBox(height: 24),
              _buildDeleteButton(context),
            ],
          );
        },
      ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile(
        activeColor: const Color(0xFF0F8A4B),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    return BlocBuilder<CommunityAdminBloc, CommunityAdminState>(
      builder: (context, adminState) {
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade50,
            foregroundColor: Colors.red,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.red),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: adminState.isDeleting ? null : () => _confirmDelete(context),
          child: adminState.isDeleting 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.red, strokeWidth: 2))
              : const Text('Delete Community', style: TextStyle(fontWeight: FontWeight.bold)),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Community', style: TextStyle(color: Colors.red)),
        content: const Text('Are you sure you want to delete this community? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<CommunityAdminBloc>().add(DeleteCommunityGroupEvent(widget.communityId));
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
