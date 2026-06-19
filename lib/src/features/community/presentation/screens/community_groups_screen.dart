import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/features/community/data/models/community_model.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/community_list_bloc.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/community_list_event.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/community_list_state.dart';
import 'package:ntk_project/src/features/community/presentation/screens/community_chat_screen.dart';
import 'package:ntk_project/src/features/community/presentation/screens/community_details_screen.dart';
import 'package:ntk_project/src/core/widgets/ntk_app_bar.dart';

const _primary = Color(0xFF0A3D28);
const _secondary = Color(0xFF0F8A4B);
const _bg = Color(0xFFF6F8F7);
const _line = Color(0xFFE7ECE9);
const _text = Color(0xFF111827);
const _muted = Color(0xFF667085);

class CommunityGroupsScreen extends StatefulWidget {
  const CommunityGroupsScreen({super.key});

  @override
  State<CommunityGroupsScreen> createState() => _CommunityGroupsScreenState();
}

class _CommunityGroupsScreenState extends State<CommunityGroupsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CommunityListBloc>().add(FetchCommunitiesList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: const NTKAppBar(
        title: 'Community Groups',
        subtitle: 'Nagapattinam local networks',
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: BlocBuilder<CommunityListBloc, CommunityListState>(
                builder: (context, state) {
                  if (state.isLoading && state.communities.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(color: _primary),
                    );
                  }
                  final communities = state.communities;
                  return RefreshIndicator(
                    color: _primary,
                    onRefresh: () async {
                      context.read<CommunityListBloc>().add(
                        FetchCommunitiesList(),
                      );
                    },
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          sliver: SliverToBoxAdapter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _SearchField(),
                                const SizedBox(height: 18),
                                if (communities.isEmpty) ...[
                                  const SizedBox(height: 40),
                                  const Center(
                                    child: Text('No groups found.', style: TextStyle(color: _muted)),
                                  ),
                                ] else if (communities.where((c) => c.isJoined).isNotEmpty) ...[
                                  const _SectionHeader(title: 'Your Groups', action: 'View All'),
                                  const SizedBox(height: 10),
                                ],
                              ],
                            ),
                          ),
                        ),
                        if (communities.where((c) => c.isJoined).isNotEmpty)
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            sliver: SliverList.builder(
                              itemCount: communities.where((c) => c.isJoined).length,
                              itemBuilder: (context, index) {
                                final group = communities.where((c) => c.isJoined).elementAt(index);
                                return _GroupCard(group: group, joined: true);
                              },
                            ),
                          ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                          sliver: SliverToBoxAdapter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (communities.where((c) => !c.isJoined).isNotEmpty) ...[
                                  const _SectionHeader(title: 'More Groups'),
                                  const SizedBox(height: 10),
                                ],
                              ],
                            ),
                          ),
                        ),
                        if (communities.where((c) => !c.isJoined).isNotEmpty)
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            sliver: SliverList.builder(
                              itemCount: communities.where((c) => !c.isJoined).length,
                              itemBuilder: (context, index) {
                                final group = communities.where((c) => !c.isJoined).elementAt(index);
                                return _GroupCard(group: group, joined: false);
                              },
                            ),
                          ),
                        const SliverPadding(padding: EdgeInsets.only(bottom: 28)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search Groups',
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _line),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action});

  final String title;
  final String? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: _text,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (action != null)
          Text(
            action!,
            style: const TextStyle(
              color: _secondary,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
      ],
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group, required this.joined});

  final CommunityModel group;
  final bool joined;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CommunityDetailsScreen(community: group),
            ),
          );
        },
        child: Row(
          children: [
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: _avatarTint(group.name),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(_groupIcon(group.name), color: _primary, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _text,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${group.memberCount} Members',
                    style: const TextStyle(
                      color: _muted,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            joined ? const _StatusBadge() : _JoinButton(communityId: group.id),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6EF),
        borderRadius: BorderRadius.circular(99),
      ),
      child: const Text(
        'Joined',
        style: TextStyle(
          color: _secondary,
          fontWeight: FontWeight.w900,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _JoinButton extends StatelessWidget {
  const _JoinButton({required this.communityId});
  
  final int communityId;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: OutlinedButton(
        onPressed: () {
          context.read<CommunityListBloc>().add(
            JoinCommunityGroup(communityId: communityId),
          );
        },
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 36),
          foregroundColor: _primary,
          side: const BorderSide(color: Color(0xFFB8C9C1)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Join',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

IconData _groupIcon(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('doctor')) return Icons.medical_services_outlined;
  if (lower.contains('farmer')) return Icons.agriculture_outlined;
  if (lower.contains('teacher')) return Icons.menu_book_outlined;
  if (lower.contains('lawyer')) return Icons.balance_outlined;
  if (lower.contains('women')) return Icons.diversity_3_outlined;
  if (lower.contains('police')) return Icons.local_police_outlined;
  if (lower.contains('business')) return Icons.business_center_outlined;
  return Icons.groups_rounded;
}

Color _avatarTint(String name) {
  final colors = [
    const Color(0xFFDFF7E8),
    const Color(0xFFFFEAC2),
    const Color(0xFFEDE4FF),
    const Color(0xFFDDF0FF),
  ];
  return colors[name.length % colors.length];
}

