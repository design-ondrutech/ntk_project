import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/core/widgets/ntk_app_bar.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/admin/community_admin_bloc.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/admin/community_admin_event.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/admin/community_admin_state.dart';

class CommunityBanListScreen extends StatefulWidget {
  final int communityId;

  const CommunityBanListScreen({Key? key, required this.communityId}) : super(key: key);

  @override
  State<CommunityBanListScreen> createState() => _CommunityBanListScreenState();
}

class _CommunityBanListScreenState extends State<CommunityBanListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CommunityAdminBloc>().add(FetchCommunityBansEvent(widget.communityId));
  }

  void _showUnbanConfirmation(int userId, String userName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unban User', style: TextStyle(color: Color(0xFF0A3D28))),
        content: Text('Are you sure you want to unban $userName? They will be able to request to join again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F8A4B)),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<CommunityAdminBloc>().add(UnbanUserEvent(
                communityId: widget.communityId,
                userId: userId,
              ));
            },
            child: const Text('Unban'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      appBar: const NTKAppBar(
        title: 'Banned Users',
        subtitle: 'Manage community bans',
      ),
      body: BlocConsumer<CommunityAdminBloc, CommunityAdminState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!)));
          }
          if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.successMessage!)));
          }
        },
        builder: (context, state) {
          if (state.isLoadingBans && state.bans.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF0A3D28)));
          }
          
          if (state.bans.isEmpty) {
            return const Center(child: Text('No banned users.', style: TextStyle(color: Colors.grey)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.bans.length,
            itemBuilder: (context, index) {
              final ban = state.bans[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFEE2E2),
                    child: Icon(Icons.block, color: Colors.red),
                  ),
                  title: Text(ban.userName ?? 'User ${ban.userId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  subtitle: Text('Reason: ${ban.reason}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  trailing: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F8A4B),
                      side: const BorderSide(color: Color(0xFF0F8A4B)),
                    ),
                    onPressed: () => _showUnbanConfirmation(ban.userId, ban.userName ?? 'User ${ban.userId}'),
                    child: const Text('Unban'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
