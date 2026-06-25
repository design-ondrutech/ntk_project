import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/core/widgets/ntk_app_bar.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/admin/community_admin_bloc.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/admin/community_admin_event.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/admin/community_admin_state.dart';
import 'package:ntk_project/src/core/utils/date_helper.dart';
import 'package:intl/intl.dart';

class CommunityJoinRequestsScreen extends StatefulWidget {
  final int communityId;

  const CommunityJoinRequestsScreen({Key? key, required this.communityId}) : super(key: key);

  @override
  State<CommunityJoinRequestsScreen> createState() => _CommunityJoinRequestsScreenState();
}

class _CommunityJoinRequestsScreenState extends State<CommunityJoinRequestsScreen> {
  final Set<int> _selectedRequests = {};

  @override
  void initState() {
    super.initState();
    context.read<CommunityAdminBloc>().add(FetchJoinRequestsEvent(widget.communityId));
  }

  void _toggleSelection(int requestId) {
    setState(() {
      if (_selectedRequests.contains(requestId)) {
        _selectedRequests.remove(requestId);
      } else {
        _selectedRequests.add(requestId);
      }
    });
  }

  void _selectAll(List<int> requestIds) {
    setState(() {
      if (_selectedRequests.length == requestIds.length) {
        _selectedRequests.clear();
      } else {
        _selectedRequests.addAll(requestIds);
      }
    });
  }

  void _bulkApprove() {
    if (_selectedRequests.isEmpty) return;
    context.read<CommunityAdminBloc>().add(BulkApproveJoinRequestsEvent(
      widget.communityId,
      _selectedRequests.toList(),
    ));
    setState(() {
      _selectedRequests.clear();
    });
  }

  void _reviewRequest(int requestId, String action) {
    context.read<CommunityAdminBloc>().add(ReviewJoinRequestEvent(
      communityId: widget.communityId,
      requestId: requestId,
      action: action,
    ));
  }

  String _formatTime(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final date = DateHelper.parseUtcToLocal(isoDate);
      return DateFormat('MMM d, yyyy').format(date);
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      appBar: const NTKAppBar(
        title: 'Join Requests',
        subtitle: 'Approve or reject members',
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
          if (state.isLoadingJoinRequests && state.joinRequests.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF0A3D28)));
          }

          if (state.joinRequests.isEmpty) {
            return const Center(child: Text('No pending join requests.', style: TextStyle(color: Colors.grey)));
          }

          final allIds = state.joinRequests.map((r) => r.id).toList();
          final allSelected = _selectedRequests.length == allIds.length && allIds.isNotEmpty;

          return Column(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Checkbox(
                      value: allSelected,
                      activeColor: const Color(0xFF0F8A4B),
                      onChanged: (_) => _selectAll(allIds),
                    ),
                    const Text('Select All', style: TextStyle(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    if (_selectedRequests.isNotEmpty)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F8A4B),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: state.isApproving ? null : _bulkApprove,
                        icon: state.isApproving 
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.check, size: 18),
                        label: Text('Approve (${_selectedRequests.length})'),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.joinRequests.length,
                  itemBuilder: (context, index) {
                    final req = state.joinRequests[index];
                    final isSelected = _selectedRequests.contains(req.id);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: isSelected ? const Color(0xFF0F8A4B) : Colors.transparent, width: 2),
                      ),
                      child: InkWell(
                        onTap: () => _toggleSelection(req.id),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: const Color(0xFFEAF6EF),
                                    child: const Icon(Icons.person, color: Color(0xFF0F8A4B)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          req.user?['name'] ?? 'User ${req.user?['id'] ?? 'Unknown'}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        Text(
                                          _formatTime(req.createdAt),
                                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Checkbox(
                                    value: isSelected,
                                    activeColor: const Color(0xFF0F8A4B),
                                    onChanged: (_) => _toggleSelection(req.id),
                                  ),
                                ],
                              ),
                              if (req.reason != null && req.reason!.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF6F8F7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Reason:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                                      const SizedBox(height: 4),
                                      Text(req.reason!, style: const TextStyle(fontSize: 14)),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                        side: const BorderSide(color: Colors.red),
                                      ),
                                      onPressed: () => _reviewRequest(req.id, 'REJECT'),
                                      child: const Text('Reject'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F8A4B)),
                                      onPressed: () => _reviewRequest(req.id, 'APPROVE'),
                                      child: const Text('Approve'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
