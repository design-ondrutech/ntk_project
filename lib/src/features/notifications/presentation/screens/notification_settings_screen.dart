import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/core/theme/app_theme.dart';
import 'package:ntk_project/src/core/widgets/ntk_app_bar.dart';
import 'package:ntk_project/src/features/notifications/presentation/bloc/notification_settings_bloc.dart';
import 'package:ntk_project/src/features/notifications/presentation/bloc/notification_settings_event.dart';
import 'package:ntk_project/src/features/notifications/presentation/bloc/notification_settings_state.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationSettingsBloc>().add(FetchNotificationSettings());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NTKColors.background,
      appBar: const NTKAppBar(
        title: 'Settings',
        subtitle: 'Notification Preferences',
        showNotification: false,
      ),
      body: BlocConsumer<NotificationSettingsBloc, NotificationSettingsState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.isLoading && state.settings.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Alert Types'),
                _buildSettingsCard([
                  _buildToggle(
                    'Event Notifications',
                    Icons.calendar_month,
                    state.settings['events'] ?? true,
                    (v) => context.read<NotificationSettingsBloc>().add(
                      ToggleNotificationSetting('events', v),
                    ),
                  ),
                  _buildToggle(
                    'Community Notifications',
                    Icons.people_outline,
                    state.settings['community'] ?? true,
                    (v) => context.read<NotificationSettingsBloc>().add(
                      ToggleNotificationSetting('community', v),
                    ),
                  ),
                  _buildToggle(
                    'Emergency Alerts',
                    Icons.campaign,
                    state.settings['emergency'] ?? true,
                    (v) => context.read<NotificationSettingsBloc>().add(
                      ToggleNotificationSetting('emergency', v),
                    ),
                    isDestructive: true,
                  ),
                  _buildToggle(
                    'Approval Notifications',
                    Icons.check_circle_outline,
                    state.settings['approval'] ?? true,
                    (v) => context.read<NotificationSettingsBloc>().add(
                      ToggleNotificationSetting('approval', v),
                    ),
                  ),
                  _buildToggle(
                    'Poll Notifications',
                    Icons.poll,
                    state.settings['poll'] ?? true,
                    (v) => context.read<NotificationSettingsBloc>().add(
                      ToggleNotificationSetting('poll', v),
                    ),
                  ),
                  _buildToggle(
                    'Broadcast Notifications',
                    Icons.podcasts,
                    state.settings['broadcast'] ?? true,
                    (v) => context.read<NotificationSettingsBloc>().add(
                      ToggleNotificationSetting('broadcast', v),
                    ),
                  ),
                ]),
                const SizedBox(height: 24),
                _buildSectionTitle('Device Preferences'),
                _buildSettingsCard([
                  _buildToggle(
                    'Sound',
                    Icons.volume_up,
                    state.settings['sound'] ?? true,
                    (v) => context.read<NotificationSettingsBloc>().add(
                      ToggleNotificationSetting('sound', v),
                    ),
                  ),
                  _buildToggle(
                    'Vibration',
                    Icons.vibration,
                    state.settings['vibration'] ?? true,
                    (v) => context.read<NotificationSettingsBloc>().add(
                      ToggleNotificationSetting('vibration', v),
                    ),
                  ),
                ]),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8, top: 16),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildToggle(
    String title,
    IconData icon,
    bool value,
    Function(bool) onChanged, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive
              ? Colors.red.withOpacity(0.1)
              : NTKColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isDestructive ? Colors.red : NTKColors.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: NTKColors.primary,
      ),
    );
  }
}
