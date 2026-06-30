import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:ntk_project/src/core/widgets/ntk_app_bar.dart';
import 'package:ntk_project/src/core/services/fcm_service.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ntk_project/src/features/requests_broadcasts/presentation/bloc/request_bloc.dart';
import 'package:ntk_project/src/features/requests_broadcasts/data/models/broadcast_model.dart';
import 'package:ntk_project/src/features/requests_broadcasts/data/models/emergency_request_model.dart';
import 'package:ntk_project/src/features/events/data/models/emergency_model.dart';
import 'package:ntk_project/src/injection_container.dart';
import 'package:ntk_project/src/core/utils/date_helper.dart';
import 'package:ntk_project/src/features/dashboard/presentation/bloc/dashboard_bloc.dart';

class RequestsBroadcastsScreen extends StatefulWidget {
  const RequestsBroadcastsScreen({super.key});

  @override
  State<RequestsBroadcastsScreen> createState() => _RequestsBroadcastsScreenState();
}

class _RequestsBroadcastsScreenState extends State<RequestsBroadcastsScreen> {
  String _selectedTab = 'All Messages';
  StreamSubscription<RemoteMessage>? _fcmSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<RequestBloc>().add(const LoadRequests());
      }
    });
    _fcmSubscription = sl<FCMService>().messageStream.listen((message) {
      debugPrint("FCM push received, refreshing Broadcast page...");
      if (mounted) {
        context.read<RequestBloc>().add(const LoadRequests());
      }
    });
  }

  @override
  void dispose() {
    _fcmSubscription?.cancel();
    super.dispose();
  }

  String _formatDateTime(String dt) {
    return DateHelper.formatDateTime(dt);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final globalLoc = context.watch<DashboardBloc>().state.globalLocation;

    return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: NTKAppBar(
          title: 'Broadcast Update',
          subtitle: globalLoc?.name ?? context.read<AuthBloc>().state.loginData?.locationName ?? 'Tamil Nadu',
        ),
        body: Column(
          children: [
            const SizedBox(height: 20),
            // ── Tabs Section ──────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFDBEAFE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildTab('All Messages', _selectedTab == 'All Messages'),
                  _buildTab('Emergency Alerts', _selectedTab == 'Emergency Alerts'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── History List ───────────────────────────────────
            Expanded(
              child: BlocBuilder<RequestBloc, RequestState>(
                builder: (context, state) {
                  if (state.isLoading && state.broadcasts.isEmpty && state.requests.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.error != null && state.broadcasts.isEmpty && state.requests.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.exclamationmark_triangle,
                              color: theme.colorScheme.error,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Failed to load broadcasts',
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              state.error!,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () {
                                context.read<RequestBloc>().add(const LoadRequests());
                              },
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(120, 45),
                                backgroundColor: const Color(0xFF004D2A),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  final isEmergencyTab = _selectedTab == 'Emergency Alerts';

                  final userRole = context.read<AuthBloc>().state.loginData?.role ?? 'MEMBER';
                  final canCreate = userRole != 'MEMBER';

                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<RequestBloc>().add(const LoadRequests());
                    },
                    child: Builder(
                      builder: (context) {
                        final flattened = isEmergencyTab
                            ? _groupAndFlatten(state.requests, (item) => (item as EmergencyRequestModel).createdAt)
                            : _groupAndFlatten(state.broadcasts, (item) => (item as BroadcastModel).createdAt);

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: flattened.length + 1, // +1 for header
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      isEmergencyTab ? 'Emergency Alerts' : 'Recent Broadcasts',
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    if (canCreate && !isEmergencyTab)
                                      OutlinedButton.icon(
                                        onPressed: () async {
                                          await Navigator.pushNamed(context, '/create_announcement');
                                          if (context.mounted) {
                                            context.read<RequestBloc>().add(const LoadRequests());
                                          }
                                        },
                                        icon: const Icon(
                                          CupertinoIcons.plus,
                                          size: 16,
                                          color: Color(0xFF1E293B),
                                        ),
                                        label: const Text(
                                          'Create Broadcast',
                                          style: TextStyle(
                                            color: Color(0xFF1E293B),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }
                            
                            final item = flattened[index - 1];
                            if (item is String) {
                              return _buildDateHeader(item);
                            }

                            if (isEmergencyTab) {
                              if (state.requests.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.all(20.0),
                                  child: Center(child: Text('No emergency alerts found')),
                                );
                              }
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: _buildEmergencyCard(item as EmergencyRequestModel),
                              );
                            } else {
                              if (state.broadcasts.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.all(20.0),
                                  child: Center(child: Text('No broadcasts found')),
                                );
                              }
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: _buildBroadcastCard(item as BroadcastModel, canDelete: canCreate),
                              );
                            }
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
  }

  Widget _buildTab(String label, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ] : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? const Color(0xFF1E293B) : const Color(0xFF64748B),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBroadcastCard(BroadcastModel broadcast, {required bool canDelete}) {
    return InkWell(
      onTap: () async {
        await Navigator.pushNamed(context, '/broadcast_details', arguments: broadcast);
        if (context.mounted) {
          context.read<RequestBloc>().add(const LoadRequests());
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
            if (canDelete)
              IconButton(
                icon: const Icon(CupertinoIcons.trash, color: Color(0xFFEF4444), size: 18),
                onPressed: () {
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
                            context.read<RequestBloc>().add(RecallBroadcast(id: broadcast.id));
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  );
                },
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

  Widget _buildEmergencyCard(EmergencyRequestModel request) {
    final alert = EmergencyModel(
      id: request.id.toString(),
      title: request.title,
      description: request.description ?? '',
      type: request.type,
      contactName: request.memberName ?? 'Unknown',
      contactPhone: '',
      expiryDate: '',
      collectResponse: true,
      locationName: request.locationName ?? 'Unknown Location',
      going: 0,
      maybe: 0,
      notGoing: 0,
      status: request.status,
      createdAt: request.createdAt,
      audience: request.audience,
    );

    final isForwarded = alert.status?.toUpperCase() == 'FORWARDED' || alert.status?.toUpperCase() == 'FORWARD';
    final aud = alert.audience?.toUpperCase() ?? '';
    final forwardBadgeText = (aud == 'STATE' || aud == 'SUPER_ADMIN')
        ? 'Forwarded to Super Admin'
        : 'Forwarded by Sub Admin';

    return InkWell(
      onTap: () async {
        await Navigator.pushNamed(context, '/emergency_details', arguments: alert);
        if (context.mounted) {
          context.read<RequestBloc>().add(const LoadRequests());
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isForwarded ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isForwarded 
                ? const Color(0xFF3B82F6) 
                : alert.typeColor.withOpacity(0.2),
            width: isForwarded ? 1.5 : 1.0,
          ),
          boxShadow: isForwarded
              ? [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: alert.typeBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(alert.typeIcon, color: alert.typeColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isForwarded) ...[
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
                          color: alert.typeBgColor,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: alert.typeColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          '${alert.typeEmoji} ${alert.typeLabel}',
                          style: TextStyle(
                            color: alert.typeColor,
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
                            color: alert.typeColor,
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
                        'By ${request.memberName ?? 'Unknown Member'}',
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
                        request.locationName ?? 'Unknown Location',
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
                        request.createdAt != null && request.createdAt!.isNotEmpty
                            ? _formatDateTime(request.createdAt!)
                            : 'Just now',
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}
