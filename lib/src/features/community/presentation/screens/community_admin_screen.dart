import 'package:flutter/material.dart';
import 'package:ntk_project/src/features/community/data/models/community_model.dart';
import 'package:ntk_project/src/core/widgets/ntk_app_bar.dart';
import 'package:ntk_project/src/features/community/presentation/screens/community_settings_screen.dart';
import 'package:ntk_project/src/features/community/presentation/screens/community_analytics_screen.dart';
import 'package:ntk_project/src/features/community/presentation/screens/community_ban_list_screen.dart';
import 'package:ntk_project/src/features/community/presentation/screens/community_join_requests_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/injection_container.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/admin/community_admin_bloc.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/settings/community_settings_bloc.dart';

class CommunityAdminScreen extends StatelessWidget {
  final CommunityModel community;

  const CommunityAdminScreen({Key? key, required this.community}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      appBar: NTKAppBar(
        title: 'Admin Dashboard',
        subtitle: community.name,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildAdminCard(
            context,
            icon: Icons.person_add_alt_1_rounded,
            title: 'Join Requests',
            subtitle: 'Review pending join requests',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider(
                    create: (_) => sl<CommunityAdminBloc>(),
                    child: CommunityJoinRequestsScreen(communityId: community.id),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildAdminCard(
            context,
            icon: Icons.bar_chart_rounded,
            title: 'Analytics',
            subtitle: 'View community growth and engagement',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider(
                    create: (_) => sl<CommunityAdminBloc>(),
                    child: CommunityAnalyticsScreen(communityId: community.id),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildAdminCard(
            context,
            icon: Icons.block_rounded,
            title: 'Ban List',
            subtitle: 'Manage banned members',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider(
                    create: (_) => sl<CommunityAdminBloc>(),
                    child: CommunityBanListScreen(communityId: community.id),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildAdminCard(
            context,
            icon: Icons.settings_rounded,
            title: 'Settings',
            subtitle: 'Change community settings',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider(
                    create: (_) => sl<CommunitySettingsBloc>(),
                    child: CommunitySettingsScreen(communityId: community.id),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdminCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE7ECE9)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0A3D28).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF0A3D28)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle, style: const TextStyle(color: Color(0xFF667085))),
        trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
        onTap: onTap,
      ),
    );
  }
}
