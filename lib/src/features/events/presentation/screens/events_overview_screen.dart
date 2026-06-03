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

    final body = BlocConsumer<EventBloc, EventState>(
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
      builder: (context, state) {
        if (state.isLoading &&
            state.events.isEmpty &&
            state.emergencies.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return DefaultTabController(
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
                ),
                child: TabBar(
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    color: NTKColors.primary,
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: NTKColors.textSecondary,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Requests'),
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
        );
      },
    );

    if (widget.embedded) {
      return Container(
        color: NTKColors.background,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Announcements',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: NTKColors.textPrimary,
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
      backgroundColor: NTKColors.background,
      appBar: NTKAppBar(
        title: 'Announcements',
        subtitle:
            context.read<AuthBloc>().state.loginData?.locationName ??
            'Tamil Nadu',
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
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Upcoming Events',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
          final event = state.events[index - 1];
          return _buildEventCard(event);
        },
      ),
    );
  }

  Widget _buildRequestsTab(EventState state, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDCFCE7)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: NTKColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.campaign,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Broadcast (No Response)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: NTKColors.primary,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Send announcements to your members.\nNo response will be collected.',
                        style: TextStyle(
                          fontSize: 12,
                          color: NTKColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildFormLabel('Broadcast Title *'),
          TextField(
            decoration: InputDecoration(
              hintText: 'Enter broadcast title',
              suffixText: '0/100',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
          const SizedBox(height: 20),

          _buildFormLabel('Message *'),
          TextField(
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Type your message here...',
              suffixText: '0/2000',
              suffixStyle: const TextStyle(fontSize: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
          const SizedBox(height: 20),

          _buildFormLabel('Send To *'),
          _buildDropdownTile(
            Icons.map,
            Colors.green,
            'Level 1 - State',
            'Tamil Nadu (Entire State)',
          ),
          const SizedBox(height: 8),
          _buildDropdownTile(
            Icons.location_city,
            Colors.blue,
            'Level 2 - District',
            'All Districts',
          ),
          const SizedBox(height: 8),
          _buildDropdownTile(
            Icons.people,
            Colors.purple,
            'Level 3 - Constituency',
            'All Constituencies',
          ),
          const SizedBox(height: 8),
          _buildDropdownTile(
            Icons.location_on,
            Colors.orange,
            'Level 4 - Area',
            'All Areas',
          ),
          const SizedBox(height: 8),
          _buildDropdownTile(
            Icons.edit_road,
            Colors.cyan,
            'Level 5 - Street',
            'All Streets',
          ),

          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info, color: Colors.blue, size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'This is a broadcast message.\nNo response will be collected.',
                    style: TextStyle(color: Colors.blue, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.send, color: Colors.white),
              label: const Text(
                'Send Broadcast',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: NTKColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFormLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }

  Widget _buildDropdownTile(
    IconData icon,
    Color color,
    String level,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(
            level,
            style: const TextStyle(
              color: NTKColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.keyboard_arrow_down,
            color: NTKColors.textSecondary,
            size: 20,
          ),
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
                      color: NTKColors.emerald50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.calendar,
                      color: NTKColors.primary,
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
                      NTKColors.primary,
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
