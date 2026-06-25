import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/features/community/data/models/community_model.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/community_list_bloc.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/community_list_event.dart';
import 'package:ntk_project/src/core/utils/date_helper.dart';
import 'package:ntk_project/src/features/community/presentation/screens/community_links_screen.dart';
import 'package:ntk_project/l10n/app_localizations.dart';

class AboutTab extends StatelessWidget {
  final CommunityModel community;

  const AboutTab({Key? key, required this.community}) : super(key: key);

  void _showLeaveConfirmation(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext bottomSheetContext) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Leave Group?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Are you sure you want to leave this community? You will no longer receive updates or be able to post.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(bottomSheetContext),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel', style: TextStyle(color: Colors.black)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<CommunityListBloc>().add(LeaveCommunityGroup(communityId: community.id));
                        Navigator.pop(bottomSheetContext); // close bottom sheet
                        Navigator.pop(context); // close details screen
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Leave Group', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showJoinDialog(BuildContext context) {
    final inputController = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    final isSecret = community.privacyType == 'SECRET';
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isSecret ? l10n.joinSecretGroup : l10n.joinPrivateGroup, style: const TextStyle(color: Color(0xFF0A3D28), fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isSecret ? l10n.enterInviteCode : l10n.provideReason),
            const SizedBox(height: 12),
            TextField(
              controller: inputController,
              decoration: InputDecoration(
                hintText: isSecret ? l10n.inviteCodeHint : l10n.yourReason,
                border: const OutlineInputBorder(),
              ),
              maxLines: isSecret ? 1 : 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A3D28)),
            onPressed: () {
              final text = inputController.text.trim();
              Navigator.pop(dialogContext);
              context.read<CommunityListBloc>().add(
                JoinCommunityGroup(
                  communityId: community.id, 
                  reason: isSecret ? null : text,
                  inviteCode: isSecret ? text : null,
                ),
              );
              Navigator.pop(context); // close details screen
            },
            child: Text(isSecret ? l10n.joinGroup : l10n.sendRequest, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE7ECE9)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'About Community',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF111827)),
                ),
                const SizedBox(height: 12),
                Text(
                  (community.description?.isNotEmpty ?? false) ? community.description! : 'No description available.',
                  style: const TextStyle(fontSize: 14, color: Color(0xFF374151), height: 1.5),
                ),
                const SizedBox(height: 24),
                const Divider(color: Color(0xFFE7ECE9), height: 1),
                const SizedBox(height: 20),
                _buildInfoRow(Icons.location_on_rounded, 'Location', community.location?['name'] ?? 'Not specified', const Color(0xFF0F8A4B)),
                const SizedBox(height: 16),
                _buildInfoRow(Icons.calendar_today_rounded, 'Created On', DateHelper.formatDateTime(community.createdAt), const Color(0xFF3B82F6)),
                const SizedBox(height: 16),
                _buildInfoRow(Icons.groups_rounded, 'Members', '${community.memberCount} members', const Color(0xFF8B5CF6)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE7ECE9)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Group Rules',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF111827)),
                ),
                const SizedBox(height: 16),
                if (community.rules.isEmpty)
                  const Text('No rules defined for this community.', style: TextStyle(color: Color(0xFF667085)))
                else
                  ...community.rules.asMap().entries.map((entry) {
                    int idx = entry.key;
                    String rule = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF6F8F7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('${idx + 1}', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0A3D28), fontSize: 13)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(rule, style: const TextStyle(color: Color(0xFF374151), height: 1.4)),
                          )),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
          const SizedBox(height: 32),
          if (community.isJoined)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => _showLeaveConfirmation(context),
                icon: const Icon(Icons.exit_to_app_rounded, color: Color(0xFFEF4444)),
                label: const Text('Leave Group', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w800, fontSize: 15)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFEF4444)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (community.privacyType == 'PRIVATE' || community.privacyType == 'SECRET') {
                    _showJoinDialog(context);
                  } else {
                    context.read<CommunityListBloc>().add(JoinCommunityGroup(communityId: community.id));
                    Navigator.pop(context); // close details screen
                  }
                },
                icon: const Icon(Icons.group_add_rounded, color: Colors.white),
                label: const Text('Join Group', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A3D28),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CommunityLinksScreen(
                      communityId: community.id,
                      isAdmin: false, // TODO: Fetch role properly
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.link_rounded, color: Color(0xFF0F8A4B)),
              label: const Text('Links & Documents', style: TextStyle(color: Color(0xFF0F8A4B), fontWeight: FontWeight.w800, fontSize: 15)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF0F8A4B)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color iconColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF667085), fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
          ],
        ),
      ],
    );
  }
}
