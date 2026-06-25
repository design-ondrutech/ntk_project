import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/core/widgets/ntk_app_bar.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/settings/community_settings_bloc.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/settings/community_settings_event.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/settings/community_settings_state.dart';

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
      body: BlocConsumer<CommunitySettingsBloc, CommunitySettingsState>(
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
            ],
          );
        },
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
}
