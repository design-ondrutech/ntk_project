import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/core/theme/app_theme.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ntk_project/src/features/requests_broadcasts/presentation/bloc/request_bloc.dart';
import 'package:ntk_project/src/features/requests_broadcasts/data/models/broadcast_model.dart';
import 'package:ntk_project/src/core/utils/date_helper.dart';

class BroadcastDetailsScreen extends StatefulWidget {
  const BroadcastDetailsScreen({super.key});

  @override
  State<BroadcastDetailsScreen> createState() => _BroadcastDetailsScreenState();
}

class _BroadcastDetailsScreenState extends State<BroadcastDetailsScreen> {
  BroadcastModel? _initialBroadcast;
  bool _detailsLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_detailsLoaded) {
      final broadcast = ModalRoute.of(context)?.settings.arguments as BroadcastModel?;
      if (broadcast != null) {
        _initialBroadcast = broadcast;
        context.read<RequestBloc>().add(LoadBroadcastDetails(broadcast.id));
        _detailsLoaded = true;
      }
    }
  }

  String _formatDateTime(String dt) {
    return DateHelper.formatDateTime(dt);
  }

  String _getTargetAudienceLabel(String? type) {
    if (type == null) return 'Area Level';
    switch (type.toUpperCase()) {
      case 'TALUK':
        return 'Taluk Level';
      case 'DISTRICT':
        return 'District Level';
      case 'STATE':
        return 'State Level';
      case 'ZONE':
        return 'Zone Level';
      default:
        return '${type[0].toUpperCase()}${type.substring(1).toLowerCase()} Level';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initialBroadcast == null) {
      return const Scaffold(
        body: Center(child: Text('No broadcast data found.')),
      );
    }

    final currentUserId = context.read<AuthBloc>().state.loginData?.id;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Broadcast Details'),
        backgroundColor: NTKColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocBuilder<RequestBloc, RequestState>(
        builder: (context, state) {
          final isLoading = state.isLoading && state.currentBroadcast == null;
          final details = state.currentBroadcast ?? _initialBroadcast!;
          final canDelete = details.createdById != null && details.createdById == currentUserId;

          return Column(
            children: [
              if (isLoading)
                const LinearProgressIndicator(
                  color: Color(0xFF0F5A29),
                  backgroundColor: Color(0xFFE6F4EA),
                ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header Section ─────────────────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE6F4EA),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.campaign_rounded,
                              color: Color(0xFF0F5A29),
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        details.title,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE6F4EA),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Active',
                                        style: TextStyle(
                                          color: Color(0xFF0F5A29),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE0F2FE),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    details.type ?? 'AREA',
                                    style: const TextStyle(
                                      color: Color(0xFF0369A1),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ── Message Box ────────────────────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  color: Color(0xFF0F5A29),
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Message',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F5A29),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              details.message,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF334155),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Detail Tiles ──────────────────────────────
                      _buildDetailTile(
                        Icons.person_outline_rounded,
                        'Created By',
                        '${details.createdByName ?? 'Admin'}${details.createdByRole != null ? ' (${details.createdByRole})' : ''}',
                      ),
                      _buildDetailTile(
                        Icons.location_on_outlined,
                        'Location',
                        details.locationName ?? 'N/A',
                        valueColor: const Color(0xFF0F5A29),
                      ),
                      _buildDetailTile(
                        Icons.people_outline_rounded,
                        'Target Audience',
                        _getTargetAudienceLabel(details.type),
                        valueColor: const Color(0xFF0369A1),
                      ),
                      _buildDetailTile(
                        Icons.calendar_today_outlined,
                        'Date & Time',
                        details.createdAt != null ? _formatDateTime(details.createdAt!) : 'N/A',
                      ),
                      _buildDetailTile(
                        Icons.group_outlined,
                        'Recipients',
                        'Delivered to ${details.recipientCount} members',
                      ),

                      // ── Delete Button ──────────────────────────────
                      if (canDelete) ...[
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _showRecallConfirmDialog(context, details.id),
                            icon: const Icon(
                              CupertinoIcons.trash,
                              color: Color(0xFFEF4444),
                              size: 18,
                            ),
                            label: const Text(
                              'Delete Broadcast',
                              style: TextStyle(
                                color: Color(0xFFEF4444),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: const Color(0xFFFEF2F2),
                              side: const BorderSide(color: Color(0xFFFEE2E2), width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDetailTile(IconData icon, String label, String value, {Color? valueColor}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: const Color(0xFF0F5A29),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRecallConfirmDialog(BuildContext context, int broadcastId) {
    showCupertinoDialog(
      context: context,
      builder: (dialogCtx) => CupertinoAlertDialog(
        title: const Text('Recall Broadcast'),
        content: const Text(
          'Are you sure you want to recall this broadcast message? This action cannot be undone.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(dialogCtx),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              context.read<RequestBloc>().add(RecallBroadcast(id: broadcastId));
              Navigator.pop(dialogCtx); // Close dialog
              Navigator.pop(context); // Close details page
            },
            child: const Text('Recall'),
          ),
        ],
      ),
    );
  }
}
