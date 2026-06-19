import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/core/theme/app_theme.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ntk_project/src/features/events/presentation/bloc/event_bloc.dart';
import 'package:ntk_project/src/features/events/presentation/bloc/event_event.dart';
import 'package:ntk_project/src/features/events/presentation/bloc/event_state.dart';
import 'package:ntk_project/src/features/events/data/models/emergency_model.dart';
import 'package:ntk_project/src/features/requests_broadcasts/data/models/broadcast_model.dart';
import 'package:ntk_project/src/core/utils/date_helper.dart';
import 'package:ntk_project/src/features/requests_broadcasts/presentation/bloc/request_bloc.dart';
import 'package:ntk_project/src/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:ntk_project/src/features/dashboard/presentation/bloc/dashboard_state.dart';

class AllAlertsScreen extends StatefulWidget {
  final String type; // 'EMERGENCY' or 'BROADCAST'

  const AllAlertsScreen({super.key, required this.type});

  @override
  State<AllAlertsScreen> createState() => _AllAlertsScreenState();
}

class _AllAlertsScreenState extends State<AllAlertsScreen> {
  int? get _effectiveLocationId {
    final dashboardBloc = context.read<DashboardBloc>();
    final globalLocId = dashboardBloc.state.globalLocation?.id;
    final authLocId = context.read<AuthBloc>().state.loginData?.locationId;
    return globalLocId ?? authLocId;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final locId = _effectiveLocationId;
      if (widget.type == 'EMERGENCY') {
        context.read<EventBloc>().add(FetchEmergencies(locationId: locId));
      } else {
        context.read<RequestBloc>().add(LoadRequests(locationId: locId));
      }
    });
  }

  String _formatDateTime(String dt) {
    return DateHelper.formatDateTime(dt);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEmergency = widget.type == 'EMERGENCY';
    final userRole = context.read<AuthBloc>().state.loginData?.role ?? 'MEMBER';
    final canCreate = userRole != 'MEMBER';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF004D2A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEmergency ? 'Emergency Alerts' : 'Recent Broadcasts',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: isEmergency
          ? BlocBuilder<EventBloc, EventState>(
              builder: (context, state) {
                if (state.isLoading && state.emergencies.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                final emergencies = state.emergencies;
                if (emergencies.isEmpty) {
                  return const Center(child: Text('No emergency alerts found'));
                }
                final flattenedEmergencies = _groupAndFlatten(emergencies, (item) => (item as EmergencyModel).createdAt);
                return RefreshIndicator(
                  onRefresh: () async {
                    final locId = _effectiveLocationId;
                    context.read<EventBloc>().add(FetchEmergencies(locationId: locId));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: flattenedEmergencies.length,
                    itemBuilder: (context, index) {
                      final item = flattenedEmergencies[index];
                      if (item is String) {
                        return _buildDateHeader(item);
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _buildEmergencyCard(item as EmergencyModel),
                      );
                    },
                  ),
                );
              },
            )
          : BlocBuilder<RequestBloc, RequestState>(
              builder: (context, state) {
                if (state.isLoading && state.broadcasts.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                final broadcasts = state.broadcasts;
                if (broadcasts.isEmpty) {
                  return const Center(child: Text('No recent broadcasts found'));
                }
                final flattenedBroadcasts = _groupAndFlatten(broadcasts, (item) => (item as BroadcastModel).createdAt);
                return RefreshIndicator(
                  onRefresh: () async {
                    final locId = _effectiveLocationId;
                    context.read<RequestBloc>().add(LoadRequests(locationId: locId));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: flattenedBroadcasts.length,
                    itemBuilder: (context, index) {
                      final item = flattenedBroadcasts[index];
                      if (item is String) {
                        return _buildDateHeader(item);
                      }
                      final broadcast = item as BroadcastModel;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _buildBroadcastItem(
                          broadcast,
                          onDelete: canCreate
                              ? () {
                                  showCupertinoDialog(
                                    context: context,
                                    builder: (context) => CupertinoAlertDialog(
                                      title: const Text('Recall Broadcast'),
                                      content: const Text(
                                        'Are you sure you want to recall this broadcast message? This action cannot be undone.',
                                      ),
                                      actions: [
                                        CupertinoDialogAction(
                                          child: const Text('Cancel'),
                                          onPressed: () => Navigator.pop(context),
                                        ),
                                        CupertinoDialogAction(
                                          isDestructiveAction: true,
                                          child: const Text('Recall'),
                                          onPressed: () {
                                            context
                                                .read<RequestBloc>()
                                                .add(RecallBroadcast(id: broadcast.id));
                                            Navigator.pop(context);
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              : null,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmergencyCard(EmergencyModel alert) {
    final isForwarded = alert.status?.toUpperCase() == 'FORWARDED' || alert.status?.toUpperCase() == 'FORWARD';
    final isCompleted = alert.isCompleted;
    final isExpired = alert.isExpired && !isCompleted;
    final aud = alert.audience?.toUpperCase() ?? '';
    final forwardBadgeText = (aud == 'STATE' || aud == 'SUPER_ADMIN')
        ? 'Forwarded to Super Admin'
        : 'Forwarded by Sub Admin';

    Color cardBg = Colors.white;
    Color cardBorder = const Color(0xFFFEE2E2);
    double borderWidth = 1.0;

    if (isCompleted) {
      cardBg = const Color(0xFFF0F9FF);
      cardBorder = const Color(0xFF7DD3FC);
    } else if (isExpired) {
      cardBg = const Color(0xFFF8F9FA);
      cardBorder = const Color(0xFFD1D5DB);
    } else if (isForwarded) {
      cardBg = const Color(0xFFEFF6FF);
      cardBorder = const Color(0xFF3B82F6);
      borderWidth = 1.5;
    }

    return InkWell(
      onTap: () async {
        await Navigator.pushNamed(context, '/emergency_details', arguments: alert);
        if (mounted) {
          final locId = _effectiveLocationId;
          context.read<EventBloc>().add(FetchEmergencies(locationId: locId));
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder, width: borderWidth),
          boxShadow: isForwarded
              ? [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isCompleted || isExpired) ? const Color(0xFFF3F4F6) : alert.typeBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCompleted ? Icons.check_circle_rounded : (isExpired ? Icons.timer_off_rounded : alert.typeIcon),
                color: isCompleted ? const Color(0xFF0369A1) : (isExpired ? const Color(0xFF9CA3AF) : alert.typeColor),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isForwarded && !isCompleted && !isExpired) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF93C5FD)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.forward_to_inbox_rounded, size: 12, color: Color(0xFF1E40AF)),
                          const SizedBox(width: 4),
                          Text(
                            forwardBadgeText,
                            style: const TextStyle(
                              color: Color(0xFF1E40AF),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isCompleted || isExpired) ? const Color(0xFFF3F4F6) : alert.typeBgColor,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: (isCompleted || isExpired) ? const Color(0xFFD1D5DB) : alert.typeColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          '${alert.typeEmoji} ${alert.typeLabel}',
                          style: TextStyle(
                            color: (isCompleted || isExpired) ? const Color(0xFF9CA3AF) : alert.typeColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          alert.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: (isCompleted || isExpired) ? const Color(0xFF9CA3AF) : alert.typeColor,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: alert.statusBadgeBgColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          alert.statusBadgeText,
                          style: TextStyle(
                            color: alert.statusBadgeTextColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded, size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 8),
                      Text(
                        'By ${alert.createdBy ?? 'Unknown Member'}',
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 8),
                      Text(
                        alert.locationName,
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 8),
                      Text(
                        alert.createdAt != null && alert.createdAt!.isNotEmpty
                            ? _formatDateTime(alert.createdAt!)
                            : 'Just now',
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      ),
                    ],
                  ),
                  if (alert.expiryDate.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 16,
                          color: isExpired ? const Color(0xFF9CA3AF) : const Color(0xFFDC2626),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isExpired
                              ? 'Expired: ${_formatDateTime(alert.expiryDate)}'
                              : 'Expires: ${_formatDateTime(alert.expiryDate)}',
                          style: TextStyle(
                            color: isExpired ? const Color(0xFF9CA3AF) : const Color(0xFFDC2626),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildBroadcastItem(
    BroadcastModel broadcast, {
    VoidCallback? onDelete,
  }) {
    return InkWell(
      onTap: () async {
        await Navigator.pushNamed(context, '/broadcast_details', arguments: broadcast);
        if (mounted) {
          final locId = _effectiveLocationId;
          context.read<RequestBloc>().add(LoadRequests(locationId: locId));
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFFE6F4EA), // light green
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.campaign_rounded, color: Color(0xFF0F5A29), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          broadcast.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded, size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 8),
                      Text(
                        'By ${broadcast.createdByName ?? 'Admin'}',
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 8),
                      Text(
                        broadcast.locationName ?? 'Unknown Location',
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 8),
                      Text(
                        broadcast.createdAt != null && broadcast.createdAt!.isNotEmpty
                            ? _formatDateTime(broadcast.createdAt!)
                            : 'Unknown Time',
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.people_outline, size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 8),
                      Text(
                        'Delivered to ${broadcast.recipientCount} members',
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(CupertinoIcons.trash, color: Color(0xFFEF4444), size: 18),
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }



  List<dynamic> _groupAndFlatten(List<dynamic> items, String? Function(dynamic) getCreatedAt) {
    final Map<String, List<dynamic>> grouped = {};
    for (final item in items) {
      try {
        final createdAt = getCreatedAt(item);
        if (createdAt != null && createdAt.isNotEmpty) {
          final date = DateHelper.parseUtcToLocal(createdAt);
          final monthNames = [
            'January', 'February', 'March', 'April', 'May', 'June',
            'July', 'August', 'September', 'October', 'November', 'December'
          ];
          final dateStr = '${date.day} ${monthNames[date.month - 1]} ${date.year}';
          grouped.putIfAbsent(dateStr, () => []).add(item);
        } else {
          grouped.putIfAbsent('Unknown Date', () => []).add(item);
        }
      } catch (_) {
        grouped.putIfAbsent('Unknown Date', () => []).add(item);
      }
    }

    final List<dynamic> flattened = [];
    grouped.forEach((dateStr, groupItems) {
      flattened.add(dateStr); // Header
      flattened.addAll(groupItems); // Cards
    });
    return flattened;
  }

  Widget _buildDateHeader(String dateStr) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        dateStr,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: Color(0xFF1F2937),
        ),
      ),
    );
  }
}
