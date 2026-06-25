import 'package:flutter/material.dart';
import 'package:ntk_project/src/features/community/data/models/community_model.dart';
import 'package:ntk_project/src/core/theme/app_theme.dart';
import 'package:ntk_project/src/features/community/presentation/screens/tabs/discussion_tab.dart';
import 'package:ntk_project/src/features/community/presentation/screens/tabs/members_tab.dart';
import 'package:ntk_project/src/features/community/presentation/screens/tabs/about_tab.dart';
import 'package:ntk_project/src/features/community/presentation/screens/community_admin_screen.dart';
import 'package:ntk_project/src/features/community/presentation/screens/community_settings_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/injection_container.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/settings/community_settings_bloc.dart';

class CommunityDetailsScreen extends StatefulWidget {
  final CommunityModel community;

  const CommunityDetailsScreen({Key? key, required this.community}) : super(key: key);

  @override
  State<CommunityDetailsScreen> createState() => _CommunityDetailsScreenState();
}

class _CommunityDetailsScreenState extends State<CommunityDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: const Color(0xFF0A3D28),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        title: Row(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.groups_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.community.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.community.memberCount} Members',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings_rounded),
            tooltip: 'Admin Dashboard',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CommunityAdminScreen(community: widget.community),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Community Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider(
                    create: (_) => sl<CommunitySettingsBloc>(),
                    child: CommunitySettingsScreen(communityId: widget.community.id),
                  ),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelColor: Colors.white54,
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
          tabs: const [
            Tab(text: 'Discussion'),
            Tab(text: 'Members'),
            Tab(text: 'About'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          DiscussionTab(community: widget.community),
          MembersTab(community: widget.community),
          AboutTab(community: widget.community),
        ],
      ),
    );
  }
}
