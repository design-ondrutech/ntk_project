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
import 'package:ntk_project/src/features/requests_broadcasts/presentation/bloc/request_bloc.dart';
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

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    final locationId = widget.locationId ?? authState.loginData?.locationId;
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

    final body = MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (previous, current) =>
              previous.loginData?.locationId != current.loginData?.locationId,
          listener: (context, state) {
            final locId = widget.locationId ?? state.loginData?.locationId;
            context.read<EventBloc>().add(FetchEvents(locationId: locId));
            context.read<EventBloc>().add(FetchEmergencies(locationId: locId));
            // Note: RequestBloc is scoped lower down, so it will rebuild and re-fetch automatically 
            // when authState changes, since we watch AuthBloc at the top of build.
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
            }
            if (state.error != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error!),
                  backgroundColor: theme.colorScheme.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
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
          create: (context) => sl<RequestBloc>()..add(LoadRequests(locationId: widget.locationId ?? authState.loginData?.locationId)),
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
        final authState = context.read<AuthBloc>().state;
        context.read<EventBloc>().add(
          FetchEvents(
            locationId: widget.locationId ?? authState.loginData?.locationId,
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
        
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Broadcasts',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
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
                    ),
                ],
              ),
            ),
            if (broadcasts.isEmpty)
              const Expanded(
                child: Center(child: Text('No broadcasts found')),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: broadcasts.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final broadcast = broadcasts[index];
                    return _buildBroadcastItem(
                      broadcast.title,
                      broadcast.locationName ?? 'Unknown Location',
                      broadcast.createdAt ?? 'Unknown Time',
                      broadcast.createdByName,
                      broadcast.isActive ? 'Active' : 'Inactive',
                      broadcast.isActive ? const Color(0xFF22C55E) : const Color(0xFF94A3B8),
                      Icons.campaign_rounded,
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
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildBroadcastItem(
    String title,
    String location,
    String time,
    String? author,
    String status,
    Color statusColor,
    IconData icon, {
    VoidCallback? onDelete,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: statusColor, size: 24),
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
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 15),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(location, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(time, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                  ],
                ),
                if (author != null && author.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text('By $author', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (onDelete != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(CupertinoIcons.trash, color: Color(0xFFEF4444), size: 20),
              onPressed: onDelete,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmergencyCard(EmergencyModel alert) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () =>
          Navigator.pushNamed(context, '/emergency_details', arguments: alert),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: NTKColors.error.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: NTKColors.error.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: NTKColors.error.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_rounded,
                    color: NTKColors.error,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: NTKColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Just now', // Placeholder
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: NTKColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              alert.description,
              style: theme.textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  CupertinoIcons.location_solid,
                  size: 14,
                  color: NTKColors.error,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    alert.locationName,
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
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
