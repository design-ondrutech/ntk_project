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
import 'package:ntk_project/src/features/location/data/models/location_model.dart';
import 'package:ntk_project/src/features/location/presentation/bloc/location_bloc.dart';
import 'package:ntk_project/src/features/location/presentation/bloc/location_event.dart';
import 'package:ntk_project/src/features/location/presentation/bloc/location_state.dart';

class EventsOverviewScreen extends StatefulWidget {
  const EventsOverviewScreen({super.key});

  @override
  State<EventsOverviewScreen> createState() => _EventsOverviewScreenState();
}

class _EventsOverviewScreenState extends State<EventsOverviewScreen> {
  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    final locationId = authState.loginData?.locationId;
    context.read<EventBloc>().add(FetchEvents(locationId: locationId));
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

  void _showCreateEventDialog(BuildContext context) {
    final theme = Theme.of(context);
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final dateController = TextEditingController();

    // Load locations when dialog opens
    final authState = context.read<AuthBloc>().state;
    final userRole = authState.loginData?.role;
    final userLocationId = authState.loginData?.locationId;

    if (userRole == 'SUB_ADMIN') {
      context.read<LocationBloc>().add(
        LoadLocationList(type: 'STREET', parentId: userLocationId),
      );
    } else {
      context.read<LocationBloc>().add(const LoadLocationList(type: 'AREA'));
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        LocationModel? selectedLocation;

        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Create New Event',
                          style: theme.textTheme.titleLarge,
                        ),
                        IconButton(
                          icon: const Icon(
                            CupertinoIcons.xmark_circle_fill,
                            color: NTKColors.textTertiary,
                          ),
                          onPressed: () => Navigator.pop(bottomSheetContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Event Title ──────────────────────────
                    TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Event Title',
                        hintText: 'Enter event title',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Description ──────────────────────────
                    TextFormField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'What is this event about?',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Date & Time ──────────────────────────
                    TextFormField(
                      controller: dateController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Date & Time',
                        hintText: 'Select date and time',
                        prefixIcon: Icon(CupertinoIcons.calendar, size: 20),
                      ),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (date == null) return;

                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time == null) return;

                        final dt = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                        dateController.text = dt.toIso8601String();
                      },
                    ),
                    const SizedBox(height: 16),

                    // ── Location Dropdown ────────────────────
                    BlocBuilder<LocationBloc, LocationState>(
                      bloc: context.read<LocationBloc>(),
                      builder: (_, locState) {
                        if (locState.isLoadingLocations) {
                          return Container(
                            height: 56,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                SizedBox(width: 16),
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Loading locations...',
                                  style: TextStyle(color: Color(0xFF9CA3AF)),
                                ),
                              ],
                            ),
                          );
                        }

                        return DropdownButtonFormField<LocationModel>(
                          value: selectedLocation,
                          decoration: InputDecoration(
                            labelText: 'Location',
                            hintText: 'Select location',
                            prefixIcon: const Icon(
                              CupertinoIcons.location,
                              size: 20,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE5E7EB),
                              ),
                            ),
                          ),
                          items: locState.locations
                              .map(
                                (loc) => DropdownMenuItem<LocationModel>(
                                  value: loc,
                                  child: Text(loc.name),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            setSheetState(() => selectedLocation = val);
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 32),

                    // ── Submit Button ────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: NTKColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          if (titleController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter an event title'),
                              ),
                            );
                            return;
                          }

                          if (dateController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please select a date and time'),
                              ),
                            );
                            return;
                          }

                          if (selectedLocation == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please select a location'),
                              ),
                            );
                            return;
                          }

                          context.read<EventBloc>().add(
                            CreateEvent(
                              title: titleController.text.trim(),
                              description: descriptionController.text.trim(),
                              date: dateController.text.trim(),
                              locationId: selectedLocation!.id,
                            ),
                          );
                          Navigator.pop(bottomSheetContext);
                        },
                        child: const Text(
                          'CREATE EVENT',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: NTKColors.background,
      appBar: NTKAppBar(
        title: 'Events',
        subtitle: context.read<AuthBloc>().state.loginData?.locationName ?? 'Tamil Nadu',
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.calendar_badge_plus, color: Colors.white),
            onPressed: () => _showCreateEventDialog(context),
          ),
        ],
      ),
      body: BlocConsumer<EventBloc, EventState>(
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
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

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
                  Text(
                    'No events scheduled',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check back later for upcoming events.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              final authState = context.read<AuthBloc>().state;
              context.read<EventBloc>().add(
                FetchEvents(locationId: authState.loginData?.locationId),
              );
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: state.events.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final event = state.events[index];
                return _buildEventCard(event);
              },
            ),
          );
        },
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: NTKColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: NTKColors.slate900.withOpacity(0.04),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: NTKColors.emerald50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'UPCOMING',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: NTKColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  CupertinoIcons.time,
                  size: 14,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDateTime(event.date),
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(event.title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              event.description,
              style: theme.textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  CupertinoIcons.location_solid,
                  size: 14,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    event.locationName,
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _onRespond(event.id, 'NOT_GOING'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: NTKColors.error,
                      side: const BorderSide(
                        color: NTKColors.error,
                        width: 1.2,
                      ),
                      minimumSize: const Size(0, 48),
                    ),
                    child: const Text('NOT GOING'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _onRespond(event.id, 'GOING'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                    child: const Text('I\'M GOING'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
