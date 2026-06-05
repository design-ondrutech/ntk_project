import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/core/widgets/ntk_app_bar.dart';
import 'package:ntk_project/src/core/theme/app_theme.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ntk_project/src/features/events/presentation/bloc/event_bloc.dart';
import 'package:ntk_project/src/features/events/presentation/bloc/event_event.dart';
import 'package:ntk_project/src/features/events/presentation/bloc/event_state.dart';
import 'package:ntk_project/src/features/events/data/models/event_model.dart';
import 'package:ntk_project/src/features/events/data/models/emergency_model.dart';
import 'package:ntk_project/src/features/location/data/models/location_model.dart';
import 'package:ntk_project/src/features/location/presentation/bloc/location_bloc.dart';
import 'package:ntk_project/src/features/location/presentation/bloc/location_event.dart';
import 'package:ntk_project/src/features/location/presentation/bloc/location_state.dart';
import 'package:ntk_project/src/features/requests_broadcasts/data/models/broadcast_model.dart';
import 'package:ntk_project/src/features/requests_broadcasts/presentation/bloc/request_bloc.dart';
import 'package:ntk_project/src/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:ntk_project/src/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:ntk_project/src/injection_container.dart';
class EventsOverviewScreen extends StatefulWidget {
  final bool embedded;
  final int? locationId;

  const EventsOverviewScreen({
    super.key,
    this.embedded = false,
    this.locationId,
  });

  @override
  State<EventsOverviewScreen> createState() => _EventsOverviewScreenState();
}

class _EventsOverviewScreenState extends State<EventsOverviewScreen> {
  bool _isEmergency = false;

  int? get _effectiveLocationId {
    if (widget.locationId != null) return widget.locationId;
    final dashboardBloc = context.read<DashboardBloc>();
    final globalLocId = dashboardBloc.state.globalLocation?.id;
    final authLocId = context.read<AuthBloc>().state.loginData?.locationId;
    return globalLocId ?? authLocId;
  }

  @override
  void initState() {
    super.initState();
    final locationId = _effectiveLocationId;
    context.read<EventBloc>().add(FetchEvents(locationId: locationId));
    context.read<EventBloc>().add(FetchEmergencies(locationId: locationId));
  }

