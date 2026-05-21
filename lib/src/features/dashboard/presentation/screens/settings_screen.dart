import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:ntk_project/src/core/theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSectionHeader('ACCOUNT'),
          _buildSettingTile(
            context,
            icon: CupertinoIcons.person,
            title: 'Edit Profile',
            subtitle: 'Update your name, photo, and bio',
            onTap: () {},
          ),
          _buildSettingTile(
            context,
            icon: CupertinoIcons.lock,
            title: 'Security',
            subtitle: 'Change password and 2FA',
            onTap: () {},
          ),
          
          const SizedBox(height: 32),
          _buildSectionHeader('PREFERENCES'),
          _buildSettingTile(
            context,
            icon: CupertinoIcons.bell,
            title: 'Notifications',
            subtitle: 'Configure alerts and updates',
            onTap: () {},
          ),
          _buildSettingTile(
            context,
            icon: CupertinoIcons.globe,
            title: 'Language',
            subtitle: 'Tamil, English',
            onTap: () {},
          ),
          _buildSettingTile(
            context,
            icon: CupertinoIcons.moon,
            title: 'Appearance',
            subtitle: 'Light, Dark, System',
            onTap: () {},
          ),

          const SizedBox(height: 32),
          _buildSectionHeader('SUPPORT'),
          _buildSettingTile(
            context,
            icon: CupertinoIcons.question_circle,
            title: 'Help Center',
            onTap: () {},
          ),
          _buildSettingTile(
            context,
            icon: CupertinoIcons.info_circle,
            title: 'About App',
            onTap: () {},
          ),
          
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error.withOpacity(0.1),
              foregroundColor: theme.colorScheme.error,
              elevation: 0,
            ),
            child: const Text('LOGOUT'),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
          color: NTKColors.textTertiary,
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 20),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(fontSize: 15),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
              )
            : null,
        trailing: const Icon(CupertinoIcons.chevron_right, size: 14, color: NTKColors.textTertiary),
        onTap: onTap,
      ),
    );
  }
}
