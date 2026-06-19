import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/features/community/data/models/community_model.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/community_member_bloc.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/community_member_event.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/community_member_state.dart';
import 'package:ntk_project/src/core/utils/date_helper.dart';

class MembersTab extends StatefulWidget {
  final CommunityModel community;

  const MembersTab({Key? key, required this.community}) : super(key: key);

  @override
  State<MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends State<MembersTab> {
  @override
  void initState() {
    super.initState();
    context.read<CommunityMemberBloc>().add(FetchCommunityMembers(communityId: widget.community.id));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CommunityMemberBloc, CommunityMemberState>(
      builder: (context, state) {
        if (state.isLoading && state.members.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.error != null && state.members.isEmpty) {
          return Center(child: Text(state.error!));
        }
        if (state.members.isEmpty) {
          return const Center(child: Text("No members found."));
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          itemCount: state.members.length,
          itemBuilder: (context, index) {
            final member = state.members[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE7ECE9)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F8F7),
                      borderRadius: BorderRadius.circular(14),
                      image: member.image != null
                          ? DecorationImage(
                              image: NetworkImage(member.image!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: member.image == null
                        ? const Icon(Icons.person_rounded, color: Color(0xFF667085), size: 24)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.name,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF111827)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Joined ${member.joinedAt != null ? DateHelper.formatDateTime(member.joinedAt!) : 'Recently'}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF667085), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  _buildRoleBadge(member.role ?? (member.isGroupAdmin ? 'ADMIN' : 'MEMBER')),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRoleBadge(String role) {
    Color bgColor;
    Color textColor;
    switch (role.toUpperCase()) {
      case 'ADMIN':
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFFDC2626);
        break;
      case 'MODERATOR':
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFFD97706);
        break;
      default:
        bgColor = const Color(0xFFF3F4F6);
        textColor = const Color(0xFF4B5563);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