  void _onRespond(String eventId, String status) {
    final authState = context.read<AuthBloc>().state;
    final memberId = authState.loginData?.id;
    if (memberId != null) {
      context.read<EventBloc>().add(
        RespondToEvent(eventId: eventId, memberId: memberId, status: status),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User not logged in')));
    }
  }

  String _formatDateTime(String dt) {
    try {
      DateTime date;
      final epoch = int.tryParse(dt);
      if (epoch != null) {
        // Backend may return epoch in seconds or milliseconds.
        date = epoch > 9999999999
            ? DateTime.fromMillisecondsSinceEpoch(epoch)
            : DateTime.fromMillisecondsSinceEpoch(epoch * 1000);
      } else {
        date = DateTime.parse(dt);
      }
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
      final ampm = date.hour < 12 ? 'AM' : 'PM';
      final minute = date.minute.toString().padLeft(2, '0');
      return '${months[date.month - 1]} ${date.day}, ${date.year} • $hour:$minute $ampm';
    } catch (_) {
      return dt;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = context.watch<AuthBloc>().state;
    // Watch globalLocation from DashboardBloc to trigger rebuild on location updates
    context.select((DashboardBloc bloc) => bloc.state.globalLocation);

    final body = MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (previous, current) =>
              previous.loginData?.locationId != current.loginData?.locationId,
          listener: (context, state) {
            final locId = widget.locationId ?? state.loginData?.locationId;
            context.read<EventBloc>().add(FetchEvents(locationId: locId));
            context.read<EventBloc>().add(FetchEmergencies(locationId: locId));
          },
        ),
        BlocListener<DashboardBloc, DashboardState>(
          listenWhen: (previous, current) =>
              previous.globalLocation?.id != current.globalLocation?.id,
          listener: (context, state) {
            final locId = widget.locationId ?? state.globalLocation?.id ?? context.read<AuthBloc>().state.loginData?.locationId;
            context.read<EventBloc>().add(FetchEvents(locationId: locId));
            context.read<EventBloc>().add(FetchEmergencies(locationId: locId));
          },
        ),
        BlocListener<EventBloc, EventState>(
          listener: (context, state) {
            if (state.message != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message!),
                  backgroundColor: theme.colorScheme.primary,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              context.read<EventBloc>().add(const ClearEventMessage());
            }
            if (state.error != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error!),
                  backgroundColor: theme.colorScheme.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              context.read<EventBloc>().add(const ClearEventError());
            }
          },
        ),
      ],
      child: BlocBuilder<EventBloc, EventState>(
        builder: (context, state) {
          if (state.isLoading &&
              state.events.isEmpty &&
              state.emergencies.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return BlocProvider(
          key: ValueKey(_effectiveLocationId),
          create: (context) => sl<RequestBloc>()..add(LoadRequests(locationId: _effectiveLocationId)),
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: TabBar(
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    color: const Color(0xFF004D2A),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: NTKColors.textSecondary,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Broadcast'),
                    Tab(text: 'Events'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildRequestsTab(state, theme),
                    _buildEventsTab(state, theme),
                  ],
                ),
              ),
            ],
          ),
        ),
        );
      },
    ));

    if (widget.embedded) {
      return Container(
        color: const Color(0xFFF5F5F5),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Broadcast',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
            ),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF004D2A), // Dark Green
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Broadcast', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            Text(authState.loginData?.locationName ?? 'Tamil Nadu', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500, fontSize: 11, letterSpacing: 1.2)),
          ],
        ),
      ),
      body: body,
    );
  }

  Widget _buildEventsTab(EventState state, ThemeData theme) {
    final userRole = context.read<AuthBloc>().state.loginData?.role ?? 'MEMBER';
    final canCreate = userRole != 'MEMBER';

    if (state.events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.calendar_today,
              size: 64,
              color: theme.dividerColor.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text('No events scheduled', style: theme.textTheme.titleLarge),
            if (canCreate) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/create_event'),
                icon: const Icon(CupertinoIcons.plus),
                label: const Text('Create Event'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<EventBloc>().add(
          FetchEvents(
            locationId: _effectiveLocationId,
          ),
        );
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: state.events.length + 1, // +1 for the header
        separatorBuilder: (context, index) =>
            index == 0 ? const SizedBox() : const SizedBox(height: 16),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Location Filter & Upcoming Text
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                  const Text(
                    'Upcoming Events',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                  ),
                  if (canCreate)
                    OutlinedButton.icon(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/create_event'),
                      icon: const Icon(
                        CupertinoIcons.plus,
                        size: 16,
                        color: NTKColors.textPrimary,
                      ),
                      label: const Text(
                        'Create Event',
                        style: TextStyle(
                          color: NTKColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size.zero,
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
              const SizedBox(height: 16),
            ],
            );
          }
          final event = state.events[index - 1];
          return _buildEventCard(event);
        },
      ),
    );
  }  Widget _buildRequestsTab(EventState state, ThemeData theme) {
    final userRole = context.read<AuthBloc>().state.loginData?.role ?? 'MEMBER';
    final canCreate = userRole != 'MEMBER';

    return BlocBuilder<RequestBloc, RequestState>(
      builder: (context, reqState) {
        if (reqState.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (reqState.error != null) {
          return Center(child: Text('Error: ${reqState.error}'));
        }

        final broadcasts = reqState.broadcasts;
        final emergencies = state.emergencies;

        return RefreshIndicator(
          onRefresh: () async {
            final locId = _effectiveLocationId;
            context.read<RequestBloc>().add(LoadRequests(locationId: locId));
            context.read<EventBloc>().add(FetchEmergencies(locationId: locId));
          },
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      canCreate ? 'Recent Broadcasts' : 'Emergency & Updates',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    if (canCreate)
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/create_announcement');
                        },
                        icon: const Icon(CupertinoIcons.plus, size: 16, color: Colors.white),
                        label: const Text('Create Broadcast', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF004D2A),
                          minimumSize: const Size(0, 36),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/create_announcement');
                        },
                        icon: const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.white),
                        label: const Text(
                          'Report Emergency',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          minimumSize: const Size(0, 32),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          elevation: 0,
                        ),
                      ),
                  ],
                ),
              ),
              if (broadcasts.isEmpty && emergencies.isEmpty)
                const Expanded(
                  child: Center(child: Text('No broadcasts or emergencies found')),
                )
              else
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: (emergencies.isNotEmpty ? emergencies.length + 1 : 0) +
                        (broadcasts.isNotEmpty ? broadcasts.length + 1 : 0),
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final hasEmergencies = emergencies.isNotEmpty;
                      final hasBroadcasts = broadcasts.isNotEmpty;

                      // Helper function to map flat index to sections
                      if (hasEmergencies) {
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Emergency Alerts',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFEF4444),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {},
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    'View All',
                                    style: TextStyle(
                                      color: Color(0xFFEF4444),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else if (index <= emergencies.length) {
                          return _buildEmergencyCard(emergencies[index - 1]);
                        }
                      }

                      // Adjust index for broadcasts
                      final broadcastStartIndex = hasEmergencies ? emergencies.length + 1 : 0;
                      final broadcastRelativeIndex = index - broadcastStartIndex;

                      if (hasBroadcasts) {
                        if (broadcastRelativeIndex == 0) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 8.0, bottom: 4.0),
                            child: Text(
                              'Recent Broadcasts',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B)),
                            ),
                          );
                        } else {
                          final broadcast = broadcasts[broadcastRelativeIndex - 1];
                          return _buildBroadcastItem(
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
                          );
                        }
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBroadcastItem(
    BroadcastModel broadcast, {
    VoidCallback? onDelete,
  }) {
    return InkWell(
      onTap: () => _showBroadcastDetailsDialog(context, broadcast),
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
            Column(
              children: [
                const Icon(CupertinoIcons.chevron_right, size: 16, color: Color(0xFF94A3B8)),
                if (onDelete != null) ...[
                  const SizedBox(height: 12),
                  IconButton(
                    icon: const Icon(CupertinoIcons.trash, color: Color(0xFFEF4444), size: 18),
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showBroadcastDetailsDialog(BuildContext context, BroadcastModel broadcast) {
    final requestBloc = context.read<RequestBloc>();
    requestBloc.add(LoadBroadcastDetails(broadcast.id));

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: BlocProvider.value(
            value: requestBloc,
            child: BlocBuilder<RequestBloc, RequestState>(
              builder: (context, state) {
                final isLoading = state.isLoading ||
                    state.currentBroadcast == null ||
                    state.currentBroadcast!.id != broadcast.id;

                if (isLoading) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (state.error != null) {
                  return Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 40),
                        const SizedBox(height: 12),
                        Text('Failed to load details: ${state.error}', textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                }

                final details = state.currentBroadcast ?? broadcast;

                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFFE6F4EA),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.campaign_rounded, color: Color(0xFF0F5A29), size: 24),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Broadcast Details',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                              onPressed: () => Navigator.pop(dialogContext),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        
                        Text(
                          details.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 8),

                        Row(
                          children: [
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
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0F2FE),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                details.type ?? 'AREA',
                                style: const TextStyle(
                                  color: Color(0xFF0369A1),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        const Text(
                          'Message',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            details.message,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF334155),
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        _buildBroadcastInfoRow(Icons.person_outline_rounded, 'Created By', 'By ${details.createdByName ?? 'Admin'} (${details.createdByRole ?? 'SUB_ADMIN'})'),
                        const SizedBox(height: 10),
                        _buildBroadcastInfoRow(Icons.location_on_outlined, 'Location', details.locationName ?? 'Tamil Nadu'),
                        const SizedBox(height: 10),
                        _buildBroadcastInfoRow(Icons.access_time_rounded, 'Date & Time', details.createdAt != null ? _formatDateTime(details.createdAt!) : 'Unknown'),
                        const SizedBox(height: 10),
                        _buildBroadcastInfoRow(Icons.people_outline, 'Recipients', 'Delivered to ${details.recipientCount} members'),
                        
                        const SizedBox(height: 24),
                        
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF004D2A),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              'Close',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildBroadcastInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              children: [
                TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: value, style: const TextStyle(color: Color(0xFF334155))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmergencyCard(EmergencyModel alert) {
    return InkWell(
      onTap: () =>
          Navigator.pushNamed(context, '/emergency_details', arguments: alert),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFEE2E2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFFFCE8E6), // light pink
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bloodtype_rounded, color: Color(0xFFC5221F), size: 24),
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
                          alert.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFC5221F), // dark red
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
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.account_tree_outlined, size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 8),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                          children: [
                            const TextSpan(text: 'Current Level: '),
                            TextSpan(
                              text: alert.currentLevelText,
                              style: const TextStyle(color: Color(0xFF1967D2), fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(CupertinoIcons.chevron_right, size: 16, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(EventModel event) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () =>
          Navigator.pushNamed(context, '/event_details', arguments: event),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5F0EA),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.calendar,
                      color: Color(0xFF004D2A),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: NTKColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              CupertinoIcons.time,
                              size: 14,
                              color: NTKColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDateTime(event.date),
                              style: const TextStyle(
                                fontSize: 12,
                                color: NTKColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              CupertinoIcons.location_solid,
                              size: 14,
                              color: NTKColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                event.locationName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: NTKColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    CupertinoIcons.chevron_right,
                    color: NTKColors.textTertiary,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatColumn(
                      event.going,
                      'Attend',
                      const Color(0xFF004D2A),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    color: const Color(0xFFE5E7EB),
                  ),
                  Expanded(
                    child: _buildStatColumn(
                      event.maybe,
                      'Maybe',
                      Colors.orange,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    color: const Color(0xFFE5E7EB),
                  ),
                  Expanded(
                    child: _buildStatColumn(
                      event.notGoing,
                      'Not Attend',
                      NTKColors.error,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(int count, String label, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
