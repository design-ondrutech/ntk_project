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
import 'package:ntk_project/src/core/utils/date_helper.dart';
enum EventExpiryStatus { active, upcoming, expired }

class EventsOverviewScreen extends StatefulWidget {
  static final GlobalKey<_EventsOverviewScreenState> eventsOverviewKey = GlobalKey<_EventsOverviewScreenState>();

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

class _EventsOverviewScreenState extends State<EventsOverviewScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isEmergency = false;
  int _selectedSubTabIndex = 0; // 0: Emergency Alerts, 1: Recent Broadcasts
  int _eventsFilterIndex = 0; // 0: Active & Upcoming, 1: Expired/Completed
  bool _hasInitialized = false;

  DateTime _parseEventDate(String dt) {
    return DateHelper.parseUtcToLocal(dt);
  }

  EventExpiryStatus _getEventStatus(String dateStr) {
    final eventTime = _parseEventDate(dateStr);
    final now = DateTime.now();
    if (now.isAfter(eventTime)) {
      return EventExpiryStatus.expired;
    }
    if (eventTime.year == now.year &&
        eventTime.month == now.month &&
        eventTime.day == now.day) {
      return EventExpiryStatus.active;
    }
    return EventExpiryStatus.upcoming;
  }

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
    _tabController = TabController(length: 2, vsync: this);
    final locationId = _effectiveLocationId;
    context.read<EventBloc>().add(FetchEvents(locationId: locationId));
    context.read<EventBloc>().add(FetchEmergencies(locationId: locationId));
    context.read<RequestBloc>().add(LoadRequests(locationId: locationId));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void selectTab(int index, {int? subTabIndex}) {
    if (_tabController.length > index) {
      _tabController.animateTo(index);
    }
    if (subTabIndex != null) {
      setState(() {
        _selectedSubTabIndex = subTabIndex;
      });
    }
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
    return DateHelper.formatDateTime(dt);
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
            context.read<RequestBloc>().add(LoadRequests(locationId: locId));
          },
        ),
        BlocListener<DashboardBloc, DashboardState>(
          listenWhen: (previous, current) =>
              previous.globalLocation?.id != current.globalLocation?.id,
          listener: (context, state) {
            final locId = widget.locationId ?? state.globalLocation?.id ?? context.read<AuthBloc>().state.loginData?.locationId;
            context.read<EventBloc>().add(FetchEvents(locationId: locId));
            context.read<EventBloc>().add(FetchEmergencies(locationId: locId));
            context.read<RequestBloc>().add(LoadRequests(locationId: locId));
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
              !_hasInitialized &&
              state.events.isEmpty &&
              state.emergencies.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!state.isLoading) {
            _hasInitialized = true;
          }

          return Column(
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
                controller: _tabController,
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
                controller: _tabController,
                children: [
                  _buildRequestsTab(state, theme),
                  _buildEventsTab(state, theme),
                ],
              ),
            ),
          ],
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
                onPressed: () async {
                  await Navigator.pushNamed(context, '/create_event');
                  if (mounted) {
                    context.read<EventBloc>().add(FetchEvents(locationId: _effectiveLocationId));
                  }
                },
                icon: const Icon(CupertinoIcons.plus),
                label: const Text('Create Event'),
              ),
            ],
          ],
        ),
      );
    }

    final nonExpiredEvents = state.events.where((e) {
      final status = _getEventStatus(e.date);
      return status != EventExpiryStatus.expired;
    }).toList();

    final expiredEvents = state.events.where((e) {
      final status = _getEventStatus(e.date);
      return status == EventExpiryStatus.expired;
    }).toList();

    final displayedEvents = _eventsFilterIndex == 0 ? nonExpiredEvents : expiredEvents;

    return RefreshIndicator(
      onRefresh: () async {
        context.read<EventBloc>().add(
          FetchEvents(
            locationId: _effectiveLocationId,
          ),
        );
      },
      child: Builder(
        builder: (context) {
          // Group events by their scheduled date (same pattern as broadcasts)
          final flattenedEvents = _groupAndFlatten(
            displayedEvents,
            (item) => (item as EventModel).date,
          );

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: flattenedEvents.length + 1, // +1 for the header
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Events List',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                        ),
                        if (canCreate)
                          OutlinedButton.icon(
                            onPressed: () async {
                              await Navigator.pushNamed(context, '/create_event');
                              if (mounted) {
                                context.read<EventBloc>().add(FetchEvents(locationId: _effectiveLocationId));
                              }
                            },
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
                    Row(
                      children: [
                        _buildFilterChip(
                          label: 'Active & Upcoming',
                          count: nonExpiredEvents.length,
                          isSelected: _eventsFilterIndex == 0,
                          activeColor: const Color(0xFF004D2A),
                          activeBgColor: const Color(0xFFE5F0EA),
                          onTap: () => setState(() => _eventsFilterIndex = 0),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: 'Expired/Completed',
                          count: expiredEvents.length,
                          isSelected: _eventsFilterIndex == 1,
                          activeColor: const Color(0xFFEF4444),
                          activeBgColor: const Color(0xFFFEE2E2),
                          onTap: () => setState(() => _eventsFilterIndex = 1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (displayedEvents.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Text(
                            _eventsFilterIndex == 0
                                ? 'No active or upcoming events.'
                                : 'No expired or completed events.',
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              }

              final item = flattenedEvents[index - 1];

              // Date header string
              if (item is String) {
                return _buildDateHeader(item);
              }

              // Event card
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: _buildEventCard(item as EventModel),
              );
            },
          );
        },
      ),
    );
  }
  Widget _buildRequestsTab(EventState state, ThemeData theme) {
    final userRole = context.read<AuthBloc>().state.loginData?.role ?? 'MEMBER';
    final canCreate = userRole != 'MEMBER';

    return BlocBuilder<RequestBloc, RequestState>(
      builder: (context, reqState) {
        if (reqState.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (reqState.error != null) {
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
                    reqState.error!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      final locId = _effectiveLocationId;
                      context.read<RequestBloc>().add(LoadRequests(locationId: locId));
                      context.read<EventBloc>().add(FetchEmergencies(locationId: locId));
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
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.pushNamed(context, '/create_announcement');
                      if (mounted) {
                        final locId = _effectiveLocationId;
                        context.read<RequestBloc>().add(LoadRequests(locationId: locId));
                        context.read<EventBloc>().add(FetchEmergencies(locationId: locId));
                      }
                    },
                    icon: Icon(
                      canCreate ? CupertinoIcons.plus : Icons.warning_amber_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    label: Text(
                      canCreate ? 'Create Broadcast' : 'Report Emergency',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canCreate ? const Color(0xFF004D2A) : const Color(0xFFEF4444),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setState(() => _selectedSubTabIndex = 0),
                        child: Column(
                          children: [
                            Text(
                              'Emergency Alerts',
                              style: TextStyle(
                                color: _selectedSubTabIndex == 0 ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: _selectedSubTabIndex == 0 ? const Color(0xFFEF4444) : Colors.transparent,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setState(() => _selectedSubTabIndex = 1),
                        child: Column(
                          children: [
                            Text(
                              'Recent Broadcasts',
                              style: TextStyle(
                                color: _selectedSubTabIndex == 1 ? const Color(0xFF004D2A) : const Color(0xFF64748B),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: _selectedSubTabIndex == 1 ? const Color(0xFF004D2A) : Colors.transparent,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _selectedSubTabIndex == 0
                    ? (emergencies.isEmpty
                        ? const Center(child: Text('No emergency alerts found'))
                        : Builder(
                            builder: (context) {
                              final flattenedEmergencies = _groupAndFlatten(
                                emergencies.take(5).toList(),
                                (item) => (item as EmergencyModel).createdAt,
                              );
                              return ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: flattenedEmergencies.length + 1,
                                itemBuilder: (context, index) {
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
                                            onPressed: () {
                                              Navigator.pushNamed(
                                                context,
                                                '/all_alerts',
                                                arguments: {'type': 'EMERGENCY'},
                                              );
                                            },
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
                                  }
                                  final item = flattenedEmergencies[index - 1];
                                  if (item is String) {
                                    return _buildDateHeader(item);
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12.0),
                                    child: _buildEmergencyCard(item as EmergencyModel),
                                  );
                                },
                              );
                            },
                          ))
                    : (broadcasts.isEmpty
                        ? const Center(child: Text('No recent broadcasts found'))
                        : Builder(
                            builder: (context) {
                              final flattenedBroadcasts = _groupAndFlatten(
                                broadcasts.take(5).toList(),
                                (item) => (item as BroadcastModel).createdAt,
                              );
                              return ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: flattenedBroadcasts.length + 1,
                                itemBuilder: (context, index) {
                                  if (index == 0) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Recent Broadcasts',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF004D2A),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pushNamed(
                                                context,
                                                '/all_alerts',
                                                arguments: {'type': 'BROADCAST'},
                                              );
                                            },
                                            style: TextButton.styleFrom(
                                              padding: EdgeInsets.zero,
                                              minimumSize: Size.zero,
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            ),
                                            child: const Text(
                                              'View All',
                                              style: TextStyle(
                                                color: Color(0xFF004D2A),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                  final item = flattenedBroadcasts[index - 1];
                                  if (item is String) {
                                    return _buildDateHeader(item);
                                  }
                                  final broadcast = item as BroadcastModel;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12.0),
                                    child: _buildBroadcastItem(
                                      context,
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
                              );
                            },
                          )),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBroadcastItem(
    BuildContext context,
    BroadcastModel broadcast, {
    VoidCallback? onDelete,
  }) {
    return InkWell(
      onTap: () async {
        await Navigator.pushNamed(context, '/broadcast_details', arguments: broadcast);
        if (mounted) {
          final locId = _effectiveLocationId;
          context.read<RequestBloc>().add(LoadRequests(locationId: locId));
          context.read<EventBloc>().add(FetchEmergencies(locationId: locId));
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
          context.read<EventBloc>().add(FetchEmergencies(locationId: _effectiveLocationId));
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
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.account_tree_outlined, size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
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

  Widget _buildFilterChip({
    required String label,
    required int count,
    required bool isSelected,
    required Color activeColor,
    required Color activeBgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeBgColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? activeColor : const Color(0xFF6B7280),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? activeColor : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF4B5563),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(EventExpiryStatus status) {
    switch (status) {
      case EventExpiryStatus.active:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFE6F4EA),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, size: 8, color: Color(0xFF0F5A29)),
              SizedBox(width: 4),
              Text(
                'Active Event',
                style: TextStyle(
                  color: Color(0xFF0F5A29),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      case EventExpiryStatus.upcoming:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, size: 8, color: Color(0xFFD97706)),
              SizedBox(width: 4),
              Text(
                'Upcoming Event',
                style: TextStyle(
                  color: Color(0xFFD97706),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      case EventExpiryStatus.expired:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, size: 8, color: Color(0xFFDC2626)),
              SizedBox(width: 4),
              Text(
                'Expired Event',
                style: TextStyle(
                  color: Color(0xFFDC2626),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildEventCard(EventModel event) {
    final theme = Theme.of(context);
    final status = _getEventStatus(event.date);
    final isExpired = status == EventExpiryStatus.expired;

    final cardBgColor = isExpired ? const Color(0xFFF3F4F6) : Colors.white;
    final cardBorderColor = isExpired ? const Color(0xFFD1D5DB) : const Color(0xFFE5E7EB);
    final iconBgColor = isExpired ? const Color(0xFFE5E7EB) : const Color(0xFFE5F0EA);
    final iconColor = isExpired ? Colors.grey[600] : const Color(0xFF004D2A);
    final titleColor = isExpired ? Colors.grey[600] : NTKColors.textPrimary;

    return InkWell(
      onTap: () async {
        await Navigator.pushNamed(context, '/event_details', arguments: event);
        if (mounted) {
          context.read<EventBloc>().add(FetchEvents(locationId: _effectiveLocationId));
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cardBorderColor),
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
                      color: iconBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      CupertinoIcons.calendar,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: titleColor,
                            decoration: isExpired ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildStatusBadge(status),
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
                      isExpired ? Colors.grey[500]! : const Color(0xFF004D2A),
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
                      isExpired ? Colors.grey[500]! : Colors.orange,
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
                      isExpired ? Colors.grey[500]! : NTKColors.error,
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
